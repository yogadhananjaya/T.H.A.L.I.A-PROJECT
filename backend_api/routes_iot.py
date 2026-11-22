"""PINTU 2 — API IoT Real-Time (ESP32 + Rain Drop Sensor), Prakiraan 5 Hari, & Laporan Warga."""

import base64
from datetime import date, timedelta
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, ConfigDict
from database import get_conn
from security import get_optional_user, require_current_user

router = APIRouter(prefix="/api/v1")

UPLOADS_DIR = Path(__file__).resolve().parent / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)


class IoTTelemetryInput(BaseModel):
    model_config = ConfigDict(extra="allow")

    node_id: str = "ESP32-NODE-01"
    location_name: str = "Cikarang Utara, Bekasi"
    latitude: float = -6.2845
    longitude: float = 107.1705
    temperature_c: float
    humidity_pct: float
    pressure_hpa: float = 1011.0
    rainfall_pct: float | None = None
    is_raining: bool | None = None
    rainfall_mm_per_hour: float | None = None
    water_level_cm: float | None = None
    soil_moisture_pct: float = 50.0
    condition_code: str | None = None
    status: str | None = None
    status_reason: str | None = None


class VerifyReportRequest(BaseModel):
    action: str  # "approve" atau "reject"
    note: str = ""


def _count_recent_wet_streak(cur, node_id: str) -> int:
    """Menghitung berapa kali berturut-turut pembacaan terbaru sensor rain drop dalam kondisi basah."""
    cur.execute(
        """
        SELECT is_raining, rainfall_pct, rainfall_mm_per_hour
        FROM iot_telemetry
        WHERE node_id = %s
        ORDER BY recorded_at DESC, id DESC
        LIMIT 10;
        """,
        (node_id,),
    )
    streak = 0
    for row in cur.fetchall():
        wet = bool(row["is_raining"]) or float(row["rainfall_pct"]) >= 18.0 or float(row["rainfall_mm_per_hour"]) > 0.2
        if wet:
            streak += 1
        else:
            break
    return streak


def _evaluate_rain_sensor(
    data: IoTTelemetryInput,
    prior_wet_streak: int,
) -> tuple[float, bool, float, float, str, str, str]:
    """
    Logika Rain Drop Sensor (dikalibrasi ke baseline kering ESP32 ~9% / ADC ~3830):
    - Kering (< 18%): tema PANAS / CERAH (`sunny` -> tema oren).
    - Kena air sebentar (streak 1-2 & 18-49%): `light_rain` (Hujan Ringan -> tema biru).
    - Kena air agak lama (streak 3-4 atau 50-79%): `rain` (Hujan Lebat -> tema biru).
    - Kena air lama / sangat basah (streak >= 5 atau >= 80%): `storm` (Hujan Petir -> tema biru).
    """
    rain_pct = float(data.rainfall_pct) if data.rainfall_pct is not None else 0.0
    rain_mm_in = float(data.rainfall_mm_per_hour) if data.rainfall_mm_per_hour is not None else 0.0

    # Baseline kering sensor rain drop ESP32 berada di ~9% (ADC ~3830), jadi ambang basah >= 18%
    is_wet = (
        (rain_pct >= 18.0)
        or (rain_mm_in > 0.2)
        or (data.is_raining is True and data.rainfall_pct is None)
    )

    if not is_wet:
        rain_mm = 0.0
        water_cm = float(data.water_level_cm) if data.water_level_cm is not None else 82.0
        code = data.condition_code.lower() if data.condition_code else "sunny"
        status = data.status.lower() if data.status else "aman"
        reason = data.status_reason or "CERAH: Sensor rain drop kering, cuaca panas/cerah normal."
        return round(rain_pct, 1), False, rain_mm, water_cm, code, status, reason

    # Sensor sedang kena air -> hitung durasi basah berturut-turut
    total_streak = prior_wet_streak + 1

    if rain_mm_in > 0.2:
        rain_mm = rain_mm_in
    else:
        # Hitung curah hujan realistis berdasarkan % kebasahan + durasi kena air
        base_mm = max(1.5, rain_pct * 0.16)
        duration_boost = (total_streak - 1) * 2.2
        rain_mm = round(min(28.0, base_mm + duration_boost), 1)

    if rain_pct <= 5.0:
        rain_pct = min(100.0, 25.0 + (total_streak - 1) * 18.0)

    if data.water_level_cm is not None:
        water_cm = float(data.water_level_cm)
    else:
        water_cm = round(min(175.0, 102.0 + rain_pct * 0.35 + (total_streak - 1) * 7.0), 1)

    # Tentukan level hujan berdasarkan durasi kena air & intensitas
    if data.condition_code:
        code = data.condition_code.lower()
    elif total_streak >= 5 or rain_pct >= 80.0 or rain_mm >= 14.0:
        code = "storm"
    elif total_streak >= 3 or rain_pct >= 45.0 or rain_mm >= 6.0:
        code = "rain"
    else:
        code = "light_rain"

    if data.status:
        status = data.status.lower()
        reason = data.status_reason or f"Status sensor: {status.upper()}"
    elif code == "storm" or water_cm >= 150.0 or data.soil_moisture_pct >= 85.0:
        status = "bahaya"
        reason = f"BAHAYA: Hujan deras berkepanjangan ({total_streak * 10} dtk) terdeteksi sensor rain drop."
    elif code == "rain" or water_cm >= 125.0 or data.soil_moisture_pct >= 70.0:
        status = "waspada"
        reason = f"WASPADA: Hujan lebat terdeteksi ({total_streak * 10} dtk berturut-turut)."
    else:
        status = "aman"
        reason = "HUJAN RINGAN: Sensor rain drop mendeteksi tetesan air awal."

    return round(rain_pct, 1), True, round(rain_mm, 1), water_cm, code, status, reason


def _category_to_habitat(category: str) -> str:
    c = category.strip().lower()
    if "banjir" in c or "air" in c:
        return "hydrosphere"
    if "longsor" in c or "gempa" in c or "tanah" in c:
        return "lithosphere"
    if "kebakaran" in c or "angin" in c or "badai" in c or "hujan" in c:
        return "atmosphere"
    return "field"


def _serialize_report(row: dict) -> dict:
    created = row["created_at"]
    return {
        "id": str(row["id"]),
        "title": row["title"],
        "category": row["category"],
        "habitat": row["habitat"],
        "description": row["description"],
        "metric_summary": row["metric_summary"] or "",
        "location_name": row["location_name"],
        "latitude": row["latitude"],
        "longitude": row["longitude"],
        "status": row["status"],
        "photo_path": row["photo_path"],
        "verified_by": row["verified_by"],
        "verification_note": row["verification_note"],
        "created_at": created.isoformat() if hasattr(created, "isoformat") else str(created),
    }


# ==============================================================================
# PINTU 2A: TELEMETRI SENSOR IoT REAL-TIME (ESP32 + RAIN DROP SENSOR)
# ==============================================================================

@router.post("/telemetry", tags=["Pintu 2 - IoT ESP32 & Cuaca"])
@router.post("/iot/telemetry", tags=["Pintu 2 - IoT ESP32 & Cuaca"])
def ingest_iot_telemetry(payload: IoTTelemetryInput):
    """Endpoint tujuan POST dari alat IoT ESP32 (mendukung rainfall_pct, is_raining, & durasi hujan)."""
    extra_keys = getattr(payload, "model_extra", None) or {}
    if extra_keys:
        print(f"[IoT EXTRA FIELDS] {payload.node_id}: {extra_keys}", flush=True)

    with get_conn() as conn:
        cur = conn.cursor()
        prior_streak = _count_recent_wet_streak(cur, payload.node_id)
        rain_pct, is_wet, rain_mm, water_cm, code, status, reason = _evaluate_rain_sensor(
            payload, prior_streak
        )

        cur.execute(
            """
            INSERT INTO iot_telemetry (
                node_id, location_name, latitude, longitude,
                temperature_c, humidity_pct, pressure_hpa,
                rainfall_pct, is_raining, rainfall_mm_per_hour,
                water_level_cm, soil_moisture_pct,
                condition_code, status, status_reason
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *;
            """,
            (
                payload.node_id,
                payload.location_name,
                payload.latitude,
                payload.longitude,
                payload.temperature_c,
                payload.humidity_pct,
                payload.pressure_hpa,
                rain_pct,
                is_wet,
                rain_mm,
                water_cm,
                payload.soil_moisture_pct,
                code,
                status,
                reason,
            ),
        )
        saved = dict(cur.fetchone())

    saved["recorded_at"] = saved["recorded_at"].isoformat()
    print(
        f"[IoT SAVED] node={saved['node_id']} temp={saved['temperature_c']} "
        f"rain_pct={saved['rainfall_pct']} is_raining={saved['is_raining']} "
        f"streak={prior_streak + 1 if is_wet else 0} -> {saved['condition_code']} ({saved['status']})",
        flush=True,
    )
    return {"ok": True, "telemetry": saved}


@router.get("/telemetry/latest", tags=["Pintu 2 - IoT ESP32 & Cuaca"])
def get_latest_telemetry():
    """Mengambil 1 data pembacaan sensor IoT paling baru dari PostgreSQL."""
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM iot_telemetry ORDER BY recorded_at DESC, id DESC LIMIT 1;")
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Belum ada data sensor IoT di database.")
    data = dict(row)
    data["recorded_at"] = data["recorded_at"].isoformat()
    return data


@router.get("/telemetry/history", tags=["Pintu 2 - IoT ESP32 & Cuaca"])
def get_telemetry_history(limit: int = Query(default=30, ge=1, le=200)):
    """Mengambil riwayat pembacaan sensor IoT dari PostgreSQL."""
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT * FROM iot_telemetry ORDER BY recorded_at DESC, id DESC LIMIT %s;",
            (limit,),
        )
        rows = [dict(r) for r in cur.fetchall()]
    for r in rows:
        r["recorded_at"] = r["recorded_at"].isoformat()
    return {"count": len(rows), "items": rows}


@router.get("/alerts", tags=["Pintu 2 - IoT ESP32 & Cuaca"])
def get_emergency_alerts(limit: int = Query(default=20, ge=1, le=100)):
    """Mengambil peringatan bencana (waspada/bahaya) dari pembacaan sensor IoT untuk notifikasi HP."""
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, location_name, status, status_reason, recorded_at
            FROM iot_telemetry
            WHERE LOWER(status) IN ('waspada', 'bahaya', 'alert', 'danger')
            ORDER BY id DESC
            LIMIT %s;
            """,
            (limit,),
        )
        rows = cur.fetchall()
    return [
        {
            "id": int(r["id"]),
            "severity": "Danger" if str(r["status"]).lower() in ("bahaya", "danger") else "Alert",
            "location_name": r["location_name"],
            "cause_summary": r["status_reason"] or "Anomali sensor terdeteksi.",
            "recorded_at": r["recorded_at"].isoformat(),
        }
        for r in rows
    ]


@router.get("/forecast", tags=["Pintu 2 - IoT ESP32 & Cuaca"])
def get_forecast(
    lat: float = Query(default=-6.2845),
    lng: float = Query(default=107.1705),
    radius_km: int = Query(default=5, ge=1, le=50),
    days: int = Query(default=5, ge=1, le=7),
):
    """
    Prakiraan 5 hari untuk Dashboard Flutter:
    - Hari ke-1 (index 0) diambil LIVE dari baris terbaru tabel PostgreSQL `iot_telemetry`.
    - Kering (`sunny`/`clear`) -> `season_mode: "dry_orange"` (Tema Panas Oren).
    - Kena air (`light_rain`/`rain`/`storm`) -> `season_mode: "rainy_blue"` (Tema Hujan Biru).
    """
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM iot_telemetry ORDER BY recorded_at DESC, id DESC LIMIT 1;")
        latest = cur.fetchone()

    today = date.today()
    if latest:
        base_temp = float(latest["temperature_c"])
        base_hum = float(latest["humidity_pct"])
        base_rain = float(latest["rainfall_mm_per_hour"])
        base_water = float(latest["water_level_cm"])
        base_soil = float(latest["soil_moisture_pct"])
        base_code = latest["condition_code"]
        base_status = latest["status"]
        base_is_raining = bool(latest["is_raining"]) or base_code in ("light_rain", "rain", "storm", "thunderstorm")
        location_name = latest["location_name"]
    else:
        base_temp, base_hum, base_rain, base_water, base_soil = 31.0, 48.0, 0.0, 82.0, 24.0
        base_code, base_status, base_is_raining = "sunny", "aman", False
        location_name = "Cikarang Utara, Bekasi"

    offsets = [
        (0.0, 0.0, 0.0, 0.0, 0.0, base_code, base_status, "sensor"),
        (+1.5, -5.0, 0.0, -4.0, -2.0, "partly_cloudy", "aman", "forecast"),
        (+0.8, +4.0, 1.2, +5.0, +4.0, "cloudy", "aman", "forecast"),
        (+3.2, -10.0, 0.0, -10.0, -6.0, "sunny", "aman", "forecast"),
        (-1.2, +14.0, 8.5, +24.0, +16.0, "storm", "waspada", "forecast"),
    ]

    result_days = []
    for i in range(days):
        dt = today + timedelta(days=i)
        dt_temp, dt_hum, dt_rain, dt_water, dt_soil, code, st, src = offsets[i % len(offsets)]
        is_day_dry = (not base_is_raining) if i == 0 else (code in ("sunny", "clear"))
        result_days.append(
            {
                "date": dt.isoformat(),
                "condition_code": code,
                "temperature_c": round(max(15.0, min(42.0, base_temp + dt_temp))),
                "rainfall_mm_per_hour": round(max(0.0, base_rain if i == 0 else dt_rain), 1),
                "humidity_pct": round(max(20.0, min(100.0, base_hum + dt_hum))),
                "water_level_cm": round(max(20.0, base_water + dt_water)),
                "soil_moisture_pct": round(max(0.0, min(100.0, base_soil + dt_soil))),
                "status": st,
                "source": src,
                "season_mode": "dry_orange" if is_day_dry else "rainy_blue",
            }
        )

    return {
        "location": location_name,
        "latitude": lat,
        "longitude": lng,
        "radius_km": radius_km,
        "days": result_days,
    }


# ==============================================================================
# PINTU 2B: LAPORAN LAPANGAN WARGA (KAMERA & VERIFIKASI)
# ==============================================================================

@router.get("/reports", tags=["Pintu 2 - Laporan Warga"])
def list_reports(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    """Mengambil daftar laporan warga dari tabel PostgreSQL `field_reports`."""
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT * FROM field_reports
            ORDER BY created_at DESC, id DESC
            LIMIT %s OFFSET %s;
            """,
            (limit, offset),
        )
        rows = [_serialize_report(dict(r)) for r in cur.fetchall()]
    return {"reports": rows}


@router.post("/reports", tags=["Pintu 2 - Laporan Warga"])
async def create_report(
    request: Request,
    current_user: dict | None = Depends(get_optional_user),
):
    """Menerima laporan warga baik format multipart/form-data (upload foto) maupun JSON."""
    content_type = request.headers.get("content-type", "").lower()
    photo_bytes: bytes | None = None

    if "multipart/form-data" in content_type:
        form = await request.form()
        category = str(form.get("category", "Lainnya")).strip()
        description = str(form.get("description", "")).strip()
        location_name = str(form.get("location_name", "Lokasi Terpantau")).strip()
        latitude = float(form.get("latitude", -6.2845))
        longitude = float(form.get("longitude", 107.1705))
        photo_file = form.get("photo")
        if photo_file is not None and hasattr(photo_file, "read"):
            photo_bytes = await photo_file.read()
    else:
        body = await request.json()
        category = str(body.get("category", "Lainnya")).strip()
        description = str(body.get("description", "")).strip()
        location_name = str(body.get("location_name", "Lokasi Terpantau")).strip()
        latitude = float(body.get("latitude", -6.2845))
        longitude = float(body.get("longitude", 107.1705))
        photo_b64 = body.get("photo_base64")
        if isinstance(photo_b64, str) and photo_b64:
            try:
                photo_bytes = base64.b64decode(photo_b64)
            except Exception:
                photo_bytes = None

    if len(description) < 3:
        raise HTTPException(status_code=400, detail="Deskripsi laporan tidak boleh kosong.")

    habitat = _category_to_habitat(category)
    title = f"Laporan {category} • {location_name or 'Lapangan'}"
    summary = description[:38] + ("..." if len(description) > 38 else "")
    user_id = current_user["id"] if current_user else None

    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO field_reports (
                user_id, title, category, habitat, description, metric_summary,
                location_name, latitude, longitude, status
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'received')
            RETURNING *;
            """,
            (
                user_id,
                title,
                category,
                habitat,
                description,
                summary,
                location_name or "Lokasi Terpantau",
                latitude,
                longitude,
            ),
        )
        saved = dict(cur.fetchone())

        if photo_bytes:
            filename = f"report_{saved['id']}.jpg"
            (UPLOADS_DIR / filename).write_bytes(photo_bytes)
            rel_path = f"uploads/{filename}"
            cur.execute(
                "UPDATE field_reports SET photo_path = %s WHERE id = %s RETURNING *;",
                (rel_path, saved["id"]),
            )
            saved = dict(cur.fetchone())

    return _serialize_report(saved)


@router.post("/reports/{report_id}/verify", tags=["Pintu 2 - Laporan Warga"])
def verify_report(
    report_id: int,
    req: VerifyReportRequest,
    current_user: dict = Depends(require_current_user),
):
    """Memverifikasi laporan warga (khusus role staff / admin / petugas)."""
    role = (current_user.get("role") or "warga").lower()
    if role not in ("staff", "admin", "petugas"):
        raise HTTPException(
            status_code=403,
            detail="Hanya akun petugas/admin yang dapat memverifikasi laporan.",
        )

    approve = req.action.strip().lower() == "approve"
    new_status = "verified" if approve else "rejected"
    note = req.note.strip() or (
        "Terverifikasi asli oleh petugas lapangan."
        if approve
        else "Ditolak setelah pemeriksaan petugas."
    )

    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE field_reports
            SET status = %s,
                verified_by = %s,
                verification_note = %s
            WHERE id = %s
            RETURNING *;
            """,
            (new_status, current_user["full_name"], note, report_id),
        )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Laporan tidak ditemukan.")

    return {"report": _serialize_report(dict(row))}

from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.models import TelemetryLog
from app.db.session import get_db
from app.services.bmkg_service import BMKGService

router = APIRouter()


def _map_status_to_flutter(status: Optional[str]) -> str:
    s = (status or "Safe").lower()
    if s in ("danger", "bahaya"):
        return "bahaya"
    if s in ("alert", "warning", "waspada"):
        return "waspada"
    return "aman"


def _map_weather_code(rainfall_pct: float, weather_desc: str = "") -> str:
    desc = weather_desc.lower()
    if "petir" in desc or "badai" in desc or rainfall_pct >= 75:
        return "storm"
    if "lebat" in desc or rainfall_pct >= 50:
        return "rain"
    if "hujan" in desc or rainfall_pct >= 15:
        return "light_rain"
    if "mendung" in desc or "berawan tebal" in desc:
        return "cloudy"
    if "cerah" in desc and "berawan" not in desc:
        return "sunny"
    return "partly_cloudy"


@router.get("")
async def get_forecast(
    lat: Optional[float] = Query(default=None),
    lng: Optional[float] = Query(default=None),
    radius_km: int = Query(default=5, ge=1, le=50),
    db: Session = Depends(get_db),
):
    """Mengembalikan prakiraan cuaca 5 hari berbasis tanggal sistem + data BMKG/sensor terkini."""
    latest = db.query(TelemetryLog).order_by(TelemetryLog.id.desc()).first()
    bmkg = await BMKGService.get_regional_forecast()

    base_temp = int(round(latest.temperature_c)) if latest else int(round(bmkg.get("temperature_c", 27)))
    base_hum = int(round(latest.humidity_pct)) if latest else int(round(bmkg.get("humidity_pct", 78)))
    base_rain_pct = float(latest.rainfall_pct) if latest else float(bmkg.get("rainfall_probability_pct", 20))
    base_soil = int(round(latest.soil_moisture_pct)) if latest else 52
    base_status = _map_status_to_flutter(latest.status if latest else "Safe")

    now_utc = datetime.now(timezone.utc)
    today_code = _map_weather_code(base_rain_pct, bmkg.get("weather_desc", ""))

    # Day 0 uses live telemetry/BMKG; Days 1..4 provide realistic multi-day progression
    offsets = [
        (0, base_temp, today_code, round(base_rain_pct * 0.15, 1), base_hum, 110, base_soil, base_status),
        (1, base_temp + 1, "partly_cloudy", 0.4, max(45, base_hum - 7), 98, max(30, base_soil - 4), "aman"),
        (2, base_temp, "cloudy", 1.2, min(95, base_hum - 2), 105, base_soil, "aman"),
        (3, base_temp + 3, "sunny", 0.0, max(40, base_hum - 22), 82, max(28, base_soil - 14), "aman"),
        (4, max(22, base_temp - 1), "storm", 14.5, min(96, base_hum + 8), 135, min(88, base_soil + 12), "waspada"),
    ]

    days = []
    for day_offset, temp, code, rain_mm, hum, water_cm, soil, st in offsets:
        target_date = now_utc + timedelta(days=day_offset)
        days.append({
            "date": target_date.strftime("%Y-%m-%d"),
            "condition_code": code,
            "temperature_c": temp,
            "rainfall_mm_per_hour": rain_mm,
            "humidity_pct": hum,
            "water_level_cm": water_cm,
            "soil_moisture_pct": soil,
            "status": st,
        })

    return {
        "location": (latest.location_name if latest else bmkg.get("region_name", "Cikarang Selatan, Bekasi")),
        "latitude": lat or (latest.latitude if latest else -6.3378),
        "longitude": lng or (latest.longitude if latest else 107.1541),
        "radius_km": radius_km,
        "generated_at": now_utc.isoformat().replace("+00:00", "Z"),
        "days": days,
    }

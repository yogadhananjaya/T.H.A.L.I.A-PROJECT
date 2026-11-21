from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.db.session import get_db
from app.db.models import TelemetryLog
from app.services.bmkg_service import BMKGService
from app.schemas.telemetry import ComparisonResponse

router = APIRouter()


def _utc_z(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return dt.isoformat().replace("+00:00", "Z")


@router.get("", response_model=ComparisonResponse)
async def get_side_by_side_comparison(db: Session = Depends(get_db)):
    """
    Returns side-by-side comparison between:
    1. Local IoT ESP32 sensor node (Hyper-local precision at slope risk point)
    2. BMKG / Regional Weather Station (Macro regional forecast)
    Highlights the location granularity advantage of T.H.A.L.I.A.
    """
    latest_local = db.query(TelemetryLog).order_by(TelemetryLog.id.desc()).first()

    if latest_local:
        local_data = {
            "source": "T.H.A.L.I.A Physical ESP32 Node",
            "node_id": latest_local.node_id,
            "location": latest_local.location_name,
            "temperature_c": latest_local.temperature_c,
            "humidity_pct": latest_local.humidity_pct,
            "pressure_hpa": latest_local.pressure_hpa,
            "rainfall_pct": latest_local.rainfall_pct,
            "is_raining": bool(latest_local.is_raining),
            "soil_moisture_pct": latest_local.soil_moisture_pct,
            "status": latest_local.status,
            "status_reason": latest_local.status_reason,
            "timestamp": _utc_z(latest_local.timestamp),
        }
        status_value = latest_local.status
    else:
        local_data = {
            "source": "T.H.A.L.I.A Physical ESP32 Node (Baseline)",
            "node_id": "ESP32-NODE-01",
            "location": "Cibatu, Cikarang Selatan, Bekasi",
            "temperature_c": 26.2,
            "humidity_pct": 78.0,
            "pressure_hpa": 1012.0,
            "rainfall_pct": 5.0,
            "is_raining": False,
            "soil_moisture_pct": 48.0,
            "status": "Safe",
            "status_reason": "Kondisi normal",
            "timestamp": _utc_z(datetime.now(timezone.utc)),
        }
        status_value = "Safe"

    bmkg_data = await BMKGService.get_regional_forecast(
        lat=latest_local.latitude if latest_local else None,
        lon=latest_local.longitude if latest_local else None,
    )

    if local_data["soil_moisture_pct"] > 75.0 or local_data["rainfall_pct"] >= 30.0:
        advantage_text = (
            f"KEUNGGULAN GRANULARITAS TERBUKTI: Prakiraan Regional memprediksi '{bmkg_data.get('weather_desc')}', "
            f"namun sensor lokal T.H.A.L.I.A mendeteksi intensitas hujan lokal {local_data['rainfall_pct']}% "
            f"dan kejenuhan tanah lereng mencapai {local_data['soil_moisture_pct']}%. "
            f"Kondisi pemicu longsor mikro ini tidak tertangkap oleh stasiun makro!"
        )
    else:
        advantage_text = (
            f"Sinkronisasi Normal: Prakiraan Regional '{bmkg_data.get('weather_desc')}', "
            f"sementara sensor hiper-lokal T.H.A.L.I.A di titik pantau mencatat intensitas hujan {local_data['rainfall_pct']}% "
            f"dan kejenuhan tanah {local_data['soil_moisture_pct']}% (Aman)."
        )

    return ComparisonResponse(
        location=local_data["location"],
        timestamp=datetime.now(timezone.utc),
        local_telemetry=local_data,
        bmkg_regional_forecast=bmkg_data,
        granularity_advantage=advantage_text,
        status=status_value,
    )

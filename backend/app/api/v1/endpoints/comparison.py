from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.db.session import get_db
from app.db.models import TelemetryLog
from app.services.bmkg_service import BMKGService
from app.schemas.telemetry import ComparisonResponse

router = APIRouter()

@router.get("", response_model=ComparisonResponse)
async def get_side_by_side_comparison(db: Session = Depends(get_db)):
    """
    Returns side-by-side comparison between:
    1. Local IoT ESP32 sensor node (Hyper-local precision at slope risk point)
    2. BMKG Regional Weather Station (Macro regional forecast)
    Highlights the location granularity advantage of T.H.A.L.I.A.
    """
    latest_local = db.query(TelemetryLog).order_by(TelemetryLog.timestamp.desc()).first()

    # If no local data has been sent yet, provide baseline
    if latest_local:
        local_data = {
            "source": "T.H.A.L.I.A Physical ESP32 Node",
            "node_id": latest_local.node_id,
            "location": latest_local.location_name,
            "temperature_c": latest_local.temperature_c,
            "humidity_pct": latest_local.humidity_pct,
            "pressure_hpa": latest_local.pressure_hpa,
            "rainfall_mm_h": latest_local.rainfall_mm_h,
            "soil_moisture_pct": latest_local.soil_moisture_pct,
            "status": latest_local.status,
            "status_reason": latest_local.status_reason,
            "timestamp": latest_local.timestamp.isoformat()
        }
        status_value = latest_local.status
    else:
        local_data = {
            "source": "T.H.A.L.I.A Physical ESP32 Node (Baseline)",
            "node_id": "ESP32-NODE-01",
            "location": "Desa Sukamaju, Titik Rawan Lereng A",
            "temperature_c": 24.2,
            "humidity_pct": 82.0,
            "pressure_hpa": 1012.0,
            "rainfall_mm_h": 5.0,
            "soil_moisture_pct": 52.0,
            "status": "Safe",
            "status_reason": "Kondisi normal",
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        status_value = "Safe"

    # Fetch BMKG regional forecast
    bmkg_data = await BMKGService.get_regional_forecast(
        lat=latest_local.latitude if latest_local else None,
        lon=latest_local.longitude if latest_local else None,
    )

    # Formulate granularity advantage analysis
    if local_data["soil_moisture_pct"] > 75.0 or local_data["rainfall_mm_h"] > 30.0:
        advantage_text = (
            f"KEUNGGULAN GRANULARITAS TERBUKTI: BMKG Regional memprediksi '{bmkg_data.get('weather_desc')}', "
            f"namun sensor lokal T.H.A.L.I.A mendeteksi curah hujan lokal {local_data['rainfall_mm_h']} mm/jam "
            f"dan kejenuhan tanah lereng mencapai {local_data['soil_moisture_pct']}%. "
            f"Kondisi pemicu longsor mikro ini tidak tertangkap oleh stasiun makro BMKG!"
        )
    else:
        advantage_text = (
            f"Sinkronisasi Normal: BMKG memprediksi '{bmkg_data.get('weather_desc')}' (Makro), "
            f"sementara sensor hiper-lokal T.H.A.L.I.A di lereng mencatat kejenuhan tanah {local_data['soil_moisture_pct']}% (Aman)."
        )

    return ComparisonResponse(
        location=local_data["location"],
        timestamp=datetime.now(timezone.utc),
        local_telemetry=local_data,
        bmkg_regional_forecast=bmkg_data,
        granularity_advantage=advantage_text,
        status=status_value
    )

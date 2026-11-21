from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from enum import Enum
from pydantic import BaseModel

from app.db.session import get_db
from app.schemas.telemetry import TelemetryCreate, TelemetryResponse
from app.api.v1.endpoints.telemetry import ingest_telemetry

router = APIRouter()

class DemoScenario(str, Enum):
    SAFE_NORMAL = "safe_normal"
    ALERT_RAIN = "alert_rain"
    ALERT_MOISTURE = "alert_moisture"
    DANGER_LANDSLIDE = "danger_landslide"
    DANGER_FLASHFLOOD = "danger_flashflood"

class ScenarioTriggerRequest(BaseModel):
    scenario: DemoScenario
    location: str = "Desa Sukamaju, Titik Rawan Lereng A"

@router.post("/inject", response_model=TelemetryResponse)
def inject_demo_scenario(
    req: ScenarioTriggerRequest,
    db: Session = Depends(get_db)
):
    """
    Hackathon Demo Endpoint:
    Allows judges or presenter to immediately trigger specific disaster states
    to showcase instant classification, FCM alert dispatch, and Blockchain immutability.
    """
    if req.scenario == DemoScenario.SAFE_NORMAL:
        payload = TelemetryCreate(
            node_id="ESP32-NODE-01",
            location_name=req.location,
            temperature_c=25.4,
            humidity_pct=72.0,
            pressure_hpa=1013.2,
            rainfall_mm_h=2.5,
            soil_moisture_pct=45.0
        )
    elif req.scenario == DemoScenario.ALERT_RAIN:
        payload = TelemetryCreate(
            node_id="ESP32-NODE-01",
            location_name=req.location,
            temperature_c=22.8,
            humidity_pct=88.0,
            pressure_hpa=1006.0,
            rainfall_mm_h=28.0,
            soil_moisture_pct=58.0
        )
    elif req.scenario == DemoScenario.ALERT_MOISTURE:
        payload = TelemetryCreate(
            node_id="ESP32-NODE-01",
            location_name=req.location,
            temperature_c=23.0,
            humidity_pct=86.0,
            pressure_hpa=1008.0,
            rainfall_mm_h=12.0,
            soil_moisture_pct=68.5
        )
    elif req.scenario == DemoScenario.DANGER_LANDSLIDE:
        # High saturation (86%) + heavy rainfall (38mm/h) -> classic landslide trigger!
        payload = TelemetryCreate(
            node_id="ESP32-NODE-01",
            location_name=req.location,
            temperature_c=21.0,
            humidity_pct=95.0,
            pressure_hpa=1002.5,
            rainfall_mm_h=42.0,
            soil_moisture_pct=88.5
        )
    elif req.scenario == DemoScenario.DANGER_FLASHFLOOD:
        # Extreme rainfall > 70 mm/h
        payload = TelemetryCreate(
            node_id="ESP32-NODE-01",
            location_name=req.location,
            temperature_c=20.5,
            humidity_pct=98.0,
            pressure_hpa=998.0,
            rainfall_mm_h=85.0,
            soil_moisture_pct=78.0
        )
    else:
        raise HTTPException(status_code=400, detail="Unknown demo scenario")

    # Ingest through the standard pipeline
    return ingest_telemetry(payload=payload, db=db)

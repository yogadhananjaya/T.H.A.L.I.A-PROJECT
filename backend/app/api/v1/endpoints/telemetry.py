import logging
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone

from app.db.session import get_db
from app.db.models import TelemetryLog, DisasterIncident
from app.schemas.telemetry import TelemetryCreate, TelemetryResponse
from app.core.rules import DisasterRuleEngine, StatusLevel
from app.services.blockchain_service import BlockchainService
from app.services.fcm_service import FCMService

logger = logging.getLogger("thalia_backend")
router = APIRouter()

SEVERITY_RANK = {
    StatusLevel.SAFE.value: 0,
    StatusLevel.ALERT.value: 1,
    StatusLevel.DANGER.value: 2,
}


@router.post("", response_model=TelemetryResponse)
def ingest_telemetry(payload: TelemetryCreate, db: Session = Depends(get_db)):
    """
    Ingests raw IoT sensor data from ESP32 node (or simulator).
    Runs Rule-Based Tri-Habitat Analysis.
    Dispatches Blockchain & FCM ONLY when status escalates into Alert/Danger
    (prevents spamming tx/notifications every 10s while state stays unchanged).
    """
    # 0. Check previous status for this node before inserting new log
    prev_log = (
        db.query(TelemetryLog)
        .filter(TelemetryLog.node_id == payload.node_id)
        .order_by(TelemetryLog.id.desc())
        .first()
    )
    prev_rank = SEVERITY_RANK.get(prev_log.status, 0) if prev_log else 0

    # 1. Run Classification Engine
    status, reason, analysis = DisasterRuleEngine.evaluate(
        rainfall_pct=payload.rainfall_pct,
        soil_moisture_pct=payload.soil_moisture_pct,
        temperature_c=payload.temperature_c,
        humidity_pct=payload.humidity_pct,
        pressure_hpa=payload.pressure_hpa,
        is_raining=payload.is_raining,
    )

    now_utc = datetime.now(timezone.utc)

    # 2. Persist Telemetry Log
    telemetry = TelemetryLog(
        node_id=payload.node_id,
        location_name=payload.location_name,
        latitude=payload.latitude,
        longitude=payload.longitude,
        temperature_c=payload.temperature_c,
        humidity_pct=payload.humidity_pct,
        pressure_hpa=payload.pressure_hpa,
        rainfall_pct=payload.rainfall_pct,
        is_raining=bool(payload.is_raining),
        rainfall_raw=payload.rainfall_raw,
        soil_moisture_pct=payload.soil_moisture_pct,
        soil_raw=payload.soil_raw,
        status=status.value,
        status_reason=reason,
        habitat_analysis=analysis,
        timestamp=now_utc,
    )
    db.add(telemetry)
    db.commit()
    db.refresh(telemetry)

    new_rank = SEVERITY_RANK.get(status.value, 0)

    # 3. Trigger Blockchain & FCM ONLY on escalation (Safe->Alert, Safe->Danger, Alert->Danger)
    if status in [StatusLevel.ALERT, StatusLevel.DANGER] and new_rank > prev_rank:
        snapshot = {
            "telemetry_id": telemetry.id,
            "node_id": payload.node_id,
            "location": payload.location_name,
            "latitude": payload.latitude,
            "longitude": payload.longitude,
            "soil_moisture_pct": payload.soil_moisture_pct,
            "rainfall_pct": payload.rainfall_pct,
            "is_raining": bool(payload.is_raining),
            "pressure_hpa": payload.pressure_hpa,
            "status": status.value,
            "timestamp": now_utc.isoformat().replace("+00:00", "Z"),
        }

        data_hash = BlockchainService.compute_data_hash(snapshot)

        bc_result = BlockchainService.record_alert_on_chain(
            data_hash_hex=data_hash,
            location=payload.location_name,
            habitat_summary=reason,
            severity=status.value,
        )

        instructions = (
            "PERINGATAN TINGGI! Warga lereng curam harap segera evakuasi mandiri ke titik kumpul aman!"
            if status == StatusLevel.DANGER
            else "WASPADA! Pantau pergerakan tanah dan jauhi aliran sungai."
        )

        fcm_result = FCMService.send_emergency_alert(
            severity=status.value,
            location=payload.location_name,
            reason=reason,
            safety_instructions=instructions,
        )

        incident = DisasterIncident(
            node_id=payload.node_id,
            location_name=payload.location_name,
            severity=status.value,
            cause_summary=reason,
            data_hash=data_hash,
            blockchain_tx_hash=bc_result.get("tx_hash"),
            blockchain_event_id=bc_result.get("event_id"),
            blockchain_status=bc_result.get("status", "PENDING"),
            fcm_sent=fcm_result.get("status", "PENDING"),
            fcm_message=fcm_result.get("body"),
            raw_telemetry_snapshot=snapshot,
            timestamp=now_utc,
        )
        db.add(incident)
        db.commit()
    elif status in [StatusLevel.ALERT, StatusLevel.DANGER]:
        logger.info(
            f"Node {payload.node_id} remains in {status.value} state; skipping duplicate Blockchain tx & FCM."
        )

    return telemetry


@router.get("/latest", response_model=Optional[TelemetryResponse])
def get_latest_telemetry(db: Session = Depends(get_db)):
    """
    Returns the most recent sensor reading from the IoT node.
    """
    latest = db.query(TelemetryLog).order_by(TelemetryLog.id.desc()).first()
    if not latest:
        return None
    return latest


@router.get("/history", response_model=List[TelemetryResponse])
def get_telemetry_history(
    limit: int = Query(default=30, ge=1, le=200),
    db: Session = Depends(get_db),
):
    """
    Returns historical telemetry records for rendering charts on Flutter app.
    """
    records = db.query(TelemetryLog).order_by(TelemetryLog.id.desc()).limit(limit).all()
    return list(reversed(records))

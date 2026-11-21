from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone

from app.db.session import get_db
from app.db.models import TelemetryLog, DisasterIncident
from app.schemas.telemetry import TelemetryCreate, TelemetryResponse
from app.core.rules import DisasterRuleEngine, StatusLevel
from app.services.blockchain_service import BlockchainService
from app.services.fcm_service import FCMService

router = APIRouter()

@router.post("", response_model=TelemetryResponse)
def ingest_telemetry(payload: TelemetryCreate, db: Session = Depends(get_db)):
    """
    Ingests raw IoT sensor data from ESP32 node (or simulator).
    Runs Rule-Based Tri-Habitat Analysis.
    If status is Alert or Danger, dispatches to Blockchain & FCM.
    """
    # 1. Run Classification Engine
    status, reason, analysis = DisasterRuleEngine.evaluate(
        rainfall_mm_h=payload.rainfall_mm_h,
        soil_moisture_pct=payload.soil_moisture_pct,
        temperature_c=payload.temperature_c,
        humidity_pct=payload.humidity_pct,
        pressure_hpa=payload.pressure_hpa
    )

    # 2. Persist Telemetry Log
    telemetry = TelemetryLog(
        node_id=payload.node_id,
        location_name=payload.location_name,
        latitude=payload.latitude,
        longitude=payload.longitude,
        temperature_c=payload.temperature_c,
        humidity_pct=payload.humidity_pct,
        pressure_hpa=payload.pressure_hpa,
        rainfall_mm_h=payload.rainfall_mm_h,
        rainfall_raw=payload.rainfall_raw,
        soil_moisture_pct=payload.soil_moisture_pct,
        soil_raw=payload.soil_raw,
        status=status.value,
        status_reason=reason,
        habitat_analysis=analysis,
        timestamp=datetime.now(timezone.utc).replace(tzinfo=None)
    )
    db.add(telemetry)
    db.commit()
    db.refresh(telemetry)

    # 3. If Alert or Danger, trigger Blockchain Audit Trail & Push Notification
    if status in [StatusLevel.ALERT, StatusLevel.DANGER]:
        # Snapshot dictionary for tamper-proof hashing
        snapshot = {
            "telemetry_id": telemetry.id,
            "node_id": payload.node_id,
            "location": payload.location_name,
            "latitude": payload.latitude,
            "longitude": payload.longitude,
            "soil_moisture_pct": payload.soil_moisture_pct,
            "rainfall_mm_h": payload.rainfall_mm_h,
            "pressure_hpa": payload.pressure_hpa,
            "status": status.value,
            "timestamp": telemetry.timestamp.isoformat()
        }

        # Calculate cryptographic hash
        data_hash = BlockchainService.compute_data_hash(snapshot)

        # Record to Blockchain (Hardhat Smart Contract)
        bc_result = BlockchainService.record_alert_on_chain(
            data_hash_hex=data_hash,
            location=payload.location_name,
            habitat_summary=reason,
            severity=status.value
        )

        # Safety instructions based on severity
        instructions = (
            "PERINGATAN TINGGI! Warga lereng curam harap segera evakuasi mandiri ke titik kumpul aman!" 
            if status == StatusLevel.DANGER 
            else "WASPADA! Pantau pergerakan tanah dan jauhi aliran sungai."
        )

        # Dispatch FCM Push Notification
        fcm_result = FCMService.send_emergency_alert(
            severity=status.value,
            location=payload.location_name,
            reason=reason,
            safety_instructions=instructions
        )

        # Persist Incident Record
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
            timestamp=telemetry.timestamp
        )
        db.add(incident)
        db.commit()

    return telemetry


@router.get("/latest", response_model=Optional[TelemetryResponse])
def get_latest_telemetry(db: Session = Depends(get_db)):
    """
    Returns the most recent sensor reading from the IoT node.
    """
    latest = db.query(TelemetryLog).order_by(TelemetryLog.timestamp.desc()).first()
    if not latest:
        # Generate default baseline if no data yet
        return None
    return latest


@router.get("/history", response_model=List[TelemetryResponse])
def get_telemetry_history(
    limit: int = Query(default=30, ge=1, le=200),
    db: Session = Depends(get_db)
):
    """
    Returns historical telemetry records for rendering charts on Flutter app.
    """
    records = db.query(TelemetryLog).order_by(TelemetryLog.timestamp.desc()).limit(limit).all()
    return list(reversed(records))

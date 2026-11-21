from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Dict, Any

from app.db.session import get_db
from app.db.models import DisasterIncident
from app.schemas.telemetry import IncidentAlertResponse
from app.services.blockchain_service import BlockchainService

router = APIRouter()

@router.get("", response_model=List[IncidentAlertResponse])
def get_alerts(db: Session = Depends(get_db)):
    """
    Returns all logged disaster alert incidents with blockchain transaction records.
    """
    alerts = db.query(DisasterIncident).order_by(DisasterIncident.timestamp.desc()).all()
    # Map fcm_sent to fcm_status for schema
    result = []
    for a in alerts:
        res = IncidentAlertResponse(
            id=a.id,
            timestamp=a.timestamp,
            node_id=a.node_id,
            location_name=a.location_name or "Lokasi Sensor",
            severity=a.severity,
            cause_summary=a.cause_summary,
            data_hash=a.data_hash,
            blockchain_tx_hash=a.blockchain_tx_hash,
            blockchain_event_id=a.blockchain_event_id,
            blockchain_status=a.blockchain_status,
            fcm_status=a.fcm_sent
        )
        result.append(res)
    return result

@router.get("/{alert_id}/verify")
def verify_alert_on_blockchain(alert_id: int, db: Session = Depends(get_db)):
    """
    Verifies the integrity of an alert by comparing its database hash
    with the immutable record stored on the THALIARegistry smart contract.
    """
    incident = db.query(DisasterIncident).filter(DisasterIncident.id == alert_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident alert not found")

    if incident.blockchain_status != "CONFIRMED":
        return {
            "incident_id": incident.id,
            "location": incident.location_name,
            "severity": incident.severity,
            "timestamp": incident.timestamp.isoformat(),
            "database_hash": incident.data_hash,
            "blockchain_event_id": None,
            "blockchain_tx_hash": None,
            "is_tamper_proof_valid": False,
            "audit_verdict": f"NOT_ON_CHAIN ({incident.blockchain_status}): data ini tidak pernah tercatat di blockchain"
        }

    event_id = incident.blockchain_event_id
    is_valid = BlockchainService.verify_on_chain(event_id, incident.data_hash)

    return {
        "incident_id": incident.id,
        "location": incident.location_name,
        "severity": incident.severity,
        "timestamp": incident.timestamp.isoformat(),
        "database_hash": incident.data_hash,
        "blockchain_event_id": incident.blockchain_event_id,
        "blockchain_tx_hash": incident.blockchain_tx_hash,
        "is_tamper_proof_valid": is_valid,
        "audit_verdict": "VERIFIED & UNTAMPERED" if is_valid else "VERIFICATION_FAILED"
    }

@router.get("/summary/blockchain")
def get_blockchain_status():
    """Status node Hardhat & smart contract (untuk dashboard)."""
    return BlockchainService.get_status()

@router.get("/summary/stats")
def get_alert_summary(db: Session = Depends(get_db)):
    """
    Summary stats of disaster monitoring for high-level dashboard cards.
    """
    total_alerts = db.query(DisasterIncident).count()
    danger_count = db.query(DisasterIncident).filter(DisasterIncident.severity == "Danger").count()
    alert_count = db.query(DisasterIncident).filter(DisasterIncident.severity == "Alert").count()

    return {
        "total_incidents_logged": total_alerts,
        "danger_incidents": danger_count,
        "alert_incidents": alert_count,
        "blockchain_immutable_sync": True
    }

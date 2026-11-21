from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.db.models import DisasterIncident, TelemetryLog
from app.schemas.telemetry import IncidentAlertResponse
from app.services.blockchain_service import BlockchainService

router = APIRouter()


def _utc_z(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return dt.isoformat().replace("+00:00", "Z")


@router.get("", response_model=List[IncidentAlertResponse])
def get_alerts(db: Session = Depends(get_db)):
    """
    Returns all logged disaster alert incidents with blockchain transaction records.
    """
    alerts = db.query(DisasterIncident).order_by(DisasterIncident.id.desc()).all()
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
            fcm_status=a.fcm_sent,
        )
        result.append(res)
    return result


@router.get("/{alert_id}/verify")
def verify_alert_on_blockchain(alert_id: int, db: Session = Depends(get_db)):
    """
    Full tamper-proof audit check:
      1. Recomputes Keccak-256 hash from raw_telemetry_snapshot and compares with data_hash
      2. Cross-checks disaster_incidents columns (severity, location_name, node_id) against snapshot
      3. Cross-checks linked telemetry_logs row against snapshot
      4. Verifies recomputed hash directly against THALIARegistry smart contract on-chain
    """
    incident = db.query(DisasterIncident).filter(DisasterIncident.id == alert_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident alert not found")

    ts_str = _utc_z(incident.timestamp)

    if incident.blockchain_status != "CONFIRMED":
        return {
            "incident_id": incident.id,
            "location": incident.location_name,
            "severity": incident.severity,
            "timestamp": ts_str,
            "database_hash": incident.data_hash,
            "recomputed_hash": None,
            "blockchain_event_id": None,
            "blockchain_tx_hash": None,
            "is_tamper_proof_valid": False,
            "audit_verdict": f"NOT_ON_CHAIN ({incident.blockchain_status}): data ini tidak pernah tercatat di blockchain",
        }

    snapshot = incident.raw_telemetry_snapshot
    if not snapshot or not isinstance(snapshot, dict):
        return {
            "incident_id": incident.id,
            "location": incident.location_name,
            "severity": incident.severity,
            "timestamp": ts_str,
            "database_hash": incident.data_hash,
            "recomputed_hash": None,
            "blockchain_event_id": incident.blockchain_event_id,
            "blockchain_tx_hash": incident.blockchain_tx_hash,
            "is_tamper_proof_valid": False,
            "audit_verdict": "TAMPER_CHECK_FAILED: raw_telemetry_snapshot missing",
        }

    # 1. Recompute hash from snapshot
    recomputed_hash = BlockchainService.compute_data_hash(snapshot)
    hash_matches_db = recomputed_hash == incident.data_hash

    # 2. Cross-check disaster_incidents table columns against snapshot
    incident_fields_match = (
        incident.severity == snapshot.get("status")
        and incident.location_name == snapshot.get("location")
        and incident.node_id == snapshot.get("node_id")
    )

    # 3. Cross-check linked telemetry_logs row against snapshot
    telemetry_matches = True
    telemetry_id = snapshot.get("telemetry_id")
    if telemetry_id is not None:
        t_row = db.query(TelemetryLog).filter(TelemetryLog.id == telemetry_id).first()
        if t_row is None:
            telemetry_matches = False
        else:
            telemetry_matches = (
                t_row.soil_moisture_pct == snapshot.get("soil_moisture_pct")
                and t_row.rainfall_pct == snapshot.get("rainfall_pct")
                and t_row.pressure_hpa == snapshot.get("pressure_hpa")
                and t_row.status == snapshot.get("status")
                and t_row.location_name == snapshot.get("location")
                and t_row.node_id == snapshot.get("node_id")
            )

    # 4. On-chain verification against THALIARegistry
    event_id = incident.blockchain_event_id
    on_chain_valid = BlockchainService.verify_on_chain(event_id, recomputed_hash) if event_id else False

    is_valid = hash_matches_db and incident_fields_match and telemetry_matches and on_chain_valid

    if is_valid:
        verdict = "VERIFIED & UNTAMPERED"
    elif not hash_matches_db:
        verdict = "TAMPERED_DATA: snapshot database tidak cocok dengan data_hash"
    elif not incident_fields_match:
        verdict = "TAMPERED_DATA: kolom severity/location pada tabel disaster_incidents telah diubah"
    elif not telemetry_matches:
        verdict = "TAMPERED_DATA: nilai sensor pada tabel telemetry_logs telah diubah atau dihapus"
    else:
        verdict = "VERIFICATION_FAILED: hash tidak cocok di blockchain atau node Hardhat offline"

    return {
        "incident_id": incident.id,
        "location": incident.location_name,
        "severity": incident.severity,
        "timestamp": ts_str,
        "database_hash": incident.data_hash,
        "recomputed_hash": recomputed_hash,
        "blockchain_event_id": incident.blockchain_event_id,
        "blockchain_tx_hash": incident.blockchain_tx_hash,
        "checks": {
            "hash_matches_db": hash_matches_db,
            "incident_fields_match": incident_fields_match,
            "telemetry_row_matches": telemetry_matches,
            "on_chain_verified": on_chain_valid,
        },
        "is_tamper_proof_valid": is_valid,
        "audit_verdict": verdict,
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
        "blockchain_immutable_sync": True,
    }

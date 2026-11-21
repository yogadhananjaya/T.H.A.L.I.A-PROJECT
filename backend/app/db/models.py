from datetime import datetime, timezone
from sqlalchemy import Column, Integer, Float, String, DateTime, Text, JSON, Boolean
from app.db.session import Base

def utc_now():
    return datetime.now(timezone.utc)

class TelemetryLog(Base):
    __tablename__ = "telemetry_logs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    timestamp = Column(DateTime(timezone=True), default=utc_now, index=True)
    node_id = Column(String(50), default="ESP32-NODE-01", index=True)
    location_name = Column(String(100), default="Cibatu, Cikarang Selatan, Bekasi")
    latitude = Column(Float, default=-6.3378)
    longitude = Column(Float, default=107.1541)

    # 1. Atmosphere (BME280)
    temperature_c = Column(Float, nullable=False)
    humidity_pct = Column(Float, nullable=False)
    pressure_hpa = Column(Float, nullable=False)

    # 2. Hydrosphere (FC-37 Rain Sensor: 0-100% + boolean)
    rainfall_pct = Column(Float, nullable=False)
    is_raining = Column(Boolean, default=False)
    rainfall_raw = Column(Integer, nullable=True)

    # 3. Lithosphere (Soil moisture sensor)
    soil_moisture_pct = Column(Float, nullable=False)
    soil_raw = Column(Integer, nullable=True)

    # Classification
    status = Column(String(20), nullable=False, index=True) # Safe, Alert, Danger
    status_reason = Column(Text, nullable=True)
    habitat_analysis = Column(JSON, nullable=True)


class DisasterIncident(Base):
    __tablename__ = "disaster_incidents"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    timestamp = Column(DateTime(timezone=True), default=utc_now, index=True)
    node_id = Column(String(50), default="ESP32-NODE-01")
    location_name = Column(String(100))
    severity = Column(String(20), nullable=False) # Alert, Danger
    cause_summary = Column(Text, nullable=False)

    # Blockchain Audit Trail Details
    data_hash = Column(String(66), nullable=False, index=True) # Keccak256 hash 0x...
    blockchain_tx_hash = Column(String(66), nullable=True)
    blockchain_event_id = Column(Integer, nullable=True)
    blockchain_status = Column(String(20), default="PENDING") # PENDING, CONFIRMED, FAILED

    # Push Notification Status
    fcm_sent = Column(String(20), default="PENDING") # SENT, FAILED, MOCKED
    fcm_message = Column(Text, nullable=True)

    raw_telemetry_snapshot = Column(JSON, nullable=True)


class BMKGSnapshot(Base):
    __tablename__ = "bmkg_snapshots"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    updated_at = Column(DateTime(timezone=True), default=utc_now)
    region_code = Column(String(50), index=True)
    region_name = Column(String(100))
    weather_desc = Column(String(100))
    temperature_c = Column(Float)
    humidity_pct = Column(Float)
    rainfall_probability_pct = Column(Float, default=0.0)
    raw_payload = Column(JSON, nullable=True)

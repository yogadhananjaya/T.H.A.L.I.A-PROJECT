import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db.session import engine, Base

# Ensure test DB tables are created
Base.metadata.create_all(bind=engine)

client = TestClient(app)

def test_root_healthcheck():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["project"] == "T.H.A.L.I.A"
    assert data["status"] == "OPERATIONAL"

def test_ingest_telemetry_safe():
    payload = {
        "node_id": "ESP32-TEST-01",
        "location_name": "Lereng Uji A",
        "temperature_c": 25.0,
        "humidity_pct": 70.0,
        "pressure_hpa": 1012.0,
        "rainfall_mm_h": 2.0,
        "soil_moisture_pct": 40.0
    }
    response = client.post("/api/v1/telemetry", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Safe"
    assert data["node_id"] == "ESP32-TEST-01"

def test_ingest_telemetry_danger_and_incident_creation():
    payload = {
        "node_id": "ESP32-TEST-02",
        "location_name": "Lereng Rawan Longsor B",
        "temperature_c": 21.0,
        "humidity_pct": 95.0,
        "pressure_hpa": 1001.0,
        "rainfall_mm_h": 45.0,
        "soil_moisture_pct": 87.0 # Triggers Danger!
    }
    response = client.post("/api/v1/telemetry", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Danger"
    assert "BAHAYA" in data["status_reason"]

def test_get_latest_telemetry():
    response = client.get("/api/v1/telemetry/latest")
    assert response.status_code == 200
    data = response.json()
    assert data is not None
    assert "temperature_c" in data

def test_get_comparison():
    response = client.get("/api/v1/comparison")
    assert response.status_code == 200
    data = response.json()
    assert "local_telemetry" in data
    assert "bmkg_regional_forecast" in data
    assert "granularity_advantage" in data

def test_get_alerts_and_stats():
    # Alerts list
    response = client.get("/api/v1/alerts")
    assert response.status_code == 200
    alerts = response.json()
    assert len(alerts) >= 1
    
    # Stats
    stats_res = client.get("/api/v1/alerts/summary/stats")
    assert stats_res.status_code == 200
    stats = stats_res.json()
    assert stats["total_incidents_logged"] >= 1

def test_simulator_injection():
    response = client.post("/api/v1/simulator/inject", json={
        "scenario": "danger_landslide",
        "location": "Lereng Demonstrasi C"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Danger"

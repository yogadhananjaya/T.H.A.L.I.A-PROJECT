import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db.session import engine, Base

# Recreate tables cleanly if schema changed
Base.metadata.drop_all(bind=engine)
Base.metadata.create_all(bind=engine)

client = TestClient(app)


def test_root_healthcheck():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["project"] == "T.H.A.L.I.A"
    assert data["status"] == "OPERATIONAL"


def test_ingest_telemetry_safe_and_utc_z():
    payload = {
        "node_id": "ESP32-TEST-01",
        "location_name": "Cibatu, Cikarang Selatan, Bekasi",
        "temperature_c": 26.0,
        "humidity_pct": 70.0,
        "pressure_hpa": 1012.0,
        "rainfall_pct": 5.0,
        "is_raining": False,
        "soil_moisture_pct": 40.0
    }
    response = client.post("/api/v1/telemetry", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Safe"
    assert data["rainfall_pct"] == 5.0
    assert data["is_raining"] is False
    assert data["timestamp"].endswith("Z")


def test_ingest_telemetry_danger_and_antispam_deduplication():
    # First Danger for ESP32-TEST-02 -> creates 1 incident
    payload = {
        "node_id": "ESP32-TEST-02",
        "location_name": "Lereng Rawan Longsor B",
        "temperature_c": 21.0,
        "humidity_pct": 95.0,
        "pressure_hpa": 1001.0,
        "rainfall_pct": 55.0,
        "is_raining": True,
        "soil_moisture_pct": 87.0
    }
    r1 = client.post("/api/v1/telemetry", json=payload)
    assert r1.status_code == 200
    assert r1.json()["status"] == "Danger"
    assert "BAHAYA" in r1.json()["status_reason"]

    alerts_after_first = len(client.get("/api/v1/alerts").json())

    # Second consecutive Danger for the SAME node -> must NOT spam a new incident
    r2 = client.post("/api/v1/telemetry", json=payload)
    assert r2.status_code == 200
    assert r2.json()["status"] == "Danger"

    alerts_after_second = len(client.get("/api/v1/alerts").json())
    assert alerts_after_second == alerts_after_first


def test_get_latest_telemetry():
    response = client.get("/api/v1/telemetry/latest")
    assert response.status_code == 200
    data = response.json()
    assert data is not None
    assert "rainfall_pct" in data
    assert data["timestamp"].endswith("Z")


def test_get_comparison():
    response = client.get("/api/v1/comparison")
    assert response.status_code == 200
    data = response.json()
    assert "local_telemetry" in data
    assert "rainfall_pct" in data["local_telemetry"]
    assert "bmkg_regional_forecast" in data
    assert "granularity_advantage" in data
    assert data["timestamp"].endswith("Z")


def test_get_alerts_and_verify_offline_returns_false(monkeypatch):
    from app.services.blockchain_service import BlockchainService

    response = client.get("/api/v1/alerts")
    assert response.status_code == 200
    alerts = response.json()
    assert len(alerts) >= 1
    assert alerts[0]["timestamp"].endswith("Z")

    # Ensure verify_on_chain returns False when Hardhat is offline
    class OfflineW3:
        def is_connected(self): return False
    monkeypatch.setattr(BlockchainService, "get_w3", classmethod(lambda cls: OfflineW3()))
    assert BlockchainService.verify_on_chain(1, "0x" + "ab" * 32) is False

    stats_res = client.get("/api/v1/alerts/summary/stats")
    assert stats_res.status_code == 200
    assert stats_res.json()["total_incidents_logged"] >= 1


def test_simulator_injection():
    client.post("/api/v1/simulator/reset")
    response = client.post("/api/v1/simulator/inject", json={
        "scenario": "danger_landslide",
        "location": "Cibatu, Cikarang Selatan, Bekasi"
    })
    assert response.status_code == 200
    assert response.json()["status"] == "Danger"

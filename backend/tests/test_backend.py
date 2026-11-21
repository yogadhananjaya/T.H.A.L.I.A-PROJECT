import os

# Isolate pytest database so it NEVER drops or alters the demo thalia.db
os.environ["DATABASE_URL"] = "sqlite:///./test_thalia.db"

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db.session import engine, Base, SessionLocal
from app.db.models import TelemetryLog, DisasterIncident
from app.core.rules import DisasterRuleEngine, StatusLevel
from app.services.blockchain_service import BlockchainService


@pytest.fixture(scope="module", autouse=True)
def setup_and_teardown_test_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield
    engine.dispose()
    if os.path.exists("test_thalia.db"):
        try:
            os.remove("test_thalia.db")
        except OSError:
            pass


client = TestClient(app)


def test_root_healthcheck():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["project"] == "T.H.A.L.I.A"
    assert data["status"] == "OPERATIONAL"


def test_rain_threshold_alignment():
    # 72% must be Alert / Moderate Rain (below 75% Danger threshold)
    status, _, details = DisasterRuleEngine.evaluate(
        rainfall_pct=72.0, soil_moisture_pct=40.0,
        temperature_c=25.0, humidity_pct=75.0, pressure_hpa=1012.0,
    )
    assert status == StatusLevel.ALERT
    assert details["habitats"]["hydrosphere"] == "Moderate Rain"

    # 75% must be Danger / Heavy Rain
    status2, _, details2 = DisasterRuleEngine.evaluate(
        rainfall_pct=75.0, soil_moisture_pct=40.0,
        temperature_c=25.0, humidity_pct=75.0, pressure_hpa=1012.0,
    )
    assert status2 == StatusLevel.DANGER
    assert details2["habitats"]["hydrosphere"] == "Heavy Rain"


def test_ingest_telemetry_safe_and_utc_z():
    payload = {
        "node_id": "ESP32-TEST-01",
        "location_name": "Cibatu, Cikarang Selatan, Bekasi",
        "temperature_c": 26.0,
        "humidity_pct": 70.0,
        "pressure_hpa": 1012.0,
        "rainfall_pct": 5.0,
        "is_raining": False,
        "soil_moisture_pct": 40.0,
    }
    response = client.post("/api/v1/telemetry", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "Safe"
    assert data["rainfall_pct"] == 5.0
    assert data["is_raining"] is False
    assert data["timestamp"].endswith("Z")


def test_oscillating_sensor_cooldown_antispam():
    """Oscillating 64.9% <-> 65.1% must NOT spam Alert incidents within cooldown."""
    node = "ESP32-OSC-01"
    base = {
        "node_id": node,
        "location_name": "Cibatu, Cikarang Selatan, Bekasi",
        "temperature_c": 25.0,
        "humidity_pct": 75.0,
        "pressure_hpa": 1011.0,
        "rainfall_pct": 5.0,
        "is_raining": False,
    }
    before = len(client.get("/api/v1/alerts").json())

    # Safe -> Alert (65.1%) -> triggers 1 Alert incident
    client.post("/api/v1/telemetry", json={**base, "soil_moisture_pct": 64.9})
    r1 = client.post("/api/v1/telemetry", json={**base, "soil_moisture_pct": 65.1})
    assert r1.json()["status"] == "Alert"
    after_first = len(client.get("/api/v1/alerts").json())
    assert after_first == before + 1

    # Dip back to Safe (64.9%) then bounce back to Alert (65.1%) within 60s -> must NOT create a 2nd Alert
    client.post("/api/v1/telemetry", json={**base, "soil_moisture_pct": 64.9})
    r2 = client.post("/api/v1/telemetry", json={**base, "soil_moisture_pct": 65.1})
    assert r2.json()["status"] == "Alert"
    after_bounce = len(client.get("/api/v1/alerts").json())
    assert after_bounce == after_first

    # Escalating to Danger (88%) MUST still trigger immediately (different severity)
    r3 = client.post("/api/v1/telemetry", json={**base, "soil_moisture_pct": 88.0})
    assert r3.json()["status"] == "Danger"
    after_danger = len(client.get("/api/v1/alerts").json())
    assert after_danger == after_first + 1


def test_verify_not_on_chain_utc_z_and_cross_table_tamper_detection(monkeypatch):
    # Force an incident with CONFIRMED status and mock on-chain check = True
    alerts = client.get("/api/v1/alerts").json()
    assert len(alerts) >= 1
    alert_id = alerts[0]["id"]

    # First check NOT_ON_CHAIN branch if not confirmed
    db = SessionLocal()
    try:
        inc = db.query(DisasterIncident).filter(DisasterIncident.id == alert_id).first()
        orig_bc_status = inc.blockchain_status
        inc.blockchain_status = "SIMULATED"
        db.commit()

        v_sim = client.get(f"/api/v1/alerts/{alert_id}/verify").json()
        assert v_sim["is_tamper_proof_valid"] is False
        assert v_sim["timestamp"].endswith("Z")
        assert "NOT_ON_CHAIN" in v_sim["audit_verdict"]

        # Now mark as CONFIRMED and mock on-chain check = True
        inc.blockchain_status = "CONFIRMED"
        inc.blockchain_event_id = 1
        db.commit()
    finally:
        db.close()

    monkeypatch.setattr(BlockchainService, "verify_on_chain", classmethod(lambda cls, eid, h: True))

    # Clean record -> VERIFIED & UNTAMPERED
    v_ok = client.get(f"/api/v1/alerts/{alert_id}/verify").json()
    assert v_ok["is_tamper_proof_valid"] is True
    assert v_ok["audit_verdict"] == "VERIFIED & UNTAMPERED"
    assert v_ok["timestamp"].endswith("Z")

    # Tamper with linked telemetry_logs row -> MUST be detected!
    db = SessionLocal()
    try:
        inc = db.query(DisasterIncident).filter(DisasterIncident.id == alert_id).first()
        tid = inc.raw_telemetry_snapshot["telemetry_id"]
        t_row = db.query(TelemetryLog).filter(TelemetryLog.id == tid).first()
        orig_soil = t_row.soil_moisture_pct
        t_row.soil_moisture_pct = 12.3
        db.commit()

        v_tampered_tel = client.get(f"/api/v1/alerts/{alert_id}/verify").json()
        assert v_tampered_tel["is_tamper_proof_valid"] is False
        assert v_tampered_tel["checks"]["telemetry_row_matches"] is False
        assert "telemetry_logs" in v_tampered_tel["audit_verdict"]

        # Restore telemetry row, tamper with disaster_incidents.location_name -> MUST be detected!
        t_row.soil_moisture_pct = orig_soil
        orig_loc = inc.location_name
        inc.location_name = "Lokasi Palsu"
        db.commit()

        v_tampered_inc = client.get(f"/api/v1/alerts/{alert_id}/verify").json()
        assert v_tampered_inc["is_tamper_proof_valid"] is False
        assert v_tampered_inc["checks"]["incident_fields_match"] is False
        assert "disaster_incidents" in v_tampered_inc["audit_verdict"]

        # Restore
        inc.location_name = orig_loc
        inc.blockchain_status = orig_bc_status
        db.commit()
    finally:
        db.close()


def test_verify_offline_returns_false(monkeypatch):
    class OfflineW3:
        def is_connected(self): return False
    monkeypatch.setattr(BlockchainService, "get_w3", classmethod(lambda cls: OfflineW3()))
    assert BlockchainService.verify_on_chain(1, "0x" + "ab" * 32) is False


def test_get_latest_and_comparison():
    r_lat = client.get("/api/v1/telemetry/latest")
    assert r_lat.status_code == 200
    assert r_lat.json()["timestamp"].endswith("Z")

    r_cmp = client.get("/api/v1/comparison")
    assert r_cmp.status_code == 200
    data = r_cmp.json()
    assert "rainfall_pct" in data["local_telemetry"]
    assert data["timestamp"].endswith("Z")


def test_simulator_injection():
    client.post("/api/v1/simulator/reset")
    response = client.post("/api/v1/simulator/inject", json={
        "scenario": "danger_landslide",
        "location": "Cibatu, Cikarang Selatan, Bekasi",
    })
    assert response.status_code == 200
    assert response.json()["status"] == "Danger"


def test_auth_register_login_and_change_password():
    # Demo admin / 123 must work out of the box (B01 contract)
    demo_login = client.post("/api/v1/auth/login", json={"username": "admin", "password": "123"})
    assert demo_login.status_code == 200
    assert "access_token" in demo_login.json()
    assert demo_login.json()["user"]["name"]

    # Register new user
    reg = client.post("/api/v1/auth/register", json={
        "full_name": "Rafie Maulana",
        "email": "rafie.maulana@gmail.com",
        "password": "password123",
        "location_name": "Cikarang Utara",
    })
    assert reg.status_code == 201
    token = reg.json()["access_token"]
    assert reg.json()["user"]["email"] == "rafie.maulana@gmail.com"

    # Login with registered email
    login_res = client.post("/api/v1/auth/login", json={
        "username": "rafie.maulana@gmail.com",
        "password": "password123",
    })
    assert login_res.status_code == 200

    # Change password
    chg = client.post(
        "/api/v1/auth/change-password",
        json={"current_password": "password123", "new_password": "newpass456"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert chg.status_code == 200

    # Verify old password fails & new password succeeds
    old_try = client.post("/api/v1/auth/login", json={"username": "rafie.maulana@gmail.com", "password": "password123"})
    assert old_try.status_code == 401
    new_try = client.post("/api/v1/auth/login", json={"username": "rafie.maulana@gmail.com", "password": "newpass456"})
    assert new_try.status_code == 200

    # Forgot password endpoint
    fp = client.post("/api/v1/auth/forgot-password", json={"email": "rafie.maulana@gmail.com"})
    assert fp.status_code == 200


def test_forecast_and_field_reports_with_utc_z():
    fc = client.get("/api/v1/forecast?lat=-6.3378&lng=107.1541&radius_km=5")
    assert fc.status_code == 200
    data = fc.json()
    assert len(data["days"]) == 5
    assert data["generated_at"].endswith("Z")

    # Submit report via JSON
    rep = client.post("/api/v1/reports", json={
        "category": "Banjir",
        "description": "Genangan air setinggi 40 cm di jalan utama Cikarang Selatan.",
        "location_name": "Cibatu, Cikarang Selatan",
        "latitude": -6.3378,
        "longitude": 107.1541,
    })
    assert rep.status_code == 201
    created = rep.json()
    assert created["created_at"].endswith("Z")
    assert created["status"] == "received"

    # Submit report via multipart
    mp = client.post(
        "/api/v1/reports",
        data={
            "category": "Tanah Longsor",
            "description": "Retakan tanah selebar 15 cm terdeteksi di lereng selatan.",
            "location_name": "Bukit Selatan",
            "latitude": "-6.3400",
            "longitude": "107.1500",
        },
        files={"photo": ("test.jpg", b"\xff\xd8\xff\xe0testjpeg", "image/jpeg")},
    )
    assert mp.status_code == 201
    assert mp.json()["has_photo"] is True

    listing = client.get("/api/v1/reports")
    assert listing.status_code == 200
    assert len(listing.json()["reports"]) >= 2

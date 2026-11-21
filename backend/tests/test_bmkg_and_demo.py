import asyncio
from datetime import datetime, timezone, timedelta

from app.services.bmkg_service import BMKGService
from app.core.rules import DisasterRuleEngine
import importlib.util, pathlib


def _slot(delta_h, **kw):
    t = datetime.now(timezone.utc) + timedelta(hours=delta_h)
    base = {"utc_datetime": t.strftime("%Y-%m-%d %H:%M:%S"),
            "local_datetime": (t + timedelta(hours=7)).strftime("%Y-%m-%d %H:%M:%S"),
            "t": 25, "hu": 80, "tp": 0, "weather_desc": "Cerah", "ws": 5, "tcc": 30}
    base.update(kw)
    return base


def test_bmkg_parse_live_picks_nearest_slot():
    payload = {
        "lokasi": {"desa": "Maleber", "kecamatan": "Andir", "kotkab": "Kota Bandung"},
        "data": [{"cuaca": [[_slot(-20, weather_desc="Lama"),
                             _slot(0.5, weather_desc="Hujan Ringan", t=23, hu=90, tp=2.5)],
                            [_slot(30, weather_desc="Nanti")]]}],
    }
    r = BMKGService._parse_live(payload, payload["lokasi"])
    assert r["is_live"] is True
    assert r["weather_desc"] == "Hujan Ringan"
    assert r["temperature_c"] == 23.0 and r["rainfall_mm"] == 2.5
    assert "Maleber" in r["region_name"]


def test_bmkg_empty_returns_none_then_fallback_is_labeled():
    payload = {"lokasi": {"desa": "X", "kotkab": "Y"}, "data": [{"cuaca": []}]}
    assert BMKGService._parse_live(payload, payload["lokasi"]) is None
    fb = BMKGService._fallback(payload["lokasi"])
    assert fb["is_live"] is False and "FALLBACK" in fb["source"]


def test_demo_storyline_covers_all_levels():
    spec = importlib.util.spec_from_file_location(
        "sim", pathlib.Path(__file__).resolve().parents[2] / "scripts" / "esp32_simulator.py")
    sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)
    levels = set()
    for step in range(36):
        p = sim.generate_telemetry("demo", step)
        s, _, _ = DisasterRuleEngine.evaluate(p["rainfall_mm_h"], p["soil_moisture_pct"],
                                              p["temperature_c"], p["humidity_pct"], p["pressure_hpa"])
        levels.add(s.value)
    assert levels == {"Safe", "Alert", "Danger"}

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
    assert fb["is_live"] is False and fb["source_level"] == "static"


def test_demo_storyline_covers_all_levels():
    spec = importlib.util.spec_from_file_location(
        "sim", pathlib.Path(__file__).resolve().parents[2] / "scripts" / "esp32_simulator.py")
    sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)
    levels = set()
    for step in range(36):
        p = sim.generate_telemetry("demo", step)
        s, _, _ = DisasterRuleEngine.evaluate(p["rainfall_pct"], p["soil_moisture_pct"],
                                              p["temperature_c"], p["humidity_pct"], p["pressure_hpa"], p["is_raining"])
        levels.add(s.value)
    assert levels == {"Safe", "Alert", "Danger"}


def test_chain_bmkg_empty_uses_open_meteo(monkeypatch):
    import httpx

    class FakeResp:
        def __init__(self, payload): self.status_code, self._p = 200, payload
        def json(self): return self._p

    class FakeClient:
        def __init__(self, *a, **k): pass
        async def __aenter__(self): return self
        async def __aexit__(self, *a): return False
        async def get(self, url, params=None):
            if "bmkg" in url:
                return FakeResp({"lokasi": {"desa": "X", "lat": -6.9, "lon": 107.6}, "data": [{"cuaca": []}]})
            return FakeResp({"current": {"temperature_2m": 26.1, "relative_humidity_2m": 73, "precipitation": 0.5,
                                         "weather_code": 80, "cloud_cover": 90, "wind_speed_10m": 6.5, "time": "t"},
                             "hourly": {"precipitation_probability": [75]}})

    monkeypatch.setattr(httpx, "AsyncClient", FakeClient)
    BMKGService._cache.clear(); BMKGService._fetched_at.clear()
    r = asyncio.run(BMKGService.get_regional_forecast("test-code"))
    assert r["source_level"] == "open-meteo" and r["is_live"] is True
    assert r["temperature_c"] == 26.1 and r["rainfall_probability_pct"] == 75.0
    assert r["weather_desc"] == "Hujan Lokal Ringan"
    BMKGService._cache.clear(); BMKGService._fetched_at.clear()
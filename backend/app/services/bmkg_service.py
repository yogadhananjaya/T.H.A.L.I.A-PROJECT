import logging
import httpx
from datetime import datetime, timezone
from typing import Dict, Any, Optional
from app.core.config import settings

logger = logging.getLogger("thalia_backend")

CACHE_TTL_SECONDS = 600


class BMKGService:
    """
    Client BMKG Open Data (prakiraan cuaca per desa/kelurahan, parameter adm4).
    - LIVE     : prakiraan asli dari BMKG (slot waktu terdekat dari sekarang).
    - FALLBACK : BMKG tidak mengembalikan prakiraan / tidak terjangkau -> data cadangan,
                 diberi label jelas agar tidak disalahartikan sebagai data live.
    """
    _cache: Dict[str, Dict[str, Any]] = {}
    _fetched_at: Dict[str, datetime] = {}

    @classmethod
    async def get_regional_forecast(cls, region_code: Optional[str] = None) -> Dict[str, Any]:
        code = region_code or settings.DEFAULT_REGION_CODE
        now = datetime.now(timezone.utc)

        ts = cls._fetched_at.get(code)
        if ts and (now - ts).total_seconds() < CACHE_TTL_SECONDS and code in cls._cache:
            return cls._cache[code]

        location_info: Dict[str, Any] = {}
        data: Optional[Dict[str, Any]] = None
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(settings.BMKG_API_URL, params={"adm4": code})
            if resp.status_code == 200:
                payload = resp.json()
                location_info = payload.get("lokasi", {}) or {}
                data = cls._parse_live(payload, location_info)
            else:
                logger.warning(f"BMKG returned HTTP {resp.status_code} for adm4={code}")
        except Exception as ex:
            logger.warning(f"BMKG request failed: {ex}")

        if data is None:
            data = cls._fallback(location_info)

        cls._cache[code] = data
        cls._fetched_at[code] = now
        return data

    @staticmethod
    def _region_name(loc: Dict[str, Any]) -> str:
        if not loc:
            return "Jawa Barat (regional)"
        parts = [loc.get("desa"), loc.get("kecamatan"), loc.get("kotkab")]
        return ", ".join(p for p in parts if p)

    @classmethod
    def _parse_live(cls, payload: Dict[str, Any], loc: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Ambil slot prakiraan terdekat dengan waktu sekarang. None jika tidak ada data."""
        slots = []
        for entry in payload.get("data", []) or []:
            for group in entry.get("cuaca", []) or []:
                items = group if isinstance(group, list) else [group]
                slots.extend(i for i in items if isinstance(i, dict))
        if not slots:
            return None

        now = datetime.now(timezone.utc)

        def slot_time(s):
            raw = s.get("utc_datetime") or s.get("local_datetime")
            try:
                dt = datetime.fromisoformat(str(raw).replace("Z", "+00:00").replace(" ", "T"))
                return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
            except Exception:
                return None

        timed = [(s, slot_time(s)) for s in slots]
        timed = [(s, t) for s, t in timed if t is not None]
        best = min(timed, key=lambda x: abs((x[1] - now).total_seconds()))[0] if timed else slots[0]

        def f(key, default=0.0):
            try:
                return float(best.get(key, default))
            except (TypeError, ValueError):
                return default

        tp = f("tp")  # curah hujan (mm) pada slot
        return {
            "region_name": cls._region_name(loc),
            "weather_desc": best.get("weather_desc", "-"),
            "temperature_c": f("t"),
            "humidity_pct": f("hu"),
            "rainfall_mm": tp,
            "rainfall_probability_pct": min(100.0, round(tp * 20, 0)) if tp else 0.0,
            "wind_speed_kmh": f("ws"),
            "cloud_cover_pct": f("tcc"),
            "forecast_time": best.get("local_datetime"),
            "source": "BMKG Open Data API (LIVE)",
            "is_live": True,
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "station_type": "Regional Forecast (adm4)",
        }

    @classmethod
    def _fallback(cls, loc: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "region_name": cls._region_name(loc),
            "weather_desc": "Berawan Tebal / Potensi Hujan Ringan",
            "temperature_c": 28.5,
            "humidity_pct": 78.0,
            "rainfall_mm": 0.0,
            "rainfall_probability_pct": 45.0,
            "wind_speed_kmh": 0.0,
            "cloud_cover_pct": 0.0,
            "forecast_time": None,
            "source": "BMKG Open Data - FALLBACK (prakiraan live tidak tersedia)",
            "is_live": False,
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "station_type": "Regional Forecast (adm4)",
        }

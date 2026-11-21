import logging
import httpx
from datetime import datetime, timezone
from typing import Dict, Any, Optional
from app.core.config import settings

logger = logging.getLogger("thalia_backend")

CACHE_TTL_LIVE = 600     # detik, data BMKG live
CACHE_TTL_BACKUP = 120   # detik, saat memakai cadangan -> cek BMKG lebih sering agar cepat kembali LIVE

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

WMO = {
    0: "Cerah", 1: "Cerah Berawan", 2: "Berawan", 3: "Berawan Tebal", 45: "Berkabut", 48: "Berkabut",
    51: "Gerimis Ringan", 53: "Gerimis", 55: "Gerimis Lebat", 61: "Hujan Ringan", 63: "Hujan Sedang",
    65: "Hujan Lebat", 80: "Hujan Lokal Ringan", 81: "Hujan Lokal Sedang", 82: "Hujan Lokal Lebat",
    95: "Hujan Petir", 96: "Hujan Petir + Es", 99: "Hujan Petir Lebat",
}


class BMKGService:
    """
    Sumber pembanding cuaca regional dengan rantai cadangan:
      1) BMKG Open Data (LIVE)            -> source_level = "bmkg"
      2) Open-Meteo (data nyata, gratis)  -> source_level = "open-meteo"
      3) Data statis                      -> source_level = "static"
    Field `is_live` True untuk level 1 dan 2 (keduanya data nyata); `source` selalu menyebut sumber sebenarnya.
    """
    _cache: Dict[str, Dict[str, Any]] = {}
    _fetched_at: Dict[str, datetime] = {}

    @classmethod
    async def get_regional_forecast(cls, region_code: Optional[str] = None,
                                    lat: Optional[float] = None, lon: Optional[float] = None) -> Dict[str, Any]:
        code = region_code or settings.DEFAULT_REGION_CODE
        now = datetime.now(timezone.utc)

        cached = cls._cache.get(code)
        ts = cls._fetched_at.get(code)
        if cached and ts:
            ttl = CACHE_TTL_LIVE if cached.get("source_level") == "bmkg" else CACHE_TTL_BACKUP
            if (now - ts).total_seconds() < ttl:
                return cached

        location_info: Dict[str, Any] = {}
        data: Optional[Dict[str, Any]] = None

        # 1) BMKG
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

        # 2) Open-Meteo (butuh koordinat: dari BMKG lokasi, atau parameter, atau default setting)
        if data is None:
            la = lat if lat is not None else cls._f(location_info.get("lat"), settings.DEFAULT_LAT)
            lo = lon if lon is not None else cls._f(location_info.get("lon"), settings.DEFAULT_LON)
            data = await cls._open_meteo(la, lo, cls._region_name(location_info))

        # 3) Statis
        if data is None:
            data = cls._fallback(location_info)

        cls._cache[code] = data
        cls._fetched_at[code] = now
        return data

    @staticmethod
    def _f(v, default):
        try:
            return float(v)
        except (TypeError, ValueError):
            return default

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
            return cls._f(best.get(key), default)

        tp = f("tp")
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
            "source_level": "bmkg",
            "is_live": True,
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "station_type": "Regional Forecast (adm4)",
        }

    @classmethod
    async def _open_meteo(cls, lat: float, lon: float, region_name: str) -> Optional[Dict[str, Any]]:
        params = {
            "latitude": lat, "longitude": lon,
            "current": "temperature_2m,relative_humidity_2m,precipitation,weather_code,cloud_cover,wind_speed_10m",
            "hourly": "precipitation_probability",
            "forecast_hours": 1,
            "timezone": "Asia/Jakarta",
        }
        try:
            async with httpx.AsyncClient(timeout=6.0) as client:
                resp = await client.get(OPEN_METEO_URL, params=params)
            if resp.status_code != 200:
                logger.warning(f"Open-Meteo returned HTTP {resp.status_code}")
                return None
            j = resp.json()
            cur = j.get("current") or {}
            if "temperature_2m" not in cur:
                return None
            pop = (j.get("hourly", {}).get("precipitation_probability") or [0])[0] or 0
            return {
                "region_name": region_name or f"({lat:.3f}, {lon:.3f})",
                "weather_desc": WMO.get(int(cur.get("weather_code", 0)), f"Kode cuaca {cur.get('weather_code')}"),
                "temperature_c": cls._f(cur.get("temperature_2m"), 0.0),
                "humidity_pct": cls._f(cur.get("relative_humidity_2m"), 0.0),
                "rainfall_mm": cls._f(cur.get("precipitation"), 0.0),
                "rainfall_probability_pct": cls._f(pop, 0.0),
                "wind_speed_kmh": cls._f(cur.get("wind_speed_10m"), 0.0),
                "cloud_cover_pct": cls._f(cur.get("cloud_cover"), 0.0),
                "forecast_time": cur.get("time"),
                "source": "Open-Meteo (cadangan, data nyata) - BMKG sedang tidak menyediakan prakiraan",
                "source_level": "open-meteo",
                "is_live": True,
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "station_type": "Model cuaca global (grid ~11 km)",
            }
        except Exception as ex:
            logger.warning(f"Open-Meteo request failed: {ex}")
            return None

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
            "source": "DATA STATIS - semua sumber cuaca tidak dapat dijangkau",
            "source_level": "static",
            "is_live": False,
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "station_type": "Regional Forecast (adm4)",
        }

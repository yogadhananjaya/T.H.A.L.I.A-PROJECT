from enum import Enum
from typing import Dict, Any, Tuple

class StatusLevel(str, Enum):
    SAFE = "Safe"       # Aman
    ALERT = "Alert"     # Waspada
    DANGER = "Danger"   # Bahaya

class DisasterRuleEngine:
    """
    T.H.A.L.I.A Tri-Habitat Rule-Based Classification Engine.
    Evaluates:
      1. Atmosphere: Temperature, Humidity, Barometric Pressure (hPa)
      2. Hydrosphere: Rainfall intensity (mm/h)
      3. Lithosphere: Soil Moisture saturation (%)
    """
    
    @staticmethod
    def evaluate(
        rainfall_mm_h: float,
        soil_moisture_pct: float,
        temperature_c: float,
        humidity_pct: float,
        pressure_hpa: float
    ) -> Tuple[StatusLevel, str, Dict[str, Any]]:
        reasons = []
        habitat_risks = {
            "atmosphere": "Normal",
            "hydrosphere": "Normal",
            "lithosphere": "Normal"
        }
        
        # 1. Lithosphere Evaluation (Critical Landslide Factor)
        if soil_moisture_pct >= 80.0:
            habitat_risks["lithosphere"] = "Extreme Saturation"
            reasons.append(f"Lithosphere: Tanah sangat jenuh air ({soil_moisture_pct:.1f}%), risiko longsor tinggi.")
        elif soil_moisture_pct >= 65.0:
            habitat_risks["lithosphere"] = "High Moisture"
            reasons.append(f"Lithosphere: Kelembapan tanah meningkat ({soil_moisture_pct:.1f}%).")
        
        # 2. Hydrosphere Evaluation (Rainfall Intensity)
        if rainfall_mm_h >= 50.0:
            habitat_risks["hydrosphere"] = "Torrential Rain"
            reasons.append(f"Hydrosphere: Hujan sangat lebat ({rainfall_mm_h:.1f} mm/jam), potensi limpasan air besar.")
        elif rainfall_mm_h >= 20.0:
            habitat_risks["hydrosphere"] = "Moderate/Heavy Rain"
            reasons.append(f"Hydrosphere: Curah hujan sedang-lebat ({rainfall_mm_h:.1f} mm/jam).")

        # 3. Atmosphere Evaluation (Barometric Pressure & Humidity)
        if pressure_hpa < 1005.0 and humidity_pct > 85.0:
            habitat_risks["atmosphere"] = "Storm Warning"
            reasons.append(f"Atmosphere: Tekanan udara rendah ({pressure_hpa:.1f} hPa) dan kelembapan tinggi ({humidity_pct:.1f}%).")

        # Combined Rule Determination:
        # DANGER CONDITIONS:
        # - Soil saturated (>=80%) AND Rainfall moderate/heavy (>=20mm/h) -> Imminent slope collapse / Landslide
        # - OR Soil extremely saturated (>=85%)
        # - OR Rainfall extreme (>=70mm/h)
        if (soil_moisture_pct >= 80.0 and rainfall_mm_h >= 20.0) or soil_moisture_pct >= 85.0 or rainfall_mm_h >= 70.0:
            status = StatusLevel.DANGER
            primary_reason = "BAHAYA: " + " | ".join(reasons)
        # ALERT CONDITIONS:
        # - Soil moisture >= 65% OR Rainfall >= 20mm/h OR Storm warning
        elif soil_moisture_pct >= 65.0 or rainfall_mm_h >= 20.0 or habitat_risks["atmosphere"] == "Storm Warning":
            status = StatusLevel.ALERT
            primary_reason = "WASPADA: " + " | ".join(reasons)
        else:
            status = StatusLevel.SAFE
            primary_reason = "AMAN: Kondisi seluruh habitat (Atmosfer, Hidrosfer, Litosfer) dalam batas normal."

        details = {
            "habitats": habitat_risks,
            "soil_moisture_pct": soil_moisture_pct,
            "rainfall_mm_h": rainfall_mm_h,
            "temperature_c": temperature_c,
            "humidity_pct": humidity_pct,
            "pressure_hpa": pressure_hpa,
            "reasons": reasons
        }

        return status, primary_reason, details

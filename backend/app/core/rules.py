from enum import Enum
from typing import Dict, Any, Tuple, Optional

class StatusLevel(str, Enum):
    SAFE = "Safe"       # Aman
    ALERT = "Alert"     # Waspada
    DANGER = "Danger"   # Bahaya

class DisasterRuleEngine:
    """
    T.H.A.L.I.A Tri-Habitat Rule-Based Classification Engine.
    Evaluates:
      1. Atmosphere: Temperature, Humidity, Barometric Pressure (hPa) - BME280
      2. Hydrosphere: Rainfall intensity (0-100% analog from FC-37) & is_raining
      3. Lithosphere: Soil Moisture saturation (%)
    """

    @staticmethod
    def evaluate(
        rainfall_pct: float,
        soil_moisture_pct: float,
        temperature_c: float,
        humidity_pct: float,
        pressure_hpa: float,
        is_raining: Optional[bool] = None,
    ) -> Tuple[StatusLevel, str, Dict[str, Any]]:
        reasons = []
        habitat_risks = {
            "atmosphere": "Normal",
            "hydrosphere": "Normal",
            "lithosphere": "Normal"
        }

        raining_flag = bool(is_raining) if is_raining is not None else (rainfall_pct >= 15.0)

        # 1. Lithosphere Evaluation (Critical Landslide Factor)
        if soil_moisture_pct >= 80.0:
            habitat_risks["lithosphere"] = "Extreme Saturation"
            reasons.append(f"Lithosphere: Tanah sangat jenuh air ({soil_moisture_pct:.1f}%), risiko longsor tinggi.")
        elif soil_moisture_pct >= 65.0:
            habitat_risks["lithosphere"] = "High Moisture"
            reasons.append(f"Lithosphere: Kelembapan tanah meningkat ({soil_moisture_pct:.1f}%).")

        # 2. Hydrosphere Evaluation (FC-37 Analog Rainfall Intensity 0-100%)
        if rainfall_pct >= 70.0:
            habitat_risks["hydrosphere"] = "Heavy Rain"
            reasons.append(f"Hydrosphere: Intensitas hujan sangat tinggi ({rainfall_pct:.1f}%), potensi limpasan air besar.")
        elif rainfall_pct >= 30.0:
            habitat_risks["hydrosphere"] = "Moderate Rain"
            reasons.append(f"Hydrosphere: Hujan sedang terdeteksi ({rainfall_pct:.1f}%).")
        elif raining_flag:
            habitat_risks["hydrosphere"] = "Light Rain"

        # 3. Atmosphere Evaluation (Barometric Pressure & Humidity)
        if pressure_hpa < 1005.0 and humidity_pct > 85.0:
            habitat_risks["atmosphere"] = "Storm Warning"
            reasons.append(f"Atmosphere: Tekanan udara rendah ({pressure_hpa:.1f} hPa) dan kelembapan tinggi ({humidity_pct:.1f}%).")

        # Combined Rule Determination:
        # DANGER CONDITIONS:
        # - Soil saturated (>=80%) AND Rain moderate/heavy (>=30%) -> Imminent slope collapse / Landslide
        # - OR Soil extremely saturated (>=85%)
        # - OR Rain intensity extreme (>=75%)
        if (soil_moisture_pct >= 80.0 and rainfall_pct >= 30.0) or soil_moisture_pct >= 85.0 or rainfall_pct >= 75.0:
            status = StatusLevel.DANGER
            primary_reason = "BAHAYA: " + " | ".join(reasons)
        # ALERT CONDITIONS:
        # - Soil moisture >= 65% OR Rain intensity >= 30% OR Storm warning
        elif soil_moisture_pct >= 65.0 or rainfall_pct >= 30.0 or habitat_risks["atmosphere"] == "Storm Warning":
            status = StatusLevel.ALERT
            primary_reason = "WASPADA: " + " | ".join(reasons)
        else:
            status = StatusLevel.SAFE
            primary_reason = "AMAN: Kondisi seluruh habitat (Atmosfer, Hidrosfer, Litosfer) dalam batas normal."

        details = {
            "habitats": habitat_risks,
            "soil_moisture_pct": soil_moisture_pct,
            "rainfall_pct": rainfall_pct,
            "is_raining": raining_flag,
            "temperature_c": temperature_c,
            "humidity_pct": humidity_pct,
            "pressure_hpa": pressure_hpa,
            "reasons": reasons
        }

        return status, primary_reason, details

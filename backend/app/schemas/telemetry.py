from pydantic import BaseModel, Field, ConfigDict, model_validator, PlainSerializer
from typing import Optional, Dict, Any, Annotated
from datetime import datetime, timezone


def _serialize_utc(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return dt.isoformat().replace("+00:00", "Z")


UTCDatetime = Annotated[datetime, PlainSerializer(_serialize_utc, return_type=str)]


class TelemetryCreate(BaseModel):
    node_id: str = Field(default="ESP32-NODE-01", description="ID Node IoT")
    location_name: str = Field(default="Cibatu, Cikarang Selatan, Bekasi", description="Nama lokasi sensor")
    latitude: float = Field(default=-6.3378)
    longitude: float = Field(default=107.1541)

    # 1. Atmosphere (BME280)
    temperature_c: float = Field(..., ge=-20, le=70, description="Suhu udara dalam Celsius")
    humidity_pct: float = Field(..., ge=0, le=100, description="Kelembapan udara (%)")
    pressure_hpa: float = Field(..., ge=800, le=1200, description="Tekanan udara (hPa)")

    # 2. Hydrosphere (FC-37 Rain Sensor: 0-100% + optional boolean / legacy mm_h fallback)
    rainfall_pct: Optional[float] = Field(default=None, ge=0, le=100, description="Intensitas hujan FC-37 (0-100%)")
    is_raining: Optional[bool] = Field(default=None, description="Status hujan (true/false)")
    rainfall_mm_h: Optional[float] = Field(default=None, ge=0, le=500, description="Opsional/legacy jika mengirim mm/jam")
    rainfall_raw: Optional[int] = None

    # 3. Lithosphere (Soil moisture sensor)
    soil_moisture_pct: float = Field(..., ge=0, le=100, description="Tingkat kejenuhan tanah (%)")
    soil_raw: Optional[int] = None

    @model_validator(mode="after")
    def resolve_rainfall(self) -> "TelemetryCreate":
        if self.rainfall_pct is None:
            if self.is_raining is not None:
                self.rainfall_pct = 50.0 if self.is_raining else 0.0
            elif self.rainfall_mm_h is not None:
                self.rainfall_pct = min(100.0, float(self.rainfall_mm_h))
            else:
                raise ValueError("Minimal satu dari rainfall_pct atau is_raining harus diisi.")
        if self.is_raining is None:
            self.is_raining = self.rainfall_pct >= 15.0
        return self


class TelemetryResponse(BaseModel):
    id: int
    timestamp: UTCDatetime
    node_id: str
    location_name: str
    latitude: float
    longitude: float
    temperature_c: float
    humidity_pct: float
    pressure_hpa: float
    rainfall_pct: float
    is_raining: bool
    soil_moisture_pct: float
    status: str
    status_reason: Optional[str]
    habitat_analysis: Optional[Dict[str, Any]]

    model_config = ConfigDict(from_attributes=True)


class BMKGForecastItem(BaseModel):
    region_name: str
    weather_desc: str
    temperature_c: float
    humidity_pct: float
    rainfall_probability_pct: float
    updated_at: UTCDatetime


class ComparisonResponse(BaseModel):
    location: str
    timestamp: UTCDatetime
    local_telemetry: Dict[str, Any]
    bmkg_regional_forecast: Dict[str, Any]
    granularity_advantage: str
    status: str


class IncidentAlertResponse(BaseModel):
    id: int
    timestamp: UTCDatetime
    node_id: str
    location_name: str
    severity: str
    cause_summary: str
    data_hash: str
    blockchain_tx_hash: Optional[str]
    blockchain_event_id: Optional[int]
    blockchain_status: str
    fcm_status: str

    model_config = ConfigDict(from_attributes=True)

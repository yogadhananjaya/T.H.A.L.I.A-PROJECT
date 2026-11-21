from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Dict, Any, List
from datetime import datetime

class TelemetryCreate(BaseModel):
    node_id: str = Field(default="ESP32-NODE-01", description="ID Node IoT")
    location_name: str = Field(default="Desa Sukamaju, Lereng Selatan", description="Nama lokasi sensor")
    latitude: float = Field(default=-6.9175)
    longitude: float = Field(default=107.6191)
    
    # 1. Atmosphere
    temperature_c: float = Field(..., ge=-20, le=70, description="Suhu udara dalam Celsius")
    humidity_pct: float = Field(..., ge=0, le=100, description="Kelembapan udara (%)")
    pressure_hpa: float = Field(..., ge=800, le=1200, description="Tekanan udara (hPa)")

    # 2. Hydrosphere
    rainfall_mm_h: float = Field(..., ge=0, le=500, description="Intensitas curah hujan (mm/jam)")
    rainfall_raw: Optional[int] = None

    # 3. Lithosphere
    soil_moisture_pct: float = Field(..., ge=0, le=100, description="Tingkat kejenuhan tanah (%)")
    soil_raw: Optional[int] = None


class TelemetryResponse(BaseModel):
    id: int
    timestamp: datetime
    node_id: str
    location_name: str
    latitude: float
    longitude: float
    temperature_c: float
    humidity_pct: float
    pressure_hpa: float
    rainfall_mm_h: float
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
    updated_at: datetime


class ComparisonResponse(BaseModel):
    location: str
    timestamp: datetime
    local_telemetry: Dict[str, Any]
    bmkg_regional_forecast: Dict[str, Any]
    granularity_advantage: str
    status: str


class IncidentAlertResponse(BaseModel):
    id: int
    timestamp: datetime
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

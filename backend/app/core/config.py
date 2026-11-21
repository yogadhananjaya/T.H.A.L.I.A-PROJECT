import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(case_sensitive=True, env_file=".env", extra="ignore")

    PROJECT_NAME: str = "T.H.A.L.I.A Backend API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Database configuration (PostgreSQL with SQLite fallback for seamless demo)
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "postgresql+psycopg2://postgres:postgres@localhost:5432/thalia_db"
    )
    FALLBACK_SQLITE_URL: str = "sqlite:///./thalia.db"
    
    # Blockchain settings (Hardhat local node)
    HARDHAT_RPC_URL: str = os.getenv("HARDHAT_RPC_URL", "http://127.0.0.1:8545")
    CONTRACT_ADDRESS: str = os.getenv("CONTRACT_ADDRESS", "")
    BLOCKCHAIN_PRIVATE_KEY: str = os.getenv(
        "BLOCKCHAIN_PRIVATE_KEY", 
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" # Default Hardhat Account #0
    )
    
    # BMKG Open Data API settings
    BMKG_API_URL: str = os.getenv("BMKG_API_URL", "https://api.bmkg.go.id/publik/prakiraan-cuaca")
    DEFAULT_REGION_CODE: str = os.getenv("DEFAULT_REGION_CODE", "32.73.05.1001") # Maleber, Andir, Kota Bandung
    
    # Firebase Cloud Messaging (FCM)
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase_service_account.json")
    
    # Thresholds for Disaster Classification
    # Atmosphere
    PRESSURE_DROP_THRESHOLD_HPA: float = 4.0 # Sudden pressure drop indicating storm
    # Hydrosphere (Rainfall in mm/hr)
    RAIN_MODERATE_THRESHOLD: float = 20.0
    RAIN_HEAVY_THRESHOLD: float = 50.0
    # Lithosphere (Soil Moisture in %)
    SOIL_SATURATION_ALERT: float = 65.0
    SOIL_SATURATION_DANGER: float = 80.0

settings = Settings()

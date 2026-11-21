import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import settings
from app.api.v1.router import api_router
from app.db.session import engine, Base
import app.db.models # Ensure models are loaded

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("thalia_backend")

# Ensure database tables exist immediately on import/startup
Base.metadata.create_all(bind=engine)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing T.H.A.L.I.A Database Tables...")
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database initialized successfully.")
    except Exception as e:
        logger.error(f"Error creating database tables: {e}")
    yield
    logger.info("Shutting down T.H.A.L.I.A Backend API.")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description=(
        "Backend API for T.H.A.L.I.A (Tri-Habitat Analysis & Climate Forecasting Intelligence).\n"
        "Provides real-time IoT ingestion, rule-based classification across 3 habitats (Atmosphere, Hydrosphere, Lithosphere), "
        "side-by-side BMKG comparison, FCM push notifications, and immutable Hardhat blockchain audit trail."
    ),
    lifespan=lifespan
)

# Configure CORS for Flutter app & frontend integrations
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

from fastapi.responses import FileResponse
import os as _os

@app.get("/dashboard", include_in_schema=False)
def dashboard():
    return FileResponse(_os.path.join(_os.path.dirname(__file__), "static", "dashboard.html"))

@app.get("/", tags=["Health Check"])
def root():
    return {
        "project": "T.H.A.L.I.A",
        "team": "Ayam Kecap Paijo (ASTRA Polytechnic)",
        "competition": "HACKSPHERE 2026",
        "status": "OPERATIONAL",
        "docs_url": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)

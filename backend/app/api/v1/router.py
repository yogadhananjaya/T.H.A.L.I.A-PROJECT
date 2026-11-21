from fastapi import APIRouter
from app.api.v1.endpoints import alerts, auth, comparison, forecast, reports, simulator, telemetry

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication & Profile"])
api_router.include_router(forecast.router, prefix="/forecast", tags=["Weather Forecast"])
api_router.include_router(reports.router, prefix="/reports", tags=["Field Citizen Reports"])
api_router.include_router(telemetry.router, prefix="/telemetry", tags=["IoT Telemetry"])
api_router.include_router(comparison.router, prefix="/comparison", tags=["BMKG Side-by-Side Comparison"])
api_router.include_router(alerts.router, prefix="/alerts", tags=["Disaster Incidents & Blockchain Audit"])
api_router.include_router(simulator.router, prefix="/simulator", tags=["Hackathon Demo Simulator"])

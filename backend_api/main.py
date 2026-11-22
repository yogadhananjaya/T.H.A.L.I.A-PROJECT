"""Server API Mandiri T.H.A.L.I.A (FastAPI + PostgreSQL thalia_db) dengan Arsitektur 2 Pintu."""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routes_iot import router as iot_router
from routes_users import router as users_router


@asynccontextmanager
async def lifespan(_app: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="T.H.A.L.I.A Personal API (PostgreSQL)",
    version="1.0.0",
    description=(
        "Server API mandiri T.H.A.L.I.A berbasis PostgreSQL (`thalia_db`) dengan 2 Pintu:\n"
        "- **Pintu 1**: Autentikasi, Registrasi, Profil, & Keamanan Pengguna\n"
        "- **Pintu 2**: Telemetri Real-Time IoT ESP32, Prakiraan 5 Hari, & Laporan Warga"
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users_router)
app.include_router(iot_router)


@app.get("/", tags=["Health Check"])
def health_check():
    return {
        "service": "T.H.A.L.I.A Personal API",
        "database": "PostgreSQL (thalia_db)",
        "status": "online",
        "docs": "/docs",
    }

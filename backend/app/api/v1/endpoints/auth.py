import re
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)
from app.db.models import User
from app.db.session import get_db

router = APIRouter()


class RegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=120)
    email: str = Field(..., min_length=3, max_length=120)
    password: str = Field(..., min_length=5, max_length=128)
    location_name: str = ""
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class LoginRequest(BaseModel):
    username: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=5, max_length=128)


class ForgotPasswordRequest(BaseModel):
    email: str = Field(..., min_length=3)


class ProfileUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    handle: Optional[str] = None
    location_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_km: Optional[int] = None


def _build_session_response(user: User, token: str) -> dict:
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "name": user.full_name,
            "email": user.email,
            "username": user.username,
            "phone": user.phone or "-",
            "handle": user.handle or f"@{user.username}",
            "role": user.role,
            "location_name": user.location_name or "",
            "latitude": user.latitude,
            "longitude": user.longitude,
            "radius_km": user.radius_km or 5,
        },
        "user_id": user.id,
        "user_name": user.full_name,
        "email": user.email,
        "username": user.username,
        "phone": user.phone or "-",
        "handle": user.handle or f"@{user.username}",
        "role": user.role,
        "location_name": user.location_name or "",
        "latitude": user.latitude,
        "longitude": user.longitude,
        "radius_km": user.radius_km or 5,
    }


def _ensure_demo_admin_seeded(db: Session) -> None:
    """Seed default demo officer account (admin / 123) if it does not exist yet."""
    existing = db.query(User).filter(User.username == "admin").first()
    if existing:
        return
    demo = User(
        full_name="Petugas Siaga T.H.A.L.I.A",
        email="admin@gmail.com",
        username="admin",
        hashed_password=hash_password("123"),
        phone="+62 812-0000-2026",
        handle="@petugas_thalia",
        role="admin",
        location_name="Cibatu, Cikarang Selatan, Bekasi",
        latitude=-6.3378,
        longitude=107.1541,
        radius_km=5,
    )
    db.add(demo)
    db.commit()


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    """Daftarkan akun petugas/warga baru dan kembalikan sesi login."""
    clean_name = payload.full_name.strip()
    if not re.match(r"^[a-zA-Z\s.'-]+$", clean_name):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nama hanya boleh berisi huruf, spasi, titik, apostrof, atau tanda hubung.",
        )

    clean_email = payload.email.strip().lower()
    if not re.match(r"^[a-zA-Z0-9._%+-]+@gmail\.com$", clean_email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email harus menggunakan domain @gmail.com.",
        )

    if db.query(User).filter(User.email == clean_email).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email sudah terdaftar. Silakan masuk.",
        )

    base_username = clean_email.split("@")[0]
    username = base_username
    suffix = 1
    while db.query(User).filter(User.username == username).first():
        username = f"{base_username}{suffix}"
        suffix += 1

    user = User(
        full_name=clean_name,
        email=clean_email,
        username=username,
        hashed_password=hash_password(payload.password),
        handle=f"@{username}",
        location_name=payload.location_name.strip(),
        latitude=payload.latitude,
        longitude=payload.longitude,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id, user.username)
    return _build_session_response(user, token)


@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """Autentikasi petugas/warga memakai email atau username/ID."""
    _ensure_demo_admin_seeded(db)

    identifier = payload.username.strip().lower()
    user = (
        db.query(User)
        .filter((User.email == identifier) | (User.username == identifier))
        .first()
    )
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email/ID Petugas atau kata sandi salah.",
        )

    token = create_access_token(user.id, user.username)
    return _build_session_response(user, token)


@router.post("/change-password")
def change_password(
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Ubah kata sandi akun yang sedang masuk."""
    if not verify_password(payload.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kata sandi saat ini tidak sesuai.",
        )
    if payload.current_password == payload.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kata sandi baru tidak boleh sama dengan kata sandi lama.",
        )

    current_user.hashed_password = hash_password(payload.new_password)
    db.commit()
    return {"message": "Kata sandi berhasil diperbarui."}


@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest):
    """Menerima permintaan tautan reset kata sandi."""
    clean_email = payload.email.strip().lower()
    if "@" not in clean_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Format email tidak valid.",
        )
    return {
        "message": f"Permintaan reset kata sandi untuk {clean_email} telah dicatat. Cek kotak masuk Anda."
    }


@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    """Mengembalikan profil lengkap pengguna yang sedang login."""
    return {
        "user_id": current_user.id,
        "user_name": current_user.full_name,
        "email": current_user.email,
        "username": current_user.username,
        "phone": current_user.phone or "-",
        "handle": current_user.handle or f"@{current_user.username}",
        "role": current_user.role,
        "location_name": current_user.location_name or "",
        "latitude": current_user.latitude,
        "longitude": current_user.longitude,
        "radius_km": current_user.radius_km or 5,
    }


@router.put("/me")
def update_me(
    payload: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Memperbarui profil atau lokasi pantauan pengguna."""
    if payload.full_name is not None and payload.full_name.strip():
        current_user.full_name = payload.full_name.strip()
    if payload.phone is not None:
        current_user.phone = payload.phone.strip()
    if payload.handle is not None:
        current_user.handle = payload.handle.strip()
    if payload.location_name is not None:
        current_user.location_name = payload.location_name.strip()
    if payload.latitude is not None:
        current_user.latitude = payload.latitude
    if payload.longitude is not None:
        current_user.longitude = payload.longitude
    if payload.radius_km is not None:
        current_user.radius_km = max(1, min(50, payload.radius_km))

    db.commit()
    db.refresh(current_user)
    return get_me(current_user)

"""PINTU 1 — API Pengguna & Autentikasi (Register, Login, Profil, Ganti & Lupa Sandi)."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from database import get_conn, hash_password, verify_password
from security import create_session_token, require_current_user

router = APIRouter(prefix="/api/v1/auth", tags=["Pintu 1 - Pengguna & Auth"])


class LoginRequest(BaseModel):
    username: str
    password: str


class RegisterRequest(BaseModel):
    full_name: str
    email: str
    password: str
    location_name: str = "Cikarang Utara, Bekasi"
    latitude: float | None = -6.2845
    longitude: float | None = 107.1705


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class ForgotPasswordRequest(BaseModel):
    email: str


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    handle: str | None = None
    location_name: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    radius_km: int | None = None


def _session_payload(user: dict, token: str) -> dict:
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user["id"],
            "name": user["full_name"],
            "email": user["email"],
            "phone": user.get("phone") or "-",
            "handle": user.get("handle") or f"@{user['username']}",
            "role": user.get("role") or "warga",
            "location_name": user.get("location_name") or "Cikarang Utara, Bekasi",
            "latitude": user.get("latitude"),
            "longitude": user.get("longitude"),
            "radius_km": user.get("radius_km") or 5,
        },
    }


@router.post("/register")
def register_user(req: RegisterRequest):
    clean_name = req.full_name.strip()
    clean_email = req.email.strip().lower()
    if not clean_name:
        raise HTTPException(status_code=400, detail="Nama lengkap tidak boleh kosong.")
    if not clean_email or "@" not in clean_email:
        raise HTTPException(status_code=400, detail="Alamat email tidak valid.")
    if len(req.password) < 5:
        raise HTTPException(status_code=400, detail="Kata sandi minimal 5 karakter.")

    base_username = clean_email.split("@")[0]
    pwd_hash, salt = hash_password(req.password)

    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute("SELECT id FROM users WHERE LOWER(email) = %s;", (clean_email,))
        if cur.fetchone():
            raise HTTPException(
                status_code=409,
                detail="Email sudah terdaftar. Silakan masuk.",
            )

        # Pastikan username unik
        username = base_username
        suffix = 1
        while True:
            cur.execute("SELECT id FROM users WHERE LOWER(username) = %s;", (username.lower(),))
            if not cur.fetchone():
                break
            suffix += 1
            username = f"{base_username}{suffix}"

        cur.execute(
            """
            INSERT INTO users (
                full_name, username, email, password_hash, password_salt,
                phone, handle, role, location_name, latitude, longitude, radius_km
            )
            VALUES (%s, %s, %s, %s, %s, '-', %s, 'warga', %s, %s, %s, 5)
            RETURNING *;
            """,
            (
                clean_name,
                username,
                clean_email,
                pwd_hash,
                salt,
                f"@{username}",
                req.location_name.strip() or "Cikarang Utara, Bekasi",
                req.latitude if req.latitude is not None else -6.2845,
                req.longitude if req.longitude is not None else 107.1705,
            ),
        )
        new_user = dict(cur.fetchone())

    token = create_session_token(new_user["id"])
    return _session_payload(new_user, token)


@router.post("/login")
def login_user(req: LoginRequest):
    identifier = req.username.strip().lower()
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT * FROM users
            WHERE LOWER(username) = %s OR LOWER(email) = %s
            LIMIT 1;
            """,
            (identifier, identifier),
        )
        row = cur.fetchone()

    if not row or not verify_password(req.password, row["password_hash"], row["password_salt"]):
        raise HTTPException(
            status_code=401,
            detail="Username/email atau kata sandi salah.",
        )

    user = dict(row)
    token = create_session_token(user["id"])
    return _session_payload(user, token)


@router.post("/change-password")
def change_password(
    req: ChangePasswordRequest,
    current_user: dict = Depends(require_current_user),
):
    if not verify_password(
        req.current_password,
        current_user["password_hash"],
        current_user["password_salt"],
    ):
        raise HTTPException(status_code=400, detail="Kata sandi saat ini salah.")
    if len(req.new_password) < 5:
        raise HTTPException(status_code=400, detail="Kata sandi baru minimal 5 karakter.")
    if req.current_password == req.new_password:
        raise HTTPException(
            status_code=400,
            detail="Kata sandi baru harus berbeda dari yang lama.",
        )

    new_hash, new_salt = hash_password(req.new_password)
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE users
            SET password_hash = %s, password_salt = %s
            WHERE id = %s;
            """,
            (new_hash, new_salt, current_user["id"]),
        )
    return {"ok": True, "message": "Kata sandi berhasil diperbarui."}


@router.post("/forgot-password")
def forgot_password(req: ForgotPasswordRequest):
    clean_email = req.email.strip().lower()
    if not clean_email or "@" not in clean_email:
        raise HTTPException(status_code=400, detail="Masukkan alamat email yang valid.")

    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO password_reset_requests (email) VALUES (%s);",
            (clean_email,),
        )
    return {
        "ok": True,
        "message": f"Permintaan reset kata sandi untuk {clean_email} telah dicatat.",
    }


@router.get("/me")
def get_me(current_user: dict = Depends(require_current_user)):
    return {
        "user_name": current_user["full_name"],
        "email": current_user["email"],
        "phone": current_user.get("phone") or "-",
        "handle": current_user.get("handle") or f"@{current_user['username']}",
        "role": current_user.get("role") or "warga",
        "location_name": current_user.get("location_name") or "Cikarang Utara, Bekasi",
        "latitude": current_user.get("latitude"),
        "longitude": current_user.get("longitude"),
        "radius_km": current_user.get("radius_km") or 5,
    }


@router.put("/me")
def update_profile(
    req: UpdateProfileRequest,
    current_user: dict = Depends(require_current_user),
):
    new_name = req.full_name.strip() if req.full_name and req.full_name.strip() else current_user["full_name"]
    new_phone = req.phone.strip() if req.phone is not None else current_user["phone"]
    new_handle = req.handle.strip() if req.handle is not None else current_user["handle"]
    new_loc = req.location_name.strip() if req.location_name is not None else current_user["location_name"]
    new_lat = req.latitude if req.latitude is not None else current_user["latitude"]
    new_lng = req.longitude if req.longitude is not None else current_user["longitude"]
    new_radius = req.radius_km if req.radius_km is not None else current_user["radius_km"]

    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE users
            SET full_name = %s,
                phone = %s,
                handle = %s,
                location_name = %s,
                latitude = %s,
                longitude = %s,
                radius_km = %s
            WHERE id = %s
            RETURNING *;
            """,
            (
                new_name,
                new_phone,
                new_handle,
                new_loc,
                new_lat,
                new_lng,
                new_radius,
                current_user["id"],
            ),
        )
        updated = dict(cur.fetchone())

    return {
        "user_name": updated["full_name"],
        "email": updated["email"],
        "phone": updated["phone"],
        "handle": updated["handle"],
        "role": updated["role"],
        "location_name": updated["location_name"],
        "latitude": updated["latitude"],
        "longitude": updated["longitude"],
        "radius_km": updated["radius_km"],
    }

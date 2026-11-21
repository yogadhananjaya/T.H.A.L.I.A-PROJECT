import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.db.models import User
from app.db.session import get_db

_SECRET_KEY = os.environ.get("THALIA_SECRET_KEY", "thalia-hacksphere-2026-secret-key").encode("utf-8")
_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 7  # 7 days
_bearer_scheme = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    """Hash password using PBKDF2-HMAC-SHA256 with a random 16-byte salt."""
    salt = secrets.token_hex(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100_000)
    return f"pbkdf2_sha256${salt}${dk.hex()}"


def verify_password(password: str, stored_hash: str) -> bool:
    """Constant-time verification of password against stored PBKDF2 hash."""
    try:
        algo, salt, expected_hex = stored_hash.split("$", 2)
        if algo != "pbkdf2_sha256":
            return False
        dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100_000)
        return hmac.compare_digest(dk.hex(), expected_hex)
    except Exception:
        return False


def create_access_token(user_id: int, username: str) -> str:
    """Create a signed URL-safe token containing user_id, username, and exp."""
    payload = {
        "sub": user_id,
        "username": username,
        "exp": int(time.time()) + _TOKEN_TTL_SECONDS,
    }
    payload_b64 = base64.urlsafe_b64encode(json.dumps(payload, separators=(",", ":")).encode("utf-8")).decode("ascii")
    sig = hmac.new(_SECRET_KEY, payload_b64.encode("ascii"), hashlib.sha256).hexdigest()
    return f"{payload_b64}.{sig}"


def decode_access_token(token: str) -> Optional[dict]:
    """Verify signature and expiration, returning payload dict or None."""
    try:
        payload_b64, sig = token.split(".", 1)
        expected_sig = hmac.new(_SECRET_KEY, payload_b64.encode("ascii"), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(sig, expected_sig):
            return None
        payload = json.loads(base64.urlsafe_b64decode(payload_b64.encode("ascii")).decode("utf-8"))
        if payload.get("exp", 0) < int(time.time()):
            return None
        return payload
    except Exception:
        return None


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """FastAPI dependency that validates Bearer token and returns the User."""
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesi tidak valid atau telah berakhir. Silakan masuk kembali.",
        )
    payload = decode_access_token(credentials.credentials)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token kedaluwarsa atau tidak sah.",
        )
    user = db.query(User).filter(User.id == payload.get("sub")).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Akun tidak ditemukan.",
        )
    return user


def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
    db: Session = Depends(get_db),
) -> Optional[User]:
    """Return authenticated User if valid Bearer token provided, else None."""
    if not credentials or not credentials.credentials:
        return None
    payload = decode_access_token(credentials.credentials)
    if not payload:
        return None
    return db.query(User).filter(User.id == payload.get("sub")).first()

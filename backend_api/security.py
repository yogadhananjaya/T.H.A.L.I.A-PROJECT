"""Helper autentikasi Bearer Token berbasis tabel user_sessions di PostgreSQL."""

import secrets
from fastapi import Header, HTTPException
from database import get_conn


def create_session_token(user_id: int) -> str:
    """Membuat token baru dan menyimpannya ke tabel user_sessions."""
    token = f"thalia_{secrets.token_urlsafe(32)}"
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO user_sessions (token, user_id) VALUES (%s, %s);",
            (token, user_id),
        )
    return token


def _extract_bearer(authorization: str | None) -> str | None:
    if not authorization:
        return None
    parts = authorization.strip().split(" ", 1)
    if len(parts) == 2 and parts[0].lower() == "bearer":
        return parts[1].strip()
    return None


def get_optional_user(authorization: str | None = Header(default=None)) -> dict | None:
    """Mengembalikan dict user bila token valid, atau None bila tidak mengirim token."""
    token = _extract_bearer(authorization)
    if not token:
        return None
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT u.*
            FROM user_sessions s
            JOIN users u ON u.id = s.user_id
            WHERE s.token = %s;
            """,
            (token,),
        )
        row = cur.fetchone()
    return dict(row) if row else None


def require_current_user(authorization: str | None = Header(default=None)) -> dict:
    """Dependency FastAPI: mewajibkan Bearer token valid, kalau tidak lempar 401."""
    user = get_optional_user(authorization)
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Sesi Anda telah berakhir. Silakan masuk kembali.",
        )
    return user

"""Koneksi PostgreSQL (thalia_db) dan inisialisasi skema tabel T.H.A.L.I.A."""

from contextlib import contextmanager
import hashlib
import os
import secrets
import psycopg2
from psycopg2.extras import RealDictCursor

DB_CONFIG = {
    "host": os.environ.get("THALIA_DB_HOST", "localhost"),
    "port": int(os.environ.get("THALIA_DB_PORT", "5432")),
    "dbname": os.environ.get("THALIA_DB_NAME", "thalia_db"),
    "user": os.environ.get("THALIA_DB_USER", "postgres"),
    "password": os.environ.get("THALIA_DB_PASSWORD", "112511"),
}


@contextmanager
def get_conn():
    """Membuka koneksi PostgreSQL dengan RealDictCursor dan auto commit/rollback."""
    conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def hash_password(password: str, salt: str | None = None) -> tuple[str, str]:
    """Hash password dengan PBKDF2-HMAC-SHA256 + salt acak."""
    salt_hex = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt_hex.encode("utf-8"),
        100_000,
    ).hex()
    return digest, salt_hex


def verify_password(password: str, stored_hash: str, salt: str) -> bool:
    digest, _ = hash_password(password, salt)
    return secrets.compare_digest(digest, stored_hash)


def init_db() -> None:
    """Membuat seluruh tabel di PostgreSQL thalia_db dan mengisi data awal bila masih kosong."""
    with get_conn() as conn:
        cur = conn.cursor()

        # 1. Tabel Pengguna (Pintu 1 - Auth & Profil)
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                full_name VARCHAR(120) NOT NULL,
                username VARCHAR(80) UNIQUE NOT NULL,
                email VARCHAR(160) UNIQUE NOT NULL,
                password_hash VARCHAR(128) NOT NULL,
                password_salt VARCHAR(64) NOT NULL,
                phone VARCHAR(40) DEFAULT '-',
                handle VARCHAR(80) DEFAULT '',
                role VARCHAR(30) NOT NULL DEFAULT 'warga',
                location_name VARCHAR(160) DEFAULT 'Cikarang Utara, Bekasi',
                latitude DOUBLE PRECISION DEFAULT -6.2845,
                longitude DOUBLE PRECISION DEFAULT 107.1705,
                radius_km INTEGER DEFAULT 5,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """
        )

        # 2. Tabel Sesi Login (Token Bearer aktif)
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS user_sessions (
                token VARCHAR(128) PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """
        )

        # 3. Tabel Permintaan Reset Sandi
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS password_reset_requests (
                id SERIAL PRIMARY KEY,
                email VARCHAR(160) NOT NULL,
                requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """
        )

        # 4. Tabel Telemetri IoT Real-Time (Pintu 2 - Sensor ESP32)
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS iot_telemetry (
                id SERIAL PRIMARY KEY,
                node_id VARCHAR(60) NOT NULL DEFAULT 'ESP32-NODE-01',
                location_name VARCHAR(160) NOT NULL DEFAULT 'Cikarang Utara, Bekasi',
                latitude DOUBLE PRECISION NOT NULL DEFAULT -6.2845,
                longitude DOUBLE PRECISION NOT NULL DEFAULT 107.1705,
                temperature_c DOUBLE PRECISION NOT NULL,
                humidity_pct DOUBLE PRECISION NOT NULL,
                pressure_hpa DOUBLE PRECISION NOT NULL DEFAULT 1011.0,
                rainfall_pct DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                is_raining BOOLEAN NOT NULL DEFAULT FALSE,
                rainfall_mm_per_hour DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                water_level_cm DOUBLE PRECISION NOT NULL DEFAULT 100.0,
                soil_moisture_pct DOUBLE PRECISION NOT NULL DEFAULT 50.0,
                condition_code VARCHAR(40) NOT NULL DEFAULT 'sunny',
                status VARCHAR(20) NOT NULL DEFAULT 'aman',
                status_reason TEXT DEFAULT 'Kondisi seluruh habitat dalam batas normal.',
                recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """
        )

        # Pastikan kolom rain drop sensor ada bila tabel sudah terbentuk sebelumnya
        cur.execute(
            """
            ALTER TABLE iot_telemetry
                ADD COLUMN IF NOT EXISTS rainfall_pct DOUBLE PRECISION NOT NULL DEFAULT 0.0,
                ADD COLUMN IF NOT EXISTS is_raining BOOLEAN NOT NULL DEFAULT FALSE;
            """
        )

        # 5. Tabel Laporan Lapangan Warga (Pintu 2 - Kamera & Verifikasi Petugas)
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS field_reports (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
                title VARCHAR(200) NOT NULL,
                category VARCHAR(60) NOT NULL,
                habitat VARCHAR(40) NOT NULL DEFAULT 'field',
                description TEXT NOT NULL,
                metric_summary VARCHAR(200) DEFAULT '',
                location_name VARCHAR(160) NOT NULL DEFAULT 'Cikarang Utara, Bekasi',
                latitude DOUBLE PRECISION NOT NULL DEFAULT -6.2845,
                longitude DOUBLE PRECISION NOT NULL DEFAULT 107.1705,
                status VARCHAR(30) NOT NULL DEFAULT 'received',
                photo_path VARCHAR(255),
                verified_by VARCHAR(120),
                verification_note TEXT,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );
            """
        )

        # Seed akun awal jika tabel users masih kosong
        cur.execute("SELECT COUNT(*) AS cnt FROM users;")
        if cur.fetchone()["cnt"] == 0:
            starter_users = [
                ("Admin T.H.A.L.I.A", "admin", "admin@gmail.com", "123", "+62 812-0000-2026", "@admin_thalia", "admin"),
                ("Petugas Verifikator T.H.A.L.I.A", "staff", "staff@gmail.com", "123", "+62 812-0000-2027", "@staff_verifikator", "staff"),
                ("Warga Pelapor T.H.A.L.I.A", "warga", "warga@gmail.com", "123", "+62 812-0000-2028", "@warga_pelapor", "warga"),
            ]
            for full_name, username, email, pwd, phone, handle, role in starter_users:
                pwd_hash, salt = hash_password(pwd)
                cur.execute(
                    """
                    INSERT INTO users (full_name, username, email, password_hash, password_salt, phone, handle, role)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT DO NOTHING;
                    """,
                    (full_name, username, email, pwd_hash, salt, phone, handle, role),
                )

        # Seed pembacaan awal ESP32 jika tabel iot_telemetry masih kosong
        cur.execute("SELECT COUNT(*) AS cnt FROM iot_telemetry;")
        if cur.fetchone()["cnt"] == 0:
            cur.execute(
                """
                INSERT INTO iot_telemetry (
                    node_id, location_name, latitude, longitude,
                    temperature_c, humidity_pct, pressure_hpa,
                    rainfall_mm_per_hour, water_level_cm, soil_moisture_pct,
                    condition_code, status, status_reason
                ) VALUES (
                    'ESP32-NODE-01', 'Cikarang Utara, Bekasi', -6.2845, 107.1705,
                    26.4, 77.0, 1011.2,
                    2.0, 110.0, 52.0,
                    'light_rain', 'aman', 'AMAN: Pembacaan awal sensor ESP32 normal.'
                );
                """
            )

        # Seed contoh laporan warga jika tabel field_reports masih kosong
        cur.execute("SELECT COUNT(*) AS cnt FROM field_reports;")
        if cur.fetchone()["cnt"] == 0:
            starter_reports = [
                (
                    "Luapan Pintu Air Manggarai",
                    "Banjir",
                    "hydrosphere",
                    "Debit air meningkat setelah hujan lokal di area hulu, genangan sekitar 25 cm.",
                    "Tinggi Air 110 cm • pH 6.8",
                    "Cikarang Utara, Bekasi",
                    -6.2845,
                    107.1705,
                    "received",
                    None,
                    None,
                ),
                (
                    "Kelembapan Lereng Bukit Selatan",
                    "Tanah Longsor",
                    "lithosphere",
                    "Kondisi lereng stabil setelah pengecekan sensor kelembapan tanah.",
                    "Tanah 52% • Lereng Stabil",
                    "Cikarang Selatan, Bekasi",
                    -6.3378,
                    107.1541,
                    "verified",
                    "Petugas Verifikator T.H.A.L.I.A",
                    "Terverifikasi aman di lapangan.",
                ),
            ]
            for row in starter_reports:
                cur.execute(
                    """
                    INSERT INTO field_reports (
                        title, category, habitat, description, metric_summary,
                        location_name, latitude, longitude, status,
                        verified_by, verification_note
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                    """,
                    row,
                )

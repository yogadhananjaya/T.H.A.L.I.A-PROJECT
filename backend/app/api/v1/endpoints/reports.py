import base64
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.orm import Session

from app.core.security import get_optional_user
from app.db.models import FieldReport, User
from app.db.session import get_db

router = APIRouter()


def _utc_z(dt: Optional[datetime]) -> str:
    if dt is None:
        dt = datetime.now(timezone.utc)
    elif dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return dt.isoformat().replace("+00:00", "Z")


def _infer_habitat(category: str) -> str:
    cat = category.lower()
    if "banjir" in cat or "air" in cat:
        return "hydrosphere"
    if "longsor" in cat or "gempa" in cat or "tanah" in cat:
        return "lithosphere"
    if "hujan" in cat or "badai" in cat or "kebakaran" in cat:
        return "atmosphere"
    return "lapangan"


def _serialize_report(r: FieldReport) -> dict:
    return {
        "id": str(r.id),
        "title": f"Laporan {r.category} • {r.location_name}",
        "category": r.category,
        "habitat": _infer_habitat(r.category),
        "description": r.description,
        "metric_summary": r.metric_summary or r.description[:100],
        "location_name": r.location_name,
        "latitude": r.latitude,
        "longitude": r.longitude,
        "status": r.status,
        "created_at": _utc_z(r.created_at),
        "reporter_name": r.reporter_name,
        "has_photo": bool(r.photo_base64),
    }


@router.get("")
def list_reports(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """Mengembalikan daftar laporan lapangan warga & petugas dengan dukungan pagination."""
    total = db.query(FieldReport).count()
    rows = (
        db.query(FieldReport)
        .order_by(FieldReport.id.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return {
        "reports": [_serialize_report(r) for r in rows],
        "total": total,
        "limit": limit,
        "offset": offset,
    }


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_report(
    request: Request,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
):
    """Menerima laporan lapangan warga/petugas via JSON atau Multipart Form-Data."""
    content_type = request.headers.get("content-type", "").lower()

    photo_b64: Optional[str] = None
    if "multipart/form-data" in content_type:
        form = await request.form()
        category = str(form.get("category") or "").strip()
        description = str(form.get("description") or "").strip()
        location_name = str(form.get("location_name") or "Lokasi Terpantau").strip()
        lat_raw = form.get("latitude")
        lng_raw = form.get("longitude")
        latitude = float(lat_raw) if lat_raw not in (None, "") else None
        longitude = float(lng_raw) if lng_raw not in (None, "") else None
        photo_file = form.get("photo")
        if photo_file is not None and hasattr(photo_file, "read"):
            raw_bytes = await photo_file.read()
            if raw_bytes:
                photo_b64 = base64.b64encode(raw_bytes).decode("ascii")
    else:
        body = await request.json()
        category = str(body.get("category") or "").strip()
        description = str(body.get("description") or "").strip()
        location_name = str(body.get("location_name") or "Lokasi Terpantau").strip()
        latitude = body.get("latitude")
        longitude = body.get("longitude")
        photo_b64 = body.get("photo_base64")

    if not category:
        raise HTTPException(status_code=400, detail="Kategori laporan wajib diisi.")
    if len(description) < 10:
        raise HTTPException(
            status_code=400,
            detail="Deskripsi laporan minimal 10 karakter.",
        )

    report = FieldReport(
        user_id=current_user.id if current_user else None,
        reporter_name=current_user.full_name if current_user else "Petugas T.H.A.L.I.A",
        category=category,
        description=description,
        location_name=location_name or "Lokasi Terpantau",
        latitude=latitude,
        longitude=longitude,
        status="received",
        metric_summary=description[:90],
        photo_base64=photo_b64,
        created_at=datetime.now(timezone.utc),
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return _serialize_report(report)

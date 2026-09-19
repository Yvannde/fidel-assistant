"""Jobs internes (cron) — authentifiés par X-Cron-Secret."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppException
from app.deps import get_db
from app.services import aidant_push_service, patient_suivi_service

router = APIRouter(prefix="/internal/jobs", tags=["internal-jobs"])


def _require_cron_secret(x_cron_secret: str | None = Header(default=None)) -> None:
    expected = (settings.cron_secret or "").strip()
    provided = (x_cron_secret or "").strip()
    if not expected or provided != expected:
        raise AppException(
            "UNAUTHORIZED",
            "Secret cron invalide ou manquant.",
            status_code=401,
        )


@router.post("/scan-prises-non-confirmees")
async def scan_prises_non_confirmees(
    db: AsyncSession = Depends(get_db),
    _: None = Depends(_require_cron_secret),
) -> dict:
    """Scan prises en_attente hors délai — FCM aidants si opt-in patient."""
    return await aidant_push_service.scan_prises_non_confirmees(db)


@router.post("/mark-prises-manquees")
async def mark_prises_manquees(
    db: AsyncSession = Depends(get_db),
    _: None = Depends(_require_cron_secret),
) -> dict:
    """en_attente → manquee après grâce (PRISE_MANQUEE_GRACE_HOURS, défaut 12 h)."""
    return await patient_suivi_service.mark_prises_manquees(db)

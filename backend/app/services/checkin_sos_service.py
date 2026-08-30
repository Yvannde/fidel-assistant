"""Check-in quotidien et alerte SOS (fenêtre d'annulation 30s)."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppException
from app.models import CheckIn, ContactUrgence, SosAlerte, User
from app.services import notification_service
from app.services.onboarding_service import _require_patient

VALID_CHECKIN = {"ca_va", "pas_top"}


def _patient_tz(user: User) -> ZoneInfo:
    try:
        return ZoneInfo(user.fuseau_horaire or "UTC")
    except Exception:
        return ZoneInfo("UTC")


def _aware(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt


async def create_check_in(db: AsyncSession, *, user: User, statut: str) -> dict:
    if statut not in VALID_CHECKIN:
        raise AppException(
            "TYPE_INVALIDE",
            "Statut de check-in invalide. Choisis « ça va » ou « pas top ».",
            status_code=400,
        )
    patient = _require_patient(user)
    today = datetime.now(_patient_tz(user)).date()

    existing = await db.execute(
        select(CheckIn).where(CheckIn.patient_id == patient.user_id, CheckIn.date == today)
    )
    if existing.scalar_one_or_none() is not None:
        raise AppException(
            "CHECK_IN_DEJA_FAIT_AUJOURDHUI",
            "Tu as déjà fait ton check-in aujourd'hui. Reviens demain.",
            status_code=409,
        )

    row = CheckIn(patient_id=patient.user_id, date=today, statut=statut)
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return _serialize_check_in(row)


async def list_check_ins(
    db: AsyncSession, *, user: User, depuis: date | None = None
) -> list[dict]:
    patient = _require_patient(user)
    stmt = select(CheckIn).where(CheckIn.patient_id == patient.user_id)
    if depuis is not None:
        stmt = stmt.where(CheckIn.date >= depuis)
    stmt = stmt.order_by(CheckIn.date.desc())
    result = await db.execute(stmt)
    return [_serialize_check_in(r) for r in result.scalars().all()]


def _serialize_check_in(row: CheckIn) -> dict:
    return {
        "id": row.id,
        "date": row.date,
        "statut": row.statut,
        "created_at": row.created_at,
    }


async def trigger_sos(db: AsyncSession, *, user: User) -> dict:
    patient = _require_patient(user)
    contacts = (
        await db.execute(
            select(ContactUrgence).where(ContactUrgence.patient_id == patient.user_id)
        )
    ).scalars().all()
    if not contacts:
        raise AppException(
            "AUCUN_CONTACT_URGENCE",
            "Ajoute au moins un contact d'urgence avant d'utiliser le SOS.",
            status_code=400,
        )

    now = datetime.now(UTC)
    window = timedelta(seconds=settings.sos_cancel_window_seconds)
    sos = SosAlerte(
        patient_id=patient.user_id,
        statut="en_attente",
        annulable_jusqu_a=now + window,
    )
    db.add(sos)
    await db.commit()
    await db.refresh(sos)
    return {"sos_id": sos.id, "annulable_jusqu_a": sos.annulable_jusqu_a}


async def cancel_sos(db: AsyncSession, *, user: User, sos_id: UUID) -> dict:
    patient = _require_patient(user)
    sos = await db.get(SosAlerte, sos_id)
    if sos is None or sos.patient_id != patient.user_id:
        raise AppException(
            "SOS_NOT_FOUND",
            "Cette alerte SOS est introuvable.",
            status_code=404,
        )

    await _finalize_sos_if_due(db, sos=sos)

    if sos.statut == "annule":
        return {"message": "Alerte SOS déjà annulée."}

    if sos.statut == "envoye":
        raise AppException(
            "SOS_TROP_TARD",
            "La fenêtre d'annulation est passée : l'alerte a déjà été envoyée.",
            status_code=409,
        )

    now = datetime.now(UTC)
    if now >= _aware(sos.annulable_jusqu_a):
        await _finalize_sos_if_due(db, sos=sos)
        raise AppException(
            "SOS_TROP_TARD",
            "La fenêtre d'annulation est passée : l'alerte a déjà été envoyée.",
            status_code=409,
        )

    sos.statut = "annule"
    sos.annule_at = now
    await db.commit()
    return {"message": "Alerte SOS annulée. Aucun contact n'a été prévenu."}


async def _finalize_sos_if_due(db: AsyncSession, *, sos: SosAlerte) -> None:
    if sos.statut != "en_attente":
        return
    now = datetime.now(UTC)
    if now < _aware(sos.annulable_jusqu_a):
        return

    contacts = (
        await db.execute(
            select(ContactUrgence).where(ContactUrgence.patient_id == sos.patient_id)
        )
    ).scalars().all()
    contacts_payload = [
        {"id": str(c.id), "nom": c.nom, "telephone": c.telephone, "relation": c.relation}
        for c in contacts
    ]
    await notification_service.trigger(
        db,
        type_alerte="sos_declenche",
        user_id=sos.patient_id,
        contexte={
            "sos_id": str(sos.id),
            "patient_id": str(sos.patient_id),
            "contacts": contacts_payload,
            "event": "sos_envoye",
        },
    )
    sos.statut = "envoye"
    sos.envoye_at = now
    await db.commit()

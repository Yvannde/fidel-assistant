"""Contacts d'urgence du patient (prérequis SOS)."""

from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.models import ContactUrgence, User
from app.services.onboarding_service import _require_patient


def _serialize(contact: ContactUrgence) -> dict:
    return {
        "id": contact.id,
        "nom": contact.nom,
        "telephone": contact.telephone,
        "relation": contact.relation,
    }


async def list_contacts(db: AsyncSession, *, user: User) -> list[dict]:
    patient = _require_patient(user)
    result = await db.execute(
        select(ContactUrgence)
        .where(ContactUrgence.patient_id == patient.user_id)
        .order_by(ContactUrgence.created_at.asc())
    )
    return [_serialize(c) for c in result.scalars().all()]


async def create_contact(
    db: AsyncSession,
    *,
    user: User,
    nom: str,
    telephone: str,
    relation: str,
) -> dict:
    patient = _require_patient(user)
    contact = ContactUrgence(
        patient_id=patient.user_id,
        nom=nom.strip(),
        telephone=telephone.strip(),
        relation=relation.strip(),
    )
    db.add(contact)
    await db.commit()
    await db.refresh(contact)
    return _serialize(contact)


async def delete_contact(db: AsyncSession, *, user: User, contact_id: UUID) -> dict:
    patient = _require_patient(user)
    result = await db.execute(
        select(ContactUrgence).where(
            ContactUrgence.id == contact_id,
            ContactUrgence.patient_id == patient.user_id,
        )
    )
    contact = result.scalar_one_or_none()
    if contact is None:
        raise AppException(
            "CONTACT_NOT_FOUND",
            "Ce contact d'urgence est introuvable.",
            status_code=404,
        )
    await db.delete(contact)
    await db.commit()
    return {"message": "Contact d'urgence supprimé."}

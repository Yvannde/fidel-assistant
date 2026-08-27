"""Logique métier onboarding (capacités) + sync aidant."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from secrets import randbelow
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import AppException
from app.models import (
    Maladie,
    Patient,
    PatientAidant,
    PatientTraitement,
    SyncCode,
    User,
)

VALID_PHASES = {"debut", "en_cours", "maintenance", "inconnu"}


def has_patient_profile(user: User) -> bool:
    return user.patient is not None


def is_aidant(user: User) -> bool:
    return any(
        r.statut == "actif" and r.revoked_at is None for r in (user.aidant_relations or [])
    )


def capabilities(user: User) -> dict:
    return {
        "has_patient_profile": has_patient_profile(user),
        "is_aidant": is_aidant(user),
    }


async def get_user_with_capabilities(db: AsyncSession, user_id: UUID) -> User | None:
    result = await db.execute(
        select(User)
        .where(User.id == user_id, User.deleted_at.is_(None))
        .options(
            selectinload(User.patient),
            selectinload(User.aidant_relations),
            selectinload(User.cgu_acceptances),
            selectinload(User.consentement_sante),
        )
    )
    return result.scalar_one_or_none()


def _require_patient(user: User) -> Patient:
    if user.patient is None:
        raise AppException(
            "NOT_A_PATIENT",
            "Active d'abord un suivi pour toi.",
            status_code=400,
        )
    return user.patient


def create_patient_from_user(user: User) -> Patient:
    return Patient(
        user_id=user.id,
        nom_complet=user.nom_complet,
        date_naissance=user.date_naissance,
        sexe=user.sexe,
        localisation=user.localisation,
        notifications_accordees=False,
        batterie_exemptee=False,
    )


async def status(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    return {
        "onboarding_step": refreshed.onboarding_step,
        **capabilities(refreshed),
    }


async def save_infos(
    db: AsyncSession,
    *,
    user: User,
    nom_complet: str,
    date_naissance: date,
    sexe: str,
    localisation: str,
    phone: str | None,
) -> dict:
    user.nom_complet = nom_complet.strip()
    user.date_naissance = date_naissance
    user.sexe = sexe.strip()
    user.localisation = localisation.strip()
    if phone is not None:
        user.phone = phone.strip() or None
    user.onboarding_step = "besoin_suivi"
    await db.commit()
    return {"onboarding_step": user.onboarding_step}


async def set_besoin_suivi(db: AsyncSession, *, user: User, actif: bool) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None

    if actif:
        if refreshed.patient is None:
            if not refreshed.nom_complet:
                raise AppException(
                    "ONBOARDING_INCOMPLETE",
                    "Renseigne d'abord tes informations personnelles.",
                    status_code=400,
                )
            patient = create_patient_from_user(refreshed)
            db.add(patient)
            refreshed.patient = patient
        refreshed.onboarding_step = "patient_traitement"
    else:
        refreshed.onboarding_step = "besoin_suivi"

    await db.commit()
    return {
        "onboarding_step": refreshed.onboarding_step,
        "has_patient_profile": refreshed.patient is not None,
    }


async def list_maladies(db: AsyncSession) -> list[Maladie]:
    result = await db.execute(
        select(Maladie).where(Maladie.actif.is_(True)).order_by(Maladie.nom)
    )
    return list(result.scalars().all())


async def save_traitement(
    db: AsyncSession,
    *,
    user: User,
    en_traitement: bool,
    traitements: list[dict] | None,
) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)

    if en_traitement:
        items = traitements or []
        if not items:
            raise AppException(
                "ONBOARDING_INCOMPLETE",
                "Ajoute au moins une maladie / phase de traitement.",
                status_code=400,
            )
        for item in items:
            phase = item["phase"]
            if phase not in VALID_PHASES:
                raise AppException(
                    "TYPE_INVALIDE",
                    "Phase de traitement invalide.",
                    status_code=400,
                )
            maladie = await db.get(Maladie, item["maladie_id"])
            if maladie is None or not maladie.actif:
                raise AppException("TYPE_INVALIDE", "Maladie inconnue.", status_code=400)
            db.add(
                PatientTraitement(
                    patient_id=patient.user_id,
                    maladie_id=item["maladie_id"],
                    phase=phase,
                    date_debut=item.get("date_debut"),
                )
            )
    refreshed.onboarding_step = "patient_permissions"
    await db.commit()
    return {"onboarding_step": refreshed.onboarding_step}


async def save_permissions(
    db: AsyncSession,
    *,
    user: User,
    notifications_accordees: bool,
    batterie_exemptee: bool,
) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)
    patient.notifications_accordees = notifications_accordees
    patient.batterie_exemptee = batterie_exemptee
    refreshed.onboarding_step = "patient_permissions"
    await db.commit()
    return {"onboarding_step": refreshed.onboarding_step}


async def complete(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    step = refreshed.onboarding_step

    if step in (None, "infos"):
        raise AppException(
            "ONBOARDING_INCOMPLETE",
            "Termine d'abord les informations personnelles.",
            status_code=400,
        )

    if has_patient_profile(refreshed):
        if step not in ("patient_permissions", "termine"):
            raise AppException(
                "ONBOARDING_INCOMPLETE",
                "Termine le parcours suivi (traitement + permissions).",
                status_code=400,
            )
    elif step not in ("besoin_suivi", "termine"):
        raise AppException(
            "ONBOARDING_INCOMPLETE",
            "Réponds d'abord à la question de suivi.",
            status_code=400,
        )

    refreshed.onboarding_step = "termine"
    await db.commit()
    return {"onboarding_step": "termine"}


async def activate_patient(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    if refreshed.patient is not None:
        raise AppException(
            "PATIENT_ALREADY_ACTIVE",
            "Ton suivi personnel est déjà actif.",
            status_code=409,
        )
    if not refreshed.nom_complet:
        raise AppException(
            "ONBOARDING_INCOMPLETE",
            "Renseigne d'abord tes informations (onboarding infos).",
            status_code=400,
        )
    db.add(create_patient_from_user(refreshed))
    await db.commit()
    return {"has_patient_profile": True, "onboarding_hint": "patient_traitement"}


async def create_sync_code(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)
    code = f"{randbelow(1_000_000):06d}"
    expires = datetime.now(UTC) + timedelta(minutes=settings.sync_code_expire_minutes)
    db.add(SyncCode(patient_id=patient.user_id, code=code, expires_at=expires))
    await db.commit()
    return {
        "code": code,
        "qr_payload": f"fidel://sync/{code}",
        "expires_at": expires,
    }


async def sync_aidant(db: AsyncSession, *, user: User, code: str) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None

    result = await db.execute(
        select(SyncCode)
        .where(SyncCode.code == code.strip(), SyncCode.used_at.is_(None))
        .options(selectinload(SyncCode.patient))
        .order_by(SyncCode.created_at.desc())
        .limit(1)
    )
    sync = result.scalar_one_or_none()
    if sync is None:
        raise AppException(
            "SYNC_CODE_INVALID",
            "Code de synchronisation invalide.",
            status_code=400,
        )

    expires = sync.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=UTC)
    if expires < datetime.now(UTC):
        raise AppException("SYNC_CODE_EXPIRED", "Ce code a expiré.", status_code=400)

    if sync.patient_id == refreshed.id:
        raise AppException(
            "SYNC_SELF_NOT_ALLOWED",
            "Tu ne peux pas te synchroniser avec toi-même.",
            status_code=400,
        )

    existing = await db.execute(
        select(PatientAidant).where(
            PatientAidant.patient_id == sync.patient_id,
            PatientAidant.aidant_id == refreshed.id,
            PatientAidant.statut == "actif",
            PatientAidant.revoked_at.is_(None),
        )
    )
    if existing.scalar_one_or_none() is None:
        db.add(
            PatientAidant(
                patient_id=sync.patient_id,
                aidant_id=refreshed.id,
                statut="actif",
                niveau_permission={"observance": True, "constantes": False},
            )
        )

    sync.used_at = datetime.now(UTC)
    await db.commit()

    prenom = (sync.patient.nom_complet or "Patient").split()[0]
    return {
        "patient_id": sync.patient_id,
        "patient_prenom": prenom,
        "is_aidant": True,
    }


async def get_patient_me(db: AsyncSession, *, user: User) -> dict:
    refreshed = await get_user_with_capabilities(db, user.id)
    assert refreshed is not None
    patient = _require_patient(refreshed)
    return {
        "user_id": patient.user_id,
        "nom_complet": patient.nom_complet,
        "date_naissance": patient.date_naissance,
        "sexe": patient.sexe,
        "localisation": patient.localisation,
        "photo_url": patient.photo_url,
        "notifications_accordees": patient.notifications_accordees,
        "batterie_exemptee": patient.batterie_exemptee,
    }


DEFAULT_MALADIES = [
    ("Tuberculose", "Traitement antituberculeux"),
    ("Diabète", "Suivi glycémique et traitement"),
    ("Hypertension", "Suivi tensionnel"),
    ("VIH", "Traitement antirétroviral"),
    ("Autre", "Autre pathologie chronique"),
]


async def ensure_default_maladies(db: AsyncSession) -> None:
    result = await db.execute(select(Maladie).limit(1))
    if result.scalar_one_or_none() is not None:
        return
    for nom, description in DEFAULT_MALADIES:
        db.add(Maladie(nom=nom, description=description, actif=True))
    await db.commit()

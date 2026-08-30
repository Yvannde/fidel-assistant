"""Saisie et analyse simple des constantes de santé (Volet 2)."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.models import Constante, User
from app.services import notification_service
from app.services.aidant_service import assert_aidant_permission
from app.services.onboarding_service import _require_patient

VALID_TYPES = frozenset(
    {"poids", "tension", "temperature", "glycemie", "humeur", "sommeil"}
)
VALID_SOURCES = frozenset({"manuel", "objet_connecte"})

# Types où une baisse est plutôt une bonne nouvelle
_BAISSE_POSITIVE = frozenset({"tension", "glycemie", "temperature"})
# Types où une hausse est plutôt une bonne nouvelle
_HAUSSE_POSITIVE = frozenset({"poids", "sommeil", "humeur"})

_STABLE_EPS = {
    "poids": 0.3,
    "temperature": 0.2,
    "glycemie": 0.1,
    "sommeil": 0.3,
    "humeur": 0.5,
    "tension": 5.0,
}


def _normalize_valeur(type_: str, valeur: float | str | dict[str, Any]) -> dict:
    if type_ == "tension":
        if isinstance(valeur, dict):
            sys_v = valeur.get("systolique")
            dia_v = valeur.get("diastolique")
            if sys_v is None or dia_v is None:
                raise AppException(
                    "TYPE_INVALIDE",
                    "Pour la tension, indique systolique et diastolique.",
                    status_code=400,
                )
            return {"systolique": float(sys_v), "diastolique": float(dia_v)}
        if isinstance(valeur, str) and "/" in valeur:
            left, right = valeur.split("/", 1)
            return {"systolique": float(left.strip()), "diastolique": float(right.strip())}
        raise AppException(
            "TYPE_INVALIDE",
            "Format tension attendu : « 120/80 » ou {systolique, diastolique}.",
            status_code=400,
        )
    if isinstance(valeur, dict) and "v" in valeur:
        return {"v": float(valeur["v"])}
    if isinstance(valeur, (int, float)):
        return {"v": float(valeur)}
    if isinstance(valeur, str):
        try:
            return {"v": float(valeur.replace(",", "."))}
        except ValueError as exc:
            raise AppException(
                "TYPE_INVALIDE",
                "Valeur numérique attendue pour ce type de constante.",
                status_code=400,
            ) from exc
    raise AppException("TYPE_INVALIDE", "Valeur de constante invalide.", status_code=400)


def _public_valeur(type_: str, stored: dict) -> float | str | dict[str, Any]:
    if type_ == "tension":
        return f"{int(stored['systolique'])}/{int(stored['diastolique'])}"
    return stored.get("v")


def _comparable(type_: str, stored: dict) -> float:
    if type_ == "tension":
        return float(stored["systolique"])
    return float(stored["v"])


def _analyze(type_: str, current: dict, previous: dict | None) -> tuple[str, str]:
    if previous is None:
        return "insuffisant", "Première mesure enregistrée. Continue comme ça, on suivra ensemble."

    cur = _comparable(type_, current)
    prev = _comparable(type_, previous)
    eps = _STABLE_EPS.get(type_, 0.5)
    delta = cur - prev

    if abs(delta) <= eps:
        return "stable", "Ta mesure est stable par rapport à la précédente. C'est bien."

    hausse = delta > 0
    if type_ in _BAISSE_POSITIVE:
        if not hausse:
            return (
                "amelioration",
                f"On remarque une baisse ({prev:g} → {cur:g}). C'est encourageant, continue.",
            )
        return (
            "degradation",
            f"On observe une hausse ({prev:g} → {cur:g}). Ce n'est pas forcément grave, "
            "surveille et parles-en si ça continue.",
        )
    if type_ in _HAUSSE_POSITIVE:
        if hausse:
            return (
                "amelioration",
                f"On remarque une hausse ({prev:g} → {cur:g}). C'est bon signe, continue.",
            )
        return (
            "degradation",
            f"On observe une baisse ({prev:g} → {cur:g}). Ce n'est pas forcément grave, "
            "surveille et parles-en si ça continue.",
        )
    # défaut
    if hausse:
        return "stable", f"Mesure mise à jour ({prev:g} → {cur:g})."
    return "stable", f"Mesure mise à jour ({prev:g} → {cur:g})."


def _serialize(row: Constante) -> dict:
    return {
        "id": row.id,
        "type": row.type,
        "valeur": _public_valeur(row.type, row.valeur),
        "unite": row.unite,
        "mesure_at": row.mesure_at,
        "source": row.source,
    }


async def list_constantes(
    db: AsyncSession,
    *,
    user: User,
    type_: str | None = None,
    depuis: datetime | None = None,
    jusqu_a: datetime | None = None,
) -> list[dict]:
    patient = _require_patient(user)
    return await _list_for_patient(
        db,
        patient_id=patient.user_id,
        type_=type_,
        depuis=depuis,
        jusqu_a=jusqu_a,
    )


async def create_constante(
    db: AsyncSession,
    *,
    user: User,
    type_: str,
    valeur: float | str | dict[str, Any],
    unite: str,
    mesure_at: datetime,
    source: str,
) -> dict:
    patient = _require_patient(user)
    type_norm = type_.strip().lower()
    if type_norm not in VALID_TYPES:
        raise AppException(
            "TYPE_INVALIDE",
            "Type de constante inconnu. Choisis poids, tension, température, "
            "glycémie, humeur ou sommeil.",
            status_code=400,
        )
    if source not in VALID_SOURCES:
        raise AppException(
            "TYPE_INVALIDE",
            "Source invalide. Utilise « manuel » ou « objet_connecte ».",
            status_code=400,
        )

    stored = _normalize_valeur(type_norm, valeur)
    mesure = mesure_at if mesure_at.tzinfo else mesure_at.replace(tzinfo=UTC)

    prev_result = await db.execute(
        select(Constante)
        .where(Constante.patient_id == patient.user_id, Constante.type == type_norm)
        .order_by(Constante.mesure_at.desc())
        .limit(1)
    )
    previous = prev_result.scalar_one_or_none()

    row = Constante(
        patient_id=patient.user_id,
        type=type_norm,
        valeur=stored,
        unite=unite.strip(),
        mesure_at=mesure,
        source=source,
    )
    db.add(row)
    await db.flush()

    tendance, message = _analyze(type_norm, stored, previous.valeur if previous else None)

    if tendance == "amelioration":
        await notification_service.trigger(
            db,
            type_alerte="constante_amelioration",
            user_id=patient.user_id,
            contexte={"constante_id": str(row.id), "type": type_norm, "tendance": tendance},
            contenu=message,
        )
    elif tendance == "degradation":
        await notification_service.trigger(
            db,
            type_alerte="constante_degradation",
            user_id=patient.user_id,
            contexte={"constante_id": str(row.id), "type": type_norm, "tendance": tendance},
            contenu=message,
        )

    await db.commit()
    await db.refresh(row)
    return {
        "constante": _serialize(row),
        "tendance": tendance,
        "message": message,
    }


async def list_aidant_constantes(
    db: AsyncSession,
    *,
    user: User,
    patient_id: UUID,
    type_: str | None = None,
    depuis: datetime | None = None,
    jusqu_a: datetime | None = None,
) -> list[dict]:
    await assert_aidant_permission(
        db, user=user, patient_id=patient_id, permission="constantes"
    )
    return await _list_for_patient(
        db,
        patient_id=patient_id,
        type_=type_,
        depuis=depuis,
        jusqu_a=jusqu_a,
    )


async def _list_for_patient(
    db: AsyncSession,
    *,
    patient_id: UUID,
    type_: str | None,
    depuis: datetime | None,
    jusqu_a: datetime | None,
) -> list[dict]:
    stmt = select(Constante).where(Constante.patient_id == patient_id)
    if type_:
        stmt = stmt.where(Constante.type == type_.strip().lower())
    if depuis is not None:
        d = depuis if depuis.tzinfo else depuis.replace(tzinfo=UTC)
        stmt = stmt.where(Constante.mesure_at >= d)
    if jusqu_a is not None:
        u = jusqu_a if jusqu_a.tzinfo else jusqu_a.replace(tzinfo=UTC)
        stmt = stmt.where(Constante.mesure_at <= u)
    stmt = stmt.order_by(Constante.mesure_at.desc())
    result = await db.execute(stmt)
    return [_serialize(r) for r in result.scalars().all()]

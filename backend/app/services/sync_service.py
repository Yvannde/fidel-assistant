"""Sync V2 — push / pull (Phase 4)."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import AppException
from app.models import (
    Medicament,
    MedicamentHoraire,
    PatientTraitement,
    Prise,
    User,
)
from app.services import patient_suivi_service as suivi


def _cursor_for_prise(prise: Prise) -> str:
    ts = prise.updated_at.astimezone(UTC).isoformat()
    return f"{ts}|{prise.id}"


def _parse_cursor(since: str | None) -> tuple[datetime | None, UUID | None]:
    if not since:
        return None, None
    try:
        ts_raw, id_raw = since.rsplit("|", 1)
        return datetime.fromisoformat(ts_raw), UUID(id_raw)
    except (ValueError, TypeError):
        return None, None


async def push_mutations(
    db: AsyncSession, *, user: User, mutations: list[dict]
) -> dict:
    results: list[dict] = []
    for raw in mutations:
        mutation_id = raw["mutation_id"]
        entity = raw.get("entity") or ""
        op = raw.get("op") or ""
        entity_id = raw.get("entity_id")
        payload = raw.get("payload") or {}

        existing = await suivi._get_client_mutation(db, mutation_id=mutation_id)
        if existing is not None:
            results.append(
                {
                    "mutation_id": mutation_id,
                    "status": "duplicate",
                    "reason": None,
                }
            )
            continue

        if entity != "prise" or entity_id is None:
            results.append(
                {
                    "mutation_id": mutation_id,
                    "status": "rejected",
                    "reason": "MUTATION_REJECTED",
                }
            )
            continue

        try:
            if op == "confirm":
                await suivi.confirmer_prise(
                    db,
                    user=user,
                    prise_id=entity_id,
                    canal=str(payload.get("canal") or "app"),
                    client_mutation_id=mutation_id,
                )
                results.append(
                    {
                        "mutation_id": mutation_id,
                        "status": "applied",
                        "reason": None,
                    }
                )
            elif op == "report":
                raw_heure = payload.get("nouvelle_heure")
                if not raw_heure:
                    results.append(
                        {
                            "mutation_id": mutation_id,
                            "status": "rejected",
                            "reason": "MUTATION_REJECTED",
                        }
                    )
                    continue
                when = (
                    datetime.fromisoformat(str(raw_heure))
                    if not isinstance(raw_heure, datetime)
                    else raw_heure
                )
                await suivi.reporter_prise(
                    db,
                    user=user,
                    prise_id=entity_id,
                    nouvelle_heure=when,
                    client_mutation_id=mutation_id,
                )
                results.append(
                    {
                        "mutation_id": mutation_id,
                        "status": "applied",
                        "reason": None,
                    }
                )
            else:
                results.append(
                    {
                        "mutation_id": mutation_id,
                        "status": "rejected",
                        "reason": "MUTATION_REJECTED",
                    }
                )
        except AppException as exc:
            reason = exc.code
            if exc.code == "PRISE_DEJA_CONFIRMEE":
                reason = "SYNC_CONFLICT"
            results.append(
                {
                    "mutation_id": mutation_id,
                    "status": "rejected",
                    "reason": reason,
                }
            )
        except Exception:
            results.append(
                {
                    "mutation_id": mutation_id,
                    "status": "rejected",
                    "reason": "MUTATION_REJECTED",
                }
            )

    return {"results": results}


async def pull_delta(
    db: AsyncSession, *, user: User, since: str | None = None
) -> dict:
    patient = suivi._require_patient(user)
    since_ts, since_id = _parse_cursor(since)
    now = datetime.now(UTC)
    horizon_start = now - timedelta(days=1)
    horizon_end = now + timedelta(days=7)

    prise_q = (
        select(Prise, Medicament)
        .join(MedicamentHoraire, Prise.medicament_horaire_id == MedicamentHoraire.id)
        .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(
            PatientTraitement.patient_id == patient.user_id,
            Prise.heure_prevue >= horizon_start,
            Prise.heure_prevue <= horizon_end,
        )
    )
    if since_ts is not None and since_id is not None:
        prise_q = prise_q.where(
            or_(
                Prise.updated_at > since_ts,
                and_(Prise.updated_at == since_ts, Prise.id > since_id),
            )
        )
    prise_q = prise_q.order_by(Prise.updated_at.asc(), Prise.id.asc())

    entities: list[dict] = []
    last_cursor: str | None = None
    result = await db.execute(prise_q)
    for prise, med in result.all():
        entities.append(
            {
                "type": "prise",
                "id": str(prise.id),
                "server_version": int(prise.server_version or 1),
                "updated_at": prise.updated_at.astimezone(UTC).isoformat(),
                "medicament_id": str(med.id),
                "medicament_nom": med.nom,
                "dosage": med.dosage,
                "heure_prevue": prise.heure_prevue.astimezone(UTC).isoformat(),
                "statut": prise.statut,
                "confirmee_at": (
                    prise.confirmee_at.astimezone(UTC).isoformat()
                    if prise.confirmee_at
                    else None
                ),
                "canal": prise.canal,
            }
        )
        last_cursor = _cursor_for_prise(prise)

    # Traitements actifs (miroir) — inclus si since absent ou toujours (léger)
    if since is None:
        tr_result = await db.execute(
            select(PatientTraitement)
            .where(
                PatientTraitement.patient_id == patient.user_id,
                PatientTraitement.statut == "actif",
            )
            .options(
                selectinload(PatientTraitement.maladie),
                selectinload(PatientTraitement.medicaments),
            )
        )
        for t in tr_result.scalars().all():
            entities.append(
                {
                    "type": "traitement",
                    "id": str(t.id),
                    "server_version": 1,
                    "updated_at": (
                        t.updated_at.astimezone(UTC).isoformat()
                        if getattr(t, "updated_at", None)
                        else now.isoformat()
                    ),
                    "payload": {
                        "id": str(t.id),
                        "date_debut": t.date_debut.isoformat() if t.date_debut else None,
                        "date_fin_prevue": (
                            t.date_fin_prevue.isoformat() if t.date_fin_prevue else None
                        ),
                        "jour_traitement": getattr(t, "jour_traitement", None),
                    },
                }
            )

    return {
        "entities": entities,
        "next_cursor": last_cursor if since is not None else last_cursor,
        "server_time": now,
    }

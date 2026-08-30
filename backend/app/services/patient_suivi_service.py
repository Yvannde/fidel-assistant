"""Dashboard home, médicaments, horaires et prises."""

from __future__ import annotations

from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import AppException
from app.models import (
    Maladie,
    Medicament,
    MedicamentHoraire,
    PatientTraitement,
    PatientTraitementAttribut,
    Prise,
    ProtocoleMedicamentSuggere,
    ProtocoleTraitement,
    User,
)
from app.services.onboarding_service import VALID_PHASES, _require_patient

PRISE_HORIZON_DAYS = 30

_JOURS_FR = {
    0: "lundi",
    1: "mardi",
    2: "mercredi",
    3: "jeudi",
    4: "vendredi",
    5: "samedi",
    6: "dimanche",
}


def _patient_tz(user: User) -> ZoneInfo:
    try:
        return ZoneInfo(user.fuseau_horaire or "UTC")
    except Exception:
        return ZoneInfo("UTC")


def _jour_traitement(date_debut: date | None, today: date) -> int | None:
    if date_debut is None:
        return None
    delta = (today - date_debut).days
    return max(delta + 1, 1)


def _jours_match(jours: list, weekday: int) -> bool:
    if not jours or "tous" in jours:
        return True
    nom = _JOURS_FR.get(weekday)
    return nom in jours or str(weekday) in jours


def _combine_local(d: date, t: time, tz: ZoneInfo) -> datetime:
    local = datetime(d.year, d.month, d.day, t.hour, t.minute, t.second, tzinfo=tz)
    return local.astimezone(UTC)


async def _traitement_for_patient(
    db: AsyncSession, *, patient_id: UUID, traitement_id: UUID
) -> PatientTraitement:
    result = await db.execute(
        select(PatientTraitement)
        .where(
            PatientTraitement.id == traitement_id,
            PatientTraitement.patient_id == patient_id,
            PatientTraitement.statut == "actif",
        )
        .options(
            selectinload(PatientTraitement.maladie),
            selectinload(PatientTraitement.medicaments).selectinload(Medicament.horaires),
        )
    )
    traitement = result.scalar_one_or_none()
    if traitement is None:
        raise AppException(
            "TRAITEMENT_NOT_FOUND",
            "Ce traitement est introuvable.",
            status_code=404,
        )
    return traitement


async def _medicament_for_patient(
    db: AsyncSession, *, patient_id: UUID, medicament_id: UUID
) -> Medicament:
    result = await db.execute(
        select(Medicament)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(
            Medicament.id == medicament_id,
            PatientTraitement.patient_id == patient_id,
        )
        .options(selectinload(Medicament.horaires))
    )
    med = result.scalar_one_or_none()
    if med is None:
        raise AppException(
            "MEDICAMENT_NOT_FOUND",
            "Ce médicament est introuvable.",
            status_code=404,
        )
    return med


async def _load_suggestions(
    db: AsyncSession, traitement: PatientTraitement
) -> list[dict]:
    protocole_id = traitement.protocole_id
    if protocole_id is None:
        proto_result = await db.execute(
            select(ProtocoleTraitement)
            .where(
                ProtocoleTraitement.maladie_id == traitement.maladie_id,
                ProtocoleTraitement.actif.is_(True),
            )
            .order_by(ProtocoleTraitement.ordre)
            .limit(1)
        )
        proto = proto_result.scalar_one_or_none()
        protocole_id = proto.id if proto else None

    if protocole_id is None:
        return []

    med_result = await db.execute(
        select(ProtocoleMedicamentSuggere)
        .where(
            ProtocoleMedicamentSuggere.protocole_id == protocole_id,
            ProtocoleMedicamentSuggere.actif.is_(True),
        )
        .order_by(ProtocoleMedicamentSuggere.ordre)
    )
    return [
        {
            "nom": m.nom,
            "dosage": m.dosage,
            "forme": m.forme,
            "prise_avec_repas": m.prise_avec_repas,
            "horaires_suggestion": m.horaires_suggestion or [],
        }
        for m in med_result.scalars().all()
    ]


def _traitement_has_medicaments(traitement: PatientTraitement) -> bool:
    return any(
        m.actif and any(h.actif for h in (m.horaires or [])) for m in (traitement.medicaments or [])
    )


def _serialize_traitement(traitement: PatientTraitement, today: date) -> dict:
    maladie = traitement.maladie
    return {
        "id": traitement.id,
        "maladie_id": traitement.maladie_id,
        "maladie_code": maladie.code if maladie else "",
        "maladie_nom": maladie.nom if maladie else "",
        "phase": traitement.phase,
        "en_traitement": traitement.en_traitement,
        "date_debut": traitement.date_debut,
        "date_fin_prevue": traitement.date_fin_prevue,
        "protocole_id": traitement.protocole_id,
        "lieu_suivi": traitement.lieu_suivi,
        "statut": traitement.statut,
        "jour_traitement": _jour_traitement(traitement.date_debut, today),
        "medicaments_count": sum(1 for m in (traitement.medicaments or []) if m.actif),
    }


def _serialize_medicament(med: Medicament) -> dict:
    return {
        "id": med.id,
        "patient_traitement_id": med.patient_traitement_id,
        "nom": med.nom,
        "dosage": med.dosage,
        "forme": med.forme,
        "prise_avec_repas": med.prise_avec_repas,
        "instructions": med.instructions,
        "stock_restant": med.stock_restant,
        "seuil_alerte_stock": med.seuil_alerte_stock,
        "actif": med.actif,
        "horaires": [
            {
                "id": h.id,
                "heure": h.heure,
                "jours": h.jours or ["tous"],
                "actif": h.actif,
            }
            for h in (med.horaires or [])
        ],
    }


async def get_dashboard(db: AsyncSession, *, user: User) -> dict:
    patient = _require_patient(user)
    tz = _patient_tz(user)
    today = datetime.now(tz).date()

    result = await db.execute(
        select(PatientTraitement)
        .where(
            PatientTraitement.patient_id == patient.user_id,
            PatientTraitement.statut == "actif",
        )
        .options(
            selectinload(PatientTraitement.maladie),
            selectinload(PatientTraitement.medicaments).selectinload(Medicament.horaires),
        )
    )
    traitements = list(result.scalars().all())

    medicaments_configures = any(_traitement_has_medicaments(t) for t in traitements)

    if not patient.notifications_accordees:
        prochaine_action = "activer_notifications"
    elif traitements and not medicaments_configures:
        prochaine_action = "configurer_medicaments"
    else:
        prochaine_action = "aucune"

    dashboard_traitements = []
    for t in traitements:
        configured = _traitement_has_medicaments(t)
        suggestions = []
        if not configured:
            suggestions = await _load_suggestions(db, t)
        dashboard_traitements.append(
            {
                "id": t.id,
                "maladie_code": t.maladie.code if t.maladie else "",
                "maladie_nom": t.maladie.nom if t.maladie else "",
                "phase": t.phase,
                "date_debut": t.date_debut,
                "jour_traitement": _jour_traitement(t.date_debut, today),
                "medicaments_configures": configured,
                "suggestions_medicaments": suggestions,
            }
        )

    prises = await list_prises(db, user=user, target_date=today)
    return {
        "prochaine_action": prochaine_action,
        "medicaments_configures": medicaments_configures,
        "notifications_accordees": patient.notifications_accordees,
        "traitements": dashboard_traitements,
        "prises_aujourdhui": prises,
    }


async def list_traitements(db: AsyncSession, *, user: User) -> list[dict]:
    patient = _require_patient(user)
    tz = _patient_tz(user)
    today = datetime.now(tz).date()

    result = await db.execute(
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
    return [_serialize_traitement(t, today) for t in result.scalars().all()]


async def create_traitement(db: AsyncSession, *, user: User, data: dict) -> dict:
    patient = _require_patient(user)
    phase = data["phase"]
    if phase not in VALID_PHASES:
        raise AppException("TYPE_INVALIDE", "Phase de traitement invalide.", status_code=400)

    maladie = await db.get(Maladie, data["maladie_id"])
    if maladie is None or not maladie.actif:
        raise AppException("TYPE_INVALIDE", "Maladie invalide.", status_code=400)

    traitement = PatientTraitement(
        patient_id=patient.user_id,
        maladie_id=data["maladie_id"],
        protocole_id=data.get("protocole_id"),
        phase=phase,
        en_traitement=True,
        date_debut=data.get("date_debut"),
        date_fin_prevue=data.get("date_fin_prevue"),
        maladie_libelle=data.get("maladie_libelle"),
        lieu_suivi=data.get("lieu_suivi"),
        statut="actif",
    )
    db.add(traitement)
    await db.flush()

    attributs = data.get("attributs") or {}
    for code, val in attributs.items():
        db.add(
            PatientTraitementAttribut(
                patient_traitement_id=traitement.id,
                code=str(code),
                valeur={"value": val},
            )
        )

    await db.commit()
    await db.refresh(traitement, attribute_names=["maladie", "medicaments"])
    today = datetime.now(_patient_tz(user)).date()
    return _serialize_traitement(traitement, today)


async def create_medicament(
    db: AsyncSession,
    *,
    user: User,
    traitement_id: UUID,
    data: dict,
) -> dict:
    traitement = await _traitement_for_patient(
        db, patient_id=_require_patient(user).user_id, traitement_id=traitement_id
    )
    tz = _patient_tz(user)

    med = Medicament(
        patient_traitement_id=traitement.id,
        nom=data["nom"].strip(),
        dosage=data["dosage"].strip(),
        forme=data.get("forme") or "comprime",
        prise_avec_repas=data.get("prise_avec_repas"),
        instructions=data.get("instructions"),
        stock_restant=data.get("stock_restant"),
        seuil_alerte_stock=data.get("seuil_alerte_stock"),
        actif=True,
    )
    db.add(med)
    await db.flush()

    horaires_created: list[MedicamentHoraire] = []
    for item in data["horaires"]:
        h = MedicamentHoraire(
            medicament_id=med.id,
            heure=item["heure"],
            jours=item.get("jours") or ["tous"],
            actif=True,
        )
        db.add(h)
        horaires_created.append(h)

    await db.flush()
    today = datetime.now(tz).date()
    for h in horaires_created:
        await _ensure_prises_for_horaire(
            db,
            horaire=h,
            tz=tz,
            start_date=today,
            end_date=today + timedelta(days=PRISE_HORIZON_DAYS),
        )

    await db.commit()
    med = await _medicament_for_patient(db, patient_id=traitement.patient_id, medicament_id=med.id)
    return _serialize_medicament(med)


async def list_medicaments(db: AsyncSession, *, user: User) -> list[dict]:
    patient = _require_patient(user)
    result = await db.execute(
        select(Medicament)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(PatientTraitement.patient_id == patient.user_id, Medicament.actif.is_(True))
        .options(selectinload(Medicament.horaires))
        .order_by(Medicament.nom)
    )
    return [_serialize_medicament(m) for m in result.scalars().all()]


async def update_medicament(
    db: AsyncSession, *, user: User, medicament_id: UUID, data: dict
) -> dict:
    med = await _medicament_for_patient(
        db, patient_id=_require_patient(user).user_id, medicament_id=medicament_id
    )
    for field in ("nom", "dosage", "forme", "prise_avec_repas", "instructions", "actif"):
        if field in data and data[field] is not None:
            setattr(med, field, data[field])
    await db.commit()
    med = await _medicament_for_patient(
        db, patient_id=_require_patient(user).user_id, medicament_id=medicament_id
    )
    return _serialize_medicament(med)


async def update_stock(
    db: AsyncSession, *, user: User, medicament_id: UUID, stock_restant: int
) -> dict:
    med = await _medicament_for_patient(
        db, patient_id=_require_patient(user).user_id, medicament_id=medicament_id
    )
    med.stock_restant = stock_restant
    alerte = (
        med.seuil_alerte_stock is not None and stock_restant <= med.seuil_alerte_stock
    )
    await db.commit()
    return {"stock_restant": stock_restant, "alerte_declenchee": alerte}


async def add_horaire(
    db: AsyncSession, *, user: User, medicament_id: UUID, heure: time, jours: list[str]
) -> dict:
    med = await _medicament_for_patient(
        db, patient_id=_require_patient(user).user_id, medicament_id=medicament_id
    )
    tz = _patient_tz(user)
    h = MedicamentHoraire(
        medicament_id=med.id,
        heure=heure,
        jours=jours or ["tous"],
        actif=True,
    )
    db.add(h)
    await db.flush()
    today = datetime.now(tz).date()
    await _ensure_prises_for_horaire(
        db, horaire=h, tz=tz, start_date=today, end_date=today + timedelta(days=PRISE_HORIZON_DAYS)
    )
    await db.commit()
    return {
        "id": h.id,
        "heure": h.heure,
        "jours": h.jours,
        "actif": h.actif,
    }


async def deactivate_horaire(
    db: AsyncSession, *, user: User, horaire_id: UUID
) -> dict:
    patient = _require_patient(user)
    result = await db.execute(
        select(MedicamentHoraire)
        .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(
            MedicamentHoraire.id == horaire_id,
            PatientTraitement.patient_id == patient.user_id,
        )
    )
    horaire = result.scalar_one_or_none()
    if horaire is None:
        raise AppException("HORAIRE_NOT_FOUND", "Horaire introuvable.", status_code=404)
    horaire.actif = False
    await db.commit()
    return {"message": "Horaire désactivé."}


async def _ensure_prises_for_horaire(
    db: AsyncSession,
    *,
    horaire: MedicamentHoraire,
    tz: ZoneInfo,
    start_date: date,
    end_date: date,
) -> None:
    if not horaire.actif:
        return

    existing = await db.execute(
        select(Prise.heure_prevue).where(
            Prise.medicament_horaire_id == horaire.id,
            Prise.heure_prevue >= _combine_local(start_date, time.min, tz),
            Prise.heure_prevue <= _combine_local(end_date, time(23, 59, 59), tz),
        )
    )
    existing_set = {row[0] for row in existing.all()}

    current = start_date
    while current <= end_date:
        if _jours_match(horaire.jours or ["tous"], current.weekday()):
            heure_prevue = _combine_local(current, horaire.heure, tz)
            if heure_prevue not in existing_set:
                db.add(
                    Prise(
                        medicament_horaire_id=horaire.id,
                        heure_prevue=heure_prevue,
                        statut="en_attente",
                    )
                )
        current += timedelta(days=1)


async def list_prises(
    db: AsyncSession, *, user: User, target_date: date | None = None
) -> list[dict]:
    patient = _require_patient(user)
    tz = _patient_tz(user)
    day = target_date or datetime.now(tz).date()

    horaires_result = await db.execute(
        select(MedicamentHoraire)
        .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(
            PatientTraitement.patient_id == patient.user_id,
            Medicament.actif.is_(True),
            MedicamentHoraire.actif.is_(True),
        )
    )
    for horaire in horaires_result.scalars().all():
        await _ensure_prises_for_horaire(db, horaire=horaire, tz=tz, start_date=day, end_date=day)
    await db.flush()

    day_start = _combine_local(day, time.min, tz)
    day_end = _combine_local(day, time(23, 59, 59), tz)

    result = await db.execute(
        select(Prise, Medicament)
        .join(MedicamentHoraire, Prise.medicament_horaire_id == MedicamentHoraire.id)
        .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(
            PatientTraitement.patient_id == patient.user_id,
            Prise.heure_prevue >= day_start,
            Prise.heure_prevue <= day_end,
        )
        .order_by(Prise.heure_prevue)
    )
    rows = []
    for prise, med in result.all():
        rows.append(
            {
                "id": prise.id,
                "medicament_id": med.id,
                "medicament_nom": med.nom,
                "dosage": med.dosage,
                "heure_prevue": prise.heure_prevue,
                "statut": prise.statut,
                "confirmee_at": prise.confirmee_at,
                "canal": prise.canal,
            }
        )
    await db.commit()
    return rows


async def _prise_for_patient(db: AsyncSession, *, patient_id: UUID, prise_id: UUID) -> Prise:
    result = await db.execute(
        select(Prise)
        .join(MedicamentHoraire, Prise.medicament_horaire_id == MedicamentHoraire.id)
        .join(Medicament, MedicamentHoraire.medicament_id == Medicament.id)
        .join(PatientTraitement, Medicament.patient_traitement_id == PatientTraitement.id)
        .where(Prise.id == prise_id, PatientTraitement.patient_id == patient_id)
    )
    prise = result.scalar_one_or_none()
    if prise is None:
        raise AppException("PRISE_NOT_FOUND", "Prise introuvable.", status_code=404)
    return prise


async def confirmer_prise(
    db: AsyncSession, *, user: User, prise_id: UUID, canal: str
) -> dict:
    patient = _require_patient(user)
    prise = await _prise_for_patient(db, patient_id=patient.user_id, prise_id=prise_id)
    if prise.statut == "confirmee":
        raise AppException(
            "PRISE_DEJA_CONFIRMEE",
            "Cette prise est déjà confirmée.",
            status_code=409,
        )
    prise.statut = "confirmee"
    prise.confirmee_at = datetime.now(UTC)
    prise.canal = canal
    await db.commit()
    return {
        "id": prise.id,
        "statut": prise.statut,
        "confirmee_at": prise.confirmee_at,
        "canal": prise.canal,
    }


async def reporter_prise(
    db: AsyncSession, *, user: User, prise_id: UUID, nouvelle_heure: datetime
) -> dict:
    patient = _require_patient(user)
    prise = await _prise_for_patient(db, patient_id=patient.user_id, prise_id=prise_id)
    prise.heure_prevue = nouvelle_heure.astimezone(UTC)
    prise.statut = "en_attente"
    prise.confirmee_at = None
    await db.commit()
    return {"id": prise.id, "heure_prevue": prise.heure_prevue, "statut": prise.statut}


async def sync_prises_offline(
    db: AsyncSession, *, user: User, items: list[dict]
) -> dict:
    patient = _require_patient(user)
    synced: list[UUID] = []
    conflicts: list[UUID] = []

    for item in items:
        prise_id = item["id"]
        try:
            prise = await _prise_for_patient(db, patient_id=patient.user_id, prise_id=prise_id)
        except AppException:
            conflicts.append(prise_id)
            continue

        incoming_statut = item["statut"]
        if prise.statut == "confirmee" and incoming_statut != "confirmee":
            conflicts.append(prise_id)
            continue

        prise.statut = incoming_statut
        if incoming_statut == "confirmee":
            prise.confirmee_at = item.get("confirmee_at") or datetime.now(UTC)
            prise.canal = prise.canal or "app"
        synced.append(prise_id)

    await db.commit()
    return {"synced": synced, "conflicts": conflicts}

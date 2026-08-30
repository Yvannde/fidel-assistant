"""Moteur de notification centralisé (Volet 7 — engagement-principle)."""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppException
from app.models import NotificationLog, PreferenceConsentement, User

# Types connus V1 — proposition=True = attend une réponse oui/non/reporter par défaut
ALERT_REGISTRY: dict[str, dict] = {
    "rappel_medicament": {"proposition": False},
    "stock_medicament_bas": {"proposition": True},
    "constante_amelioration": {"proposition": False},
    "constante_degradation": {"proposition": True},
    "checkin_absence": {"proposition": True},
    "sos_declenche": {"proposition": False},
    "education_contextuelle": {"proposition": False},
    "depistage_recommande": {"proposition": True},
    "aidant_sync": {"proposition": False},
}

VALID_REPONSES = frozenset({"oui", "non", "reporter"})


async def trigger(
    db: AsyncSession,
    *,
    type_alerte: str,
    user_id: UUID,
    contexte: dict,
    contenu: str | None = None,
    tiers_potentiel: UUID | None = None,
    force_proposition: bool | None = None,
) -> NotificationLog:
    """Point d'entrée unique pour journaliser une alerte produit."""
    pref = await _get_preference(db, user_id=user_id, type_alerte=type_alerte)
    registry = ALERT_REGISTRY.get(type_alerte, {"proposition": False})

    # Défaut produit : toujours demander (jamais d'action auto sans opt-in)
    toujours_demander = True if pref is None else pref.toujours_demander
    regle_auto = pref.regle_auto if pref else None

    wants_proposition = (
        force_proposition
        if force_proposition is not None
        else bool(registry.get("proposition"))
    )

    action_auto = False
    if (
        not toujours_demander
        and regle_auto
        and _regle_auto_applicable(regle_auto, contexte)
        and tiers_potentiel is not None
    ):
        action_auto = True
        wants_proposition = False

    message = contenu or _default_contenu(type_alerte, contexte)
    if wants_proposition and "veux-tu" not in message.lower():
        message = f"{message} Veux-tu qu'on prévienne ton aidant ?"

    log = NotificationLog(
        destinataire_id=user_id,
        type=type_alerte,
        contenu=message,
        declencheur={"type_alerte": type_alerte, **contexte},
        proposition=wants_proposition,
        tiers_potentiel_id=tiers_potentiel,
        action_declenchee=False,
    )
    db.add(log)
    await db.flush()

    if action_auto and tiers_potentiel is not None:
        await _notify_tiers(
            db,
            tiers_id=tiers_potentiel,
            source_log=log,
            motif="regle_auto",
        )
        log.action_declenchee = True
        await db.flush()

    return log


async def list_preferences(db: AsyncSession, *, user: User) -> list[dict]:
    result = await db.execute(
        select(PreferenceConsentement).where(PreferenceConsentement.user_id == user.id)
    )
    by_type = {p.type_alerte: p for p in result.scalars().all()}

    rows: list[dict] = []
    for type_alerte in ALERT_REGISTRY:
        pref = by_type.get(type_alerte)
        if pref:
            rows.append(_serialize_pref(pref))
        else:
            rows.append(
                {
                    "id": None,
                    "type_alerte": type_alerte,
                    "toujours_demander": True,
                    "regle_auto": None,
                }
            )
    # préférences custom hors registre
    for type_alerte, pref in by_type.items():
        if type_alerte not in ALERT_REGISTRY:
            rows.append(_serialize_pref(pref))
    return rows


async def upsert_preference(
    db: AsyncSession,
    *,
    user: User,
    type_alerte: str,
    toujours_demander: bool,
    regle_auto: dict | None,
) -> dict:
    type_norm = type_alerte.strip()
    if not type_norm:
        raise AppException("TYPE_INVALIDE", "Type d'alerte invalide.", status_code=400)

    # regle_auto seulement si l'utilisateur désactive "toujours demander"
    if toujours_demander:
        regle_auto = None
    elif regle_auto is not None and not isinstance(regle_auto, dict):
        raise AppException(
            "TYPE_INVALIDE",
            "regle_auto doit être un objet JSON (ex: {delai_heures: 48}).",
            status_code=400,
        )

    pref = await _get_preference(db, user_id=user.id, type_alerte=type_norm)
    if pref is None:
        pref = PreferenceConsentement(
            user_id=user.id,
            type_alerte=type_norm,
            toujours_demander=toujours_demander,
            regle_auto=regle_auto,
        )
        db.add(pref)
    else:
        pref.toujours_demander = toujours_demander
        pref.regle_auto = regle_auto

    await db.commit()
    await db.refresh(pref)
    return _serialize_pref(pref)


async def list_notifications(
    db: AsyncSession, *, user: User, depuis: datetime | None = None
) -> list[dict]:
    stmt = select(NotificationLog).where(NotificationLog.destinataire_id == user.id)
    if depuis is not None:
        d = depuis if depuis.tzinfo else depuis.replace(tzinfo=UTC)
        stmt = stmt.where(NotificationLog.envoye_at >= d)
    stmt = stmt.order_by(NotificationLog.envoye_at.desc())
    result = await db.execute(stmt)
    return [_serialize_log(n) for n in result.scalars().all()]


async def respond(
    db: AsyncSession, *, user: User, notification_id: UUID, reponse: str
) -> dict:
    if reponse not in VALID_REPONSES:
        raise AppException(
            "TYPE_INVALIDE",
            "Réponse invalide. Choisis oui, non ou reporter.",
            status_code=400,
        )

    log = await db.get(NotificationLog, notification_id)
    if log is None or log.destinataire_id != user.id:
        raise AppException(
            "NOTIFICATION_NOT_FOUND",
            "Cette notification est introuvable.",
            status_code=404,
        )
    if not log.proposition:
        raise AppException(
            "TYPE_INVALIDE",
            "Cette notification n'attend pas de réponse.",
            status_code=400,
        )
    if log.reponse is not None:
        raise AppException(
            "DEJA_REPONDU",
            "Tu as déjà répondu à cette proposition.",
            status_code=409,
        )

    now = datetime.now(UTC)
    log.reponse = reponse
    log.repondu_at = now
    action_declenchee = False

    if reponse == "oui" and log.tiers_potentiel_id is not None:
        await _notify_tiers(
            db,
            tiers_id=log.tiers_potentiel_id,
            source_log=log,
            motif="consentement_oui",
        )
        log.action_declenchee = True
        action_declenchee = True
        message = "Merci. Ton aidant a été informé."
    elif reponse == "oui":
        # Pas de tiers configuré : on journalise le consentement sans action
        log.action_declenchee = False
        message = "Merci pour ta réponse. Aucun contact n'était configuré pour prévenir."
    elif reponse == "non":
        message = "Compris. On ne prévient personne pour cette alerte."
    else:
        message = "OK, on te reproposera plus tard."

    await db.commit()
    return {"message": message, "action_declenchee": action_declenchee}


async def _notify_tiers(
    db: AsyncSession, *, tiers_id: UUID, source_log: NotificationLog, motif: str
) -> None:
    db.add(
        NotificationLog(
            destinataire_id=tiers_id,
            type=f"{source_log.type}_tiers",
            contenu=(
                f"La personne que tu accompagnes a besoin d'attention "
                f"(suite à « {source_log.type} »)."
            ),
            declencheur={
                "source_notification_id": str(source_log.id),
                "type_source": source_log.type,
                "motif": motif,
            },
            proposition=False,
        )
    )
    await db.flush()


async def _get_preference(
    db: AsyncSession, *, user_id: UUID, type_alerte: str
) -> PreferenceConsentement | None:
    result = await db.execute(
        select(PreferenceConsentement).where(
            PreferenceConsentement.user_id == user_id,
            PreferenceConsentement.type_alerte == type_alerte,
        )
    )
    return result.scalar_one_or_none()


def _regle_auto_applicable(regle_auto: dict, contexte: dict) -> bool:
    """V1 : si regle_auto est définie et contexte.regle_auto_ok is True, appliquer."""
    if contexte.get("regle_auto_ok") is True:
        return True
    # delai_heures présent = règle configurée ; le module appelant doit passer regle_auto_ok
    return False


def _serialize_pref(pref: PreferenceConsentement) -> dict:
    return {
        "id": pref.id,
        "type_alerte": pref.type_alerte,
        "toujours_demander": pref.toujours_demander,
        "regle_auto": pref.regle_auto,
    }


def _serialize_log(log: NotificationLog) -> dict:
    return {
        "id": log.id,
        "type": log.type,
        "contenu": log.contenu,
        "declencheur": log.declencheur,
        "envoye_at": log.envoye_at,
        "proposition": log.proposition,
        "reponse": log.reponse,
        "repondu_at": log.repondu_at,
        "action_declenchee": log.action_declenchee,
        "tiers_potentiel_id": log.tiers_potentiel_id,
    }


def _default_contenu(type_alerte: str, contexte: dict) -> str:
    if type_alerte == "sos_declenche":
        contacts = contexte.get("contacts") or []
        noms = ", ".join(c.get("nom", "?") for c in contacts) or "tes contacts"
        return f"Alerte SOS déclenchée — contacts prévenus : {noms}."
    if type_alerte == "constante_degradation":
        return "On observe un changement sur ta constante. Ce n'est pas forcément grave."
    if type_alerte == "constante_amelioration":
        return "Bonne nouvelle : ta constante s'améliore. Continue comme ça !"
    if type_alerte == "stock_medicament_bas":
        nom = contexte.get("nom") or "ton médicament"
        stock = contexte.get("stock_restant")
        return (
            f"Le stock de {nom} est bas"
            + (f" ({stock} restant)" if stock is not None else "")
            + ". Pense à te réapprovisionner."
        )
    return f"Notification {type_alerte}."

"""Moteur de notification minimal — journalise via NotificationLog.

Toute alerte produit doit passer ici (engagement-principle). L'envoi SMS/push réel
viendra plus tard ; V1 = audit + contenu prêt à envoyer.
"""

from __future__ import annotations

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models import NotificationLog


async def trigger(
    db: AsyncSession,
    *,
    type_alerte: str,
    user_id: UUID,
    contexte: dict,
    contenu: str | None = None,
) -> NotificationLog:
    """Point d'entrée unique pour journaliser une alerte produit."""
    message = contenu or _default_contenu(type_alerte, contexte)
    log = NotificationLog(
        destinataire_id=user_id,
        type=type_alerte,
        contenu=message,
        declencheur={"type_alerte": type_alerte, **contexte},
    )
    db.add(log)
    await db.flush()
    return log


def _default_contenu(type_alerte: str, contexte: dict) -> str:
    if type_alerte == "sos_declenche":
        contacts = contexte.get("contacts") or []
        noms = ", ".join(c.get("nom", "?") for c in contacts) or "tes contacts"
        return f"Alerte SOS déclenchée — contacts prévenus : {noms}."
    return f"Notification {type_alerte}."

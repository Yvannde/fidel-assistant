"""Schémas API — préférences consentement et notifications."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class PreferenceConsentementOut(BaseModel):
    id: UUID | None = None
    type_alerte: str
    toujours_demander: bool
    regle_auto: dict[str, Any] | None = None


class PreferenceConsentementIn(BaseModel):
    toujours_demander: bool = True
    regle_auto: dict[str, Any] | None = None


class NotificationLogOut(BaseModel):
    id: UUID
    type: str
    contenu: str
    declencheur: dict[str, Any] | None = None
    envoye_at: datetime
    proposition: bool
    reponse: str | None = None
    repondu_at: datetime | None = None
    action_declenchee: bool
    tiers_potentiel_id: UUID | None = None


class NotificationReponseIn(BaseModel):
    reponse: str = Field(pattern="^(oui|non|reporter)$")


class NotificationReponseOut(BaseModel):
    message: str
    action_declenchee: bool

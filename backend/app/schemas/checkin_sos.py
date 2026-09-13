"""Schémas API — check-in et SOS."""

from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class CheckInIn(BaseModel):
    statut: str = Field(pattern="^(tres_mal|pas_top|ca_va|super)$")
    client_mutation_id: UUID | None = None


class CheckInOut(BaseModel):
    id: UUID
    date: date
    statut: str
    created_at: datetime


class SosTriggerOut(BaseModel):
    sos_id: UUID
    annulable_jusqu_a: datetime


class SosConfirmOut(BaseModel):
    sos_id: UUID
    statut: str
    aidants_notifies: int
    fallback_call_recommended: bool
    acked: bool = False


class SosStatusOut(BaseModel):
    sos_id: UUID
    statut: str
    acked: bool
    envoye_at: datetime | None = None
    acked_at: datetime | None = None


class SosActiveAidantOut(BaseModel):
    sos_id: UUID
    patient_id: UUID
    patient_prenom: str
    envoye_at: datetime | None = None


class PushTokenIn(BaseModel):
    token: str = Field(min_length=8, max_length=512)
    platform: str = Field(default="android", pattern="^(android|ios|web)$")


class PushTokenOut(BaseModel):
    token: str
    platform: str


class MessageOut(BaseModel):
    message: str

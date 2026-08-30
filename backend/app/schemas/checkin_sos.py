"""Schémas API — check-in et SOS."""

from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class CheckInIn(BaseModel):
    statut: str = Field(pattern="^(ca_va|pas_top)$")


class CheckInOut(BaseModel):
    id: UUID
    date: date
    statut: str
    created_at: datetime


class SosTriggerOut(BaseModel):
    sos_id: UUID
    annulable_jusqu_a: datetime


class MessageOut(BaseModel):
    message: str

"""Schémas API — voix de rappel."""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class VoixRappelOut(BaseModel):
    id: UUID | None = None
    patient_id: UUID
    type: str
    fichier_audio_url: str | None = None
    enregistree_par: UUID | None = None
    created_at: datetime | None = None

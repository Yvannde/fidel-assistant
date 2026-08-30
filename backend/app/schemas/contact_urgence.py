"""Schémas API — contacts d'urgence."""

from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, Field


class ContactUrgenceIn(BaseModel):
    nom: str = Field(min_length=1, max_length=255)
    telephone: str = Field(min_length=6, max_length=32)
    relation: str = Field(min_length=1, max_length=64, examples=["fils", "voisin", "epoux"])


class ContactUrgenceOut(BaseModel):
    id: UUID
    nom: str
    telephone: str
    relation: str

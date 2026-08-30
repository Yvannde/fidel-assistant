"""Schémas API — constantes de santé."""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class ConstanteIn(BaseModel):
    type: str = Field(min_length=1, max_length=32)
    valeur: float | str | dict[str, Any]
    unite: str = Field(min_length=1, max_length=32)
    mesure_at: datetime
    source: str = Field(pattern="^(manuel|objet_connecte)$", default="manuel")


class ConstanteOut(BaseModel):
    id: UUID
    type: str
    valeur: float | str | dict[str, Any]
    unite: str
    mesure_at: datetime
    source: str


class ConstanteCreateOut(BaseModel):
    constante: ConstanteOut
    tendance: str
    message: str

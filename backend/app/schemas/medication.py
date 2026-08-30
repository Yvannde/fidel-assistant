"""Schémas API — dashboard home, traitements, médicaments, prises."""

from __future__ import annotations

from datetime import date, datetime, time
from uuid import UUID

from pydantic import BaseModel, Field


class HoraireIn(BaseModel):
    heure: time
    jours: list[str] = Field(default_factory=lambda: ["tous"])


class HoraireOut(BaseModel):
    id: UUID
    heure: time
    jours: list[str]
    actif: bool


class MedicamentCreateIn(BaseModel):
    nom: str = Field(min_length=1, max_length=255)
    dosage: str = Field(min_length=1, max_length=128)
    forme: str = Field(default="comprime", max_length=64)
    prise_avec_repas: str | None = Field(default=None, max_length=32)
    instructions: str | None = None
    stock_restant: int | None = Field(default=None, ge=0)
    seuil_alerte_stock: int | None = Field(default=None, ge=0)
    horaires: list[HoraireIn] = Field(min_length=1)


class MedicamentUpdateIn(BaseModel):
    nom: str | None = Field(default=None, max_length=255)
    dosage: str | None = Field(default=None, max_length=128)
    forme: str | None = Field(default=None, max_length=64)
    prise_avec_repas: str | None = Field(default=None, max_length=32)
    instructions: str | None = None
    actif: bool | None = None


class MedicamentStockIn(BaseModel):
    stock_restant: int = Field(ge=0)


class MedicamentStockOut(BaseModel):
    stock_restant: int
    alerte_declenchee: bool


class MedicamentOut(BaseModel):
    id: UUID
    patient_traitement_id: UUID
    nom: str
    dosage: str
    forme: str
    prise_avec_repas: str | None
    instructions: str | None
    stock_restant: int | None
    seuil_alerte_stock: int | None
    actif: bool
    horaires: list[HoraireOut] = []


class PatientTraitementCreateIn(BaseModel):
    maladie_id: UUID
    phase: str = Field(pattern="^(debut|en_cours|maintenance|inconnu)$")
    date_debut: date | None = None
    date_fin_prevue: date | None = None
    protocole_id: UUID | None = None
    maladie_libelle: str | None = Field(default=None, max_length=255)
    lieu_suivi: str | None = Field(default=None, max_length=255)
    attributs: dict[str, object] | None = None


class PatientTraitementOut(BaseModel):
    id: UUID
    maladie_id: UUID
    maladie_code: str
    maladie_nom: str
    phase: str
    en_traitement: bool
    date_debut: date | None
    date_fin_prevue: date | None
    protocole_id: UUID | None
    lieu_suivi: str | None
    statut: str
    jour_traitement: int | None = None
    medicaments_count: int = 0


class SuggestionMedicamentOut(BaseModel):
    nom: str
    dosage: str
    forme: str
    prise_avec_repas: str | None = None
    horaires_suggestion: list[dict[str, object]] = []


class DashboardTraitementOut(BaseModel):
    id: UUID
    maladie_code: str
    maladie_nom: str
    phase: str
    date_debut: date | None
    jour_traitement: int | None
    medicaments_configures: bool
    suggestions_medicaments: list[SuggestionMedicamentOut] = []


class PriseOut(BaseModel):
    id: UUID
    medicament_id: UUID
    medicament_nom: str
    dosage: str
    heure_prevue: datetime
    statut: str
    confirmee_at: datetime | None = None
    canal: str | None = None


class DashboardOut(BaseModel):
    prochaine_action: str
    medicaments_configures: bool
    notifications_accordees: bool
    traitements: list[DashboardTraitementOut] = []
    prises_aujourdhui: list[PriseOut] = []


class PriseConfirmerIn(BaseModel):
    canal: str = Field(pattern="^(app|sms)$", default="app")


class PriseReporterIn(BaseModel):
    nouvelle_heure: datetime


class PriseSyncItemIn(BaseModel):
    id: UUID
    statut: str = Field(pattern="^(confirmee|manquee|en_attente)$")
    confirmee_at: datetime | None = None


class PriseSyncOut(BaseModel):
    synced: list[UUID]
    conflicts: list[UUID]


class MessageOut(BaseModel):
    message: str

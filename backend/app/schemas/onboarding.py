from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class OnboardingStatusOut(BaseModel):
    onboarding_step: str | None
    has_patient_profile: bool
    is_aidant: bool


class OnboardingStepOut(BaseModel):
    onboarding_step: str | None


class InfosIn(BaseModel):
    nom_complet: str = Field(min_length=2, max_length=255)
    date_naissance: date
    sexe: str = Field(min_length=1, max_length=32, examples=["F", "M", "autre"])
    localisation: str = Field(min_length=2, max_length=255, examples=["Douala"])
    phone: str | None = Field(default=None, max_length=32)


class BesoinSuiviIn(BaseModel):
    actif: bool


class BesoinSuiviOut(BaseModel):
    onboarding_step: str | None
    has_patient_profile: bool


class MaladieOut(BaseModel):
    id: UUID
    code: str
    nom: str
    description: str | None = None
    constantes_prioritaires: list[str] = []
    questions_onboarding: list[dict[str, object]] = []


class TraitementItemIn(BaseModel):
    maladie_id: UUID
    phase: str = Field(pattern="^(debut|en_cours|maintenance|inconnu)$")
    date_debut: date | None = None
    date_fin_prevue: date | None = None
    protocole_id: UUID | None = None
    maladie_libelle: str | None = Field(default=None, max_length=255)
    lieu_suivi: str | None = Field(default=None, max_length=255)
    attributs: dict[str, object] | None = None


class TraitementIn(BaseModel):
    en_traitement: bool
    traitements: list[TraitementItemIn] | None = None


class PermissionsIn(BaseModel):
    notifications_accordees: bool
    batterie_exemptee: bool


class ActivatePatientOut(BaseModel):
    has_patient_profile: bool = True
    onboarding_hint: str = "patient_traitement"


class SyncCodeOut(BaseModel):
    code: str
    qr_payload: str
    expires_at: datetime


class AidantSyncIn(BaseModel):
    code: str = Field(min_length=4, max_length=16)


class AidantSyncOut(BaseModel):
    patient_id: UUID
    patient_prenom: str
    is_aidant: bool = True
    message: str | None = None


class PatientOut(BaseModel):
    user_id: UUID
    nom_complet: str | None
    date_naissance: date | None
    sexe: str | None
    localisation: str | None
    photo_url: str | None
    notifications_accordees: bool
    batterie_exemptee: bool
    notifications_discretes: bool = False


class PatientUpdateIn(BaseModel):
    nom_complet: str | None = Field(default=None, min_length=2, max_length=255)
    localisation: str | None = Field(default=None, min_length=2, max_length=255)
    photo_url: str | None = Field(default=None, max_length=512)
    notifications_accordees: bool | None = None
    batterie_exemptee: bool | None = None
    notifications_discretes: bool | None = None

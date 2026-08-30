"""Modèles SQLAlchemy — voir skills/data-model/SKILL.md."""

from app.models.catalog import MaladieConfig, ProtocoleMedicamentSuggere, ProtocoleTraitement
from app.models.medication import Medicament, MedicamentHoraire, Prise
from app.models.notification import NotificationLog
from app.models.patient import (
    CheckIn,
    ContactUrgence,
    Maladie,
    Patient,
    PatientAidant,
    PatientTraitement,
    PatientTraitementAttribut,
    SosAlerte,
    SyncCode,
)
from app.models.user import (
    CguAcceptance,
    ConsentementSante,
    OtpCode,
    Session,
    User,
)

__all__ = [
    "User",
    "OtpCode",
    "CguAcceptance",
    "ConsentementSante",
    "Session",
    "Patient",
    "Maladie",
    "MaladieConfig",
    "ProtocoleTraitement",
    "ProtocoleMedicamentSuggere",
    "PatientTraitement",
    "PatientTraitementAttribut",
    "PatientAidant",
    "SyncCode",
    "ContactUrgence",
    "CheckIn",
    "SosAlerte",
    "Medicament",
    "MedicamentHoraire",
    "Prise",
    "NotificationLog",
]

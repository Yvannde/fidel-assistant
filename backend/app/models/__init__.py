"""Modèles SQLAlchemy — voir skills/data-model/SKILL.md."""

from app.models.notification import NotificationLog
from app.models.patient import (
    Maladie,
    Patient,
    PatientAidant,
    PatientTraitement,
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
    "PatientTraitement",
    "PatientAidant",
    "SyncCode",
    "NotificationLog",
]

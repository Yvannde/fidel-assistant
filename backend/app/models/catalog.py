"""Catalogue référentiel maladies / protocoles — données backend, lecture seule côté app."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.patient import Maladie, PatientTraitement


class MaladieConfig(Base):
    """Configuration de suivi par maladie (questions onboarding, constantes prioritaires)."""

    __tablename__ = "maladie_configs"

    maladie_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("maladies.id", ondelete="CASCADE"),
        primary_key=True,
    )
    questions_onboarding: Mapped[list] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text("'[]'::jsonb"),
    )
    constantes_prioritaires: Mapped[list] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text("'[]'::jsonb"),
    )
    duree_traitement_jours_typique: Mapped[int | None] = mapped_column(Integer, nullable=True)
    notifications_discretes_defaut: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    maladie: Mapped[Maladie] = relationship("Maladie", back_populates="config")


class ProtocoleTraitement(Base):
    """Protocole thérapeutique type (catalogue) — suggestions médicaments et durée."""

    __tablename__ = "protocoles_traitement"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    maladie_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("maladies.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    code: Mapped[str] = mapped_column(String(64), nullable=False)
    libelle: Mapped[str] = mapped_column(String(255), nullable=False)
    phase_cible: Mapped[str | None] = mapped_column(String(32), nullable=True)
    duree_jours: Mapped[int | None] = mapped_column(Integer, nullable=True)
    ordre: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    maladie: Mapped[Maladie] = relationship("Maladie", back_populates="protocoles")
    medicaments_suggeres: Mapped[list[ProtocoleMedicamentSuggere]] = relationship(
        back_populates="protocole",
        order_by="ProtocoleMedicamentSuggere.ordre",
    )
    patient_traitements: Mapped[list[PatientTraitement]] = relationship(
        "PatientTraitement", back_populates="protocole"
    )


class ProtocoleMedicamentSuggere(Base):
    """Médicament suggéré dans un protocole catalogue (wizard post-onboarding)."""

    __tablename__ = "protocole_medicaments_suggeres"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    protocole_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("protocoles_traitement.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    nom: Mapped[str] = mapped_column(String(255), nullable=False)
    dosage: Mapped[str] = mapped_column(String(128), nullable=False)
    forme: Mapped[str] = mapped_column(String(64), nullable=False, server_default="comprime")
    prise_avec_repas: Mapped[str | None] = mapped_column(String(32), nullable=True)
    horaires_suggestion: Mapped[list] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text("'[]'::jsonb"),
    )
    ordre: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    protocole: Mapped[ProtocoleTraitement] = relationship(back_populates="medicaments_suggeres")

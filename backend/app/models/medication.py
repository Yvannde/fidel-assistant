"""Médicaments, horaires et prises — exécution du planning patient."""

from __future__ import annotations

from datetime import datetime, time
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, Time, func, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.patient import PatientTraitement


class Medicament(Base):
    __tablename__ = "medicaments"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_traitement_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patient_traitements.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    nom: Mapped[str] = mapped_column(String(255), nullable=False)
    dosage: Mapped[str] = mapped_column(String(128), nullable=False)
    forme: Mapped[str] = mapped_column(String(64), nullable=False, server_default="comprime")
    prise_avec_repas: Mapped[str | None] = mapped_column(String(32), nullable=True)
    instructions: Mapped[str | None] = mapped_column(Text, nullable=True)
    stock_restant: Mapped[int | None] = mapped_column(Integer, nullable=True)
    seuil_alerte_stock: Mapped[int | None] = mapped_column(Integer, nullable=True)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    traitement: Mapped[PatientTraitement] = relationship(
        "PatientTraitement", back_populates="medicaments"
    )
    horaires: Mapped[list[MedicamentHoraire]] = relationship(back_populates="medicament")


class MedicamentHoraire(Base):
    __tablename__ = "medicament_horaires"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    medicament_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("medicaments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    heure: Mapped[time] = mapped_column(Time, nullable=False)
    jours: Mapped[list] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text("'[\"tous\"]'::jsonb"),
    )
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    medicament: Mapped[Medicament] = relationship(back_populates="horaires")
    prises: Mapped[list[Prise]] = relationship("Prise", back_populates="horaire")


class Prise(Base):
    __tablename__ = "prises"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    medicament_horaire_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("medicament_horaires.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    heure_prevue: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )
    statut: Mapped[str] = mapped_column(
        String(32), nullable=False, server_default="en_attente", index=True
    )
    confirmee_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    canal: Mapped[str | None] = mapped_column(String(16), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    horaire: Mapped[MedicamentHoraire] = relationship(back_populates="prises")

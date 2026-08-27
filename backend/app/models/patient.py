"""Profils patient, maladies, traitements, sync aidant."""

from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, String, Text, func, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class Patient(Base):
    __tablename__ = "patients"

    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    localisation: Mapped[str | None] = mapped_column(String(255), nullable=True)
    nom_complet: Mapped[str | None] = mapped_column(String(255), nullable=True)
    date_naissance: Mapped[date | None] = mapped_column(Date, nullable=True)
    sexe: Mapped[str | None] = mapped_column(String(32), nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    notifications_accordees: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    batterie_exemptee: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    user: Mapped[User] = relationship(back_populates="patient")
    traitements: Mapped[list[PatientTraitement]] = relationship(back_populates="patient")
    sync_codes: Mapped[list[SyncCode]] = relationship(back_populates="patient")
    aidants: Mapped[list[PatientAidant]] = relationship(back_populates="patient")


class Maladie(Base):
    __tablename__ = "maladies"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    nom: Mapped[str] = mapped_column(String(128), nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))


class PatientTraitement(Base):
    __tablename__ = "patient_traitements"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    maladie_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("maladies.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    phase: Mapped[str] = mapped_column(String(32), nullable=False)  # debut|en_cours|...
    date_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    patient: Mapped[Patient] = relationship(back_populates="traitements")
    maladie: Mapped[Maladie] = relationship()


class PatientAidant(Base):
    __tablename__ = "patient_aidant"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    aidant_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    statut: Mapped[str] = mapped_column(String(32), nullable=False, server_default="actif")
    niveau_permission: Mapped[dict] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text("'{\"observance\": true, \"constantes\": false}'::jsonb"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    patient: Mapped[Patient] = relationship(back_populates="aidants")
    aidant: Mapped[User] = relationship(
        back_populates="aidant_relations",
        foreign_keys=[aidant_id],
    )


class SyncCode(Base):
    __tablename__ = "sync_codes"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    patient_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("patients.user_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    code: Mapped[str] = mapped_column(String(16), nullable=False, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    patient: Mapped[Patient] = relationship(back_populates="sync_codes")

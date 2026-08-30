"""Journal des notifications / alertes + préférences de consentement."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, UniqueConstraint, func, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    destinataire_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    type: Mapped[str] = mapped_column(String(64), nullable=False)
    contenu: Mapped[str] = mapped_column(Text, nullable=False)
    declencheur: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    envoye_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    proposition: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    reponse: Mapped[str | None] = mapped_column(String(16), nullable=True)
    repondu_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    action_declenchee: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false")
    )
    tiers_potentiel_id: Mapped[UUID | None] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    destinataire: Mapped[User] = relationship(foreign_keys=[destinataire_id])


class PreferenceConsentement(Base):
    __tablename__ = "preferences_consentement"
    __table_args__ = (
        UniqueConstraint("user_id", "type_alerte", name="uq_pref_consent_user_type"),
    )

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    type_alerte: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    toujours_demander: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true")
    )
    regle_auto: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    user: Mapped[User] = relationship()

"""add_preferences_consentement_and_notification_reponse

Revision ID: f2c5a94e7d36
Revises: e1b4f83d6c25
Create Date: 2026-08-30 17:55:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "f2c5a94e7d36"
down_revision: str | None = "e1b4f83d6c25"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "preferences_consentement",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("type_alerte", sa.String(length=64), nullable=False),
        sa.Column(
            "toujours_demander",
            sa.Boolean(),
            server_default=sa.text("true"),
            nullable=False,
        ),
        sa.Column("regle_auto", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "type_alerte", name="uq_pref_consent_user_type"),
    )
    op.create_index(
        op.f("ix_preferences_consentement_user_id"),
        "preferences_consentement",
        ["user_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_preferences_consentement_type_alerte"),
        "preferences_consentement",
        ["type_alerte"],
        unique=False,
    )

    op.add_column(
        "notification_logs",
        sa.Column("proposition", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.add_column(
        "notification_logs",
        sa.Column("reponse", sa.String(length=16), nullable=True),
    )
    op.add_column(
        "notification_logs",
        sa.Column("repondu_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "notification_logs",
        sa.Column(
            "action_declenchee",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )
    op.add_column(
        "notification_logs",
        sa.Column("tiers_potentiel_id", sa.UUID(), nullable=True),
    )
    op.create_index(
        op.f("ix_notification_logs_tiers_potentiel_id"),
        "notification_logs",
        ["tiers_potentiel_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_notification_logs_tiers_potentiel_id_users",
        "notification_logs",
        "users",
        ["tiers_potentiel_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_notification_logs_tiers_potentiel_id_users",
        "notification_logs",
        type_="foreignkey",
    )
    op.drop_index(
        op.f("ix_notification_logs_tiers_potentiel_id"), table_name="notification_logs"
    )
    op.drop_column("notification_logs", "tiers_potentiel_id")
    op.drop_column("notification_logs", "action_declenchee")
    op.drop_column("notification_logs", "repondu_at")
    op.drop_column("notification_logs", "reponse")
    op.drop_column("notification_logs", "proposition")

    op.drop_index(
        op.f("ix_preferences_consentement_type_alerte"),
        table_name="preferences_consentement",
    )
    op.drop_index(
        op.f("ix_preferences_consentement_user_id"),
        table_name="preferences_consentement",
    )
    op.drop_table("preferences_consentement")

"""add_check_ins_and_sos_alertes

Revision ID: d9a3e72c5b14
Revises: c7f2a91b4e08
Create Date: 2026-08-30 17:25:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "d9a3e72c5b14"
down_revision: str | None = "c7f2a91b4e08"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "check_ins",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("statut", sa.String(length=32), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["patient_id"], ["patients.user_id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("patient_id", "date", name="uq_check_ins_patient_date"),
    )
    op.create_index(op.f("ix_check_ins_patient_id"), "check_ins", ["patient_id"], unique=False)
    op.create_index(op.f("ix_check_ins_date"), "check_ins", ["date"], unique=False)

    op.create_table(
        "sos_alertes",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("statut", sa.String(length=32), server_default="en_attente", nullable=False),
        sa.Column("annulable_jusqu_a", sa.DateTime(timezone=True), nullable=False),
        sa.Column("envoye_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("annule_at", sa.DateTime(timezone=True), nullable=True),
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
        sa.ForeignKeyConstraint(["patient_id"], ["patients.user_id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_sos_alertes_patient_id"), "sos_alertes", ["patient_id"], unique=False)
    op.create_index(op.f("ix_sos_alertes_statut"), "sos_alertes", ["statut"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_sos_alertes_statut"), table_name="sos_alertes")
    op.drop_index(op.f("ix_sos_alertes_patient_id"), table_name="sos_alertes")
    op.drop_table("sos_alertes")
    op.drop_index(op.f("ix_check_ins_date"), table_name="check_ins")
    op.drop_index(op.f("ix_check_ins_patient_id"), table_name="check_ins")
    op.drop_table("check_ins")

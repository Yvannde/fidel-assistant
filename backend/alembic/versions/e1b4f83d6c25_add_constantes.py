"""add_constantes

Revision ID: e1b4f83d6c25
Revises: d9a3e72c5b14
Create Date: 2026-08-30 17:35:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "e1b4f83d6c25"
down_revision: str | None = "d9a3e72c5b14"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "constantes",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("type", sa.String(length=32), nullable=False),
        sa.Column("valeur", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("unite", sa.String(length=32), nullable=False),
        sa.Column("mesure_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("source", sa.String(length=32), server_default="manuel", nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["patient_id"], ["patients.user_id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_constantes_patient_id"), "constantes", ["patient_id"], unique=False)
    op.create_index(op.f("ix_constantes_type"), "constantes", ["type"], unique=False)
    op.create_index(op.f("ix_constantes_mesure_at"), "constantes", ["mesure_at"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_constantes_mesure_at"), table_name="constantes")
    op.drop_index(op.f("ix_constantes_type"), table_name="constantes")
    op.drop_index(op.f("ix_constantes_patient_id"), table_name="constantes")
    op.drop_table("constantes")

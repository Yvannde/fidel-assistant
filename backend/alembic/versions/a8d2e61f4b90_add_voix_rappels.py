"""Migration — voix_rappels."""

from __future__ import annotations

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "a8d2e61f4b90"
down_revision: str | None = "f2c5a94e7d36"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "voix_rappels",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("patient_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "type",
            sa.String(length=32),
            server_default="systeme",
            nullable=False,
        ),
        sa.Column("fichier_audio_url", sa.String(length=1024), nullable=True),
        sa.Column("enregistree_par", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["enregistree_par"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(
            ["patient_id"], ["patients.user_id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("patient_id", name="uq_voix_rappels_patient"),
    )
    op.create_index(
        op.f("ix_voix_rappels_patient_id"), "voix_rappels", ["patient_id"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_voix_rappels_patient_id"), table_name="voix_rappels")
    op.drop_table("voix_rappels")

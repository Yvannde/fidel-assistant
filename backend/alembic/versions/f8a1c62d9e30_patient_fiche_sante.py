"""patient_fiche_sante

Revision ID: f8a1c62d9e30
Revises: e6c3d94a1b20
Create Date: 2026-09-13 22:30:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "f8a1c62d9e30"
down_revision: str | None = "e6c3d94a1b20"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "patients",
        sa.Column("groupe_sanguin", sa.String(length=8), nullable=True),
    )
    op.add_column(
        "patients",
        sa.Column("rhesus", sa.String(length=4), nullable=True),
    )
    op.add_column(
        "patients",
        sa.Column("electrophorese", sa.String(length=16), nullable=True),
    )
    op.add_column(
        "patients",
        sa.Column("taille_cm", sa.Integer(), nullable=True),
    )
    op.add_column(
        "patients",
        sa.Column("groupe_sanguin_confirmed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "patients",
        sa.Column("rhesus_confirmed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "patients",
        sa.Column("electrophorese_confirmed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "patients",
        sa.Column("taille_cm_confirmed_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("patients", "taille_cm_confirmed_at")
    op.drop_column("patients", "electrophorese_confirmed_at")
    op.drop_column("patients", "rhesus_confirmed_at")
    op.drop_column("patients", "groupe_sanguin_confirmed_at")
    op.drop_column("patients", "taille_cm")
    op.drop_column("patients", "electrophorese")
    op.drop_column("patients", "rhesus")
    op.drop_column("patients", "groupe_sanguin")

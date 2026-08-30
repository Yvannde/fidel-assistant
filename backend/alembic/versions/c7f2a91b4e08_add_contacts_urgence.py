"""add_contacts_urgence

Revision ID: c7f2a91b4e08
Revises: b4e8c1a29f3d
Create Date: 2026-08-30 17:15:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "c7f2a91b4e08"
down_revision: str | None = "b4e8c1a29f3d"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "contacts_urgence",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("patient_id", sa.UUID(), nullable=False),
        sa.Column("nom", sa.String(length=255), nullable=False),
        sa.Column("telephone", sa.String(length=32), nullable=False),
        sa.Column("relation", sa.String(length=64), nullable=False),
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
    op.create_index(
        op.f("ix_contacts_urgence_patient_id"),
        "contacts_urgence",
        ["patient_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_contacts_urgence_patient_id"), table_name="contacts_urgence")
    op.drop_table("contacts_urgence")

"""sos_push_tokens_and_ack

Revision ID: e6c3d94a1b20
Revises: d4a1b7c90e12
Create Date: 2026-09-13 13:40:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "e6c3d94a1b20"
down_revision: str | None = "d4a1b7c90e12"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "sos_alertes",
        sa.Column("acked_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "sos_alertes",
        sa.Column("acked_by_aidant_id", sa.UUID(), nullable=True),
    )
    op.create_index(
        op.f("ix_sos_alertes_acked_by_aidant_id"),
        "sos_alertes",
        ["acked_by_aidant_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_sos_alertes_acked_by_aidant_id_users",
        "sos_alertes",
        "users",
        ["acked_by_aidant_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.create_table(
        "device_push_tokens",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("token", sa.String(length=512), nullable=False),
        sa.Column("platform", sa.String(length=32), server_default="android", nullable=False),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "token", name="uq_device_push_tokens_user_token"),
    )
    op.create_index(
        op.f("ix_device_push_tokens_user_id"),
        "device_push_tokens",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_device_push_tokens_user_id"), table_name="device_push_tokens")
    op.drop_table("device_push_tokens")
    op.drop_constraint(
        "fk_sos_alertes_acked_by_aidant_id_users",
        "sos_alertes",
        type_="foreignkey",
    )
    op.drop_index(op.f("ix_sos_alertes_acked_by_aidant_id"), table_name="sos_alertes")
    op.drop_column("sos_alertes", "acked_by_aidant_id")
    op.drop_column("sos_alertes", "acked_at")

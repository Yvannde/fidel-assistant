"""Migration — prises.server_version (Sync V2 Phase 4)."""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "d4a1b7c90e12"
down_revision: str | None = "c3f9e2a81b07"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "prises",
        sa.Column(
            "server_version",
            sa.Integer(),
            nullable=False,
            server_default="1",
        ),
    )


def downgrade() -> None:
    op.drop_column("prises", "server_version")

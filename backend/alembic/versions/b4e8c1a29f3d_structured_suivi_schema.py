"""structured_suivi_schema

Revision ID: b4e8c1a29f3d
Revises: a991474596b1
Create Date: 2026-08-28 08:45:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "b4e8c1a29f3d"
down_revision: str | None = "a991474596b1"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_NOM_TO_CODE = {
    "Tuberculose": "tuberculose",
    "Diabète": "diabete",
    "Hypertension": "hypertension",
    "VIH": "vih",
    "Autre": "autre",
}


def upgrade() -> None:
    # --- maladies : identifiant stable ---
    op.add_column("maladies", sa.Column("code", sa.String(length=64), nullable=True))
    op.add_column(
        "maladies",
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.add_column(
        "maladies",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    conn = op.get_bind()
    for nom, code in _NOM_TO_CODE.items():
        conn.execute(
            sa.text("UPDATE maladies SET code = :code WHERE nom = :nom AND code IS NULL"),
            {"code": code, "nom": nom},
        )
    conn.execute(
        sa.text(
            "UPDATE maladies SET code = lower(replace(nom, ' ', '_')) "
            "WHERE code IS NULL"
        )
    )
    op.alter_column("maladies", "code", nullable=False)
    op.create_index(op.f("ix_maladies_code"), "maladies", ["code"], unique=True)

    # --- catalogue ---
    op.create_table(
        "maladie_configs",
        sa.Column("maladie_id", sa.UUID(), nullable=False),
        sa.Column(
            "questions_onboarding",
            postgresql.JSONB(astext_type=sa.Text()),
            server_default=sa.text("'[]'::jsonb"),
            nullable=False,
        ),
        sa.Column(
            "constantes_prioritaires",
            postgresql.JSONB(astext_type=sa.Text()),
            server_default=sa.text("'[]'::jsonb"),
            nullable=False,
        ),
        sa.Column("duree_traitement_jours_typique", sa.Integer(), nullable=True),
        sa.Column(
            "notifications_discretes_defaut",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
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
        sa.ForeignKeyConstraint(["maladie_id"], ["maladies.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("maladie_id"),
    )
    op.create_table(
        "protocoles_traitement",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("maladie_id", sa.UUID(), nullable=False),
        sa.Column("code", sa.String(length=64), nullable=False),
        sa.Column("libelle", sa.String(length=255), nullable=False),
        sa.Column("phase_cible", sa.String(length=32), nullable=True),
        sa.Column("duree_jours", sa.Integer(), nullable=True),
        sa.Column("ordre", sa.Integer(), server_default=sa.text("0"), nullable=False),
        sa.Column("actif", sa.Boolean(), server_default=sa.text("true"), nullable=False),
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
        sa.ForeignKeyConstraint(["maladie_id"], ["maladies.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("maladie_id", "code", name="uq_protocole_maladie_code"),
    )
    op.create_index(
        op.f("ix_protocoles_traitement_maladie_id"),
        "protocoles_traitement",
        ["maladie_id"],
        unique=False,
    )
    op.create_table(
        "protocole_medicaments_suggeres",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("protocole_id", sa.UUID(), nullable=False),
        sa.Column("nom", sa.String(length=255), nullable=False),
        sa.Column("dosage", sa.String(length=128), nullable=False),
        sa.Column("forme", sa.String(length=64), server_default="comprime", nullable=False),
        sa.Column("prise_avec_repas", sa.String(length=32), nullable=True),
        sa.Column(
            "horaires_suggestion",
            postgresql.JSONB(astext_type=sa.Text()),
            server_default=sa.text("'[]'::jsonb"),
            nullable=False,
        ),
        sa.Column("ordre", sa.Integer(), server_default=sa.text("0"), nullable=False),
        sa.Column("actif", sa.Boolean(), server_default=sa.text("true"), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["protocole_id"], ["protocoles_traitement.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_protocole_medicaments_suggeres_protocole_id"),
        "protocole_medicaments_suggeres",
        ["protocole_id"],
        unique=False,
    )

    # --- patient ---
    op.add_column(
        "patients",
        sa.Column(
            "notifications_discretes",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
    )
    op.add_column("patient_traitements", sa.Column("protocole_id", sa.UUID(), nullable=True))
    op.add_column(
        "patient_traitements",
        sa.Column("en_traitement", sa.Boolean(), server_default=sa.text("true"), nullable=False),
    )
    op.add_column("patient_traitements", sa.Column("date_fin_prevue", sa.Date(), nullable=True))
    op.add_column(
        "patient_traitements", sa.Column("maladie_libelle", sa.String(length=255), nullable=True)
    )
    op.add_column(
        "patient_traitements", sa.Column("lieu_suivi", sa.String(length=255), nullable=True)
    )
    op.add_column(
        "patient_traitements",
        sa.Column("statut", sa.String(length=32), server_default="actif", nullable=False),
    )
    op.add_column(
        "patient_traitements",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.create_index(
        op.f("ix_patient_traitements_protocole_id"),
        "patient_traitements",
        ["protocole_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_patient_traitements_statut"),
        "patient_traitements",
        ["statut"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_patient_traitements_protocole_id",
        "patient_traitements",
        "protocoles_traitement",
        ["protocole_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_table(
        "patient_traitement_attributs",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("patient_traitement_id", sa.UUID(), nullable=False),
        sa.Column("code", sa.String(length=64), nullable=False),
        sa.Column("valeur", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["patient_traitement_id"], ["patient_traitements.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "patient_traitement_id", "code", name="uq_traitement_attribut_code"
        ),
    )
    op.create_index(
        op.f("ix_patient_traitement_attributs_code"),
        "patient_traitement_attributs",
        ["code"],
        unique=False,
    )
    op.create_index(
        op.f("ix_patient_traitement_attributs_patient_traitement_id"),
        "patient_traitement_attributs",
        ["patient_traitement_id"],
        unique=False,
    )

    # --- médicaments & prises ---
    op.create_table(
        "medicaments",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("patient_traitement_id", sa.UUID(), nullable=False),
        sa.Column("nom", sa.String(length=255), nullable=False),
        sa.Column("dosage", sa.String(length=128), nullable=False),
        sa.Column("forme", sa.String(length=64), server_default="comprime", nullable=False),
        sa.Column("prise_avec_repas", sa.String(length=32), nullable=True),
        sa.Column("instructions", sa.Text(), nullable=True),
        sa.Column("stock_restant", sa.Integer(), nullable=True),
        sa.Column("seuil_alerte_stock", sa.Integer(), nullable=True),
        sa.Column("actif", sa.Boolean(), server_default=sa.text("true"), nullable=False),
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
        sa.ForeignKeyConstraint(
            ["patient_traitement_id"], ["patient_traitements.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_medicaments_patient_traitement_id"),
        "medicaments",
        ["patient_traitement_id"],
        unique=False,
    )
    op.create_table(
        "medicament_horaires",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("medicament_id", sa.UUID(), nullable=False),
        sa.Column("heure", sa.Time(), nullable=False),
        sa.Column(
            "jours",
            postgresql.JSONB(astext_type=sa.Text()),
            server_default=sa.text("'[\"tous\"]'::jsonb"),
            nullable=False,
        ),
        sa.Column("actif", sa.Boolean(), server_default=sa.text("true"), nullable=False),
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
        sa.ForeignKeyConstraint(["medicament_id"], ["medicaments.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_medicament_horaires_medicament_id"),
        "medicament_horaires",
        ["medicament_id"],
        unique=False,
    )
    op.create_table(
        "prises",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("medicament_horaire_id", sa.UUID(), nullable=False),
        sa.Column("heure_prevue", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "statut", sa.String(length=32), server_default="en_attente", nullable=False
        ),
        sa.Column("confirmee_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("canal", sa.String(length=16), nullable=True),
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
        sa.ForeignKeyConstraint(
            ["medicament_horaire_id"], ["medicament_horaires.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_prises_heure_prevue"), "prises", ["heure_prevue"], unique=False
    )
    op.create_index(
        op.f("ix_prises_medicament_horaire_id"),
        "prises",
        ["medicament_horaire_id"],
        unique=False,
    )
    op.create_index(op.f("ix_prises_statut"), "prises", ["statut"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_prises_statut"), table_name="prises")
    op.drop_index(op.f("ix_prises_medicament_horaire_id"), table_name="prises")
    op.drop_index(op.f("ix_prises_heure_prevue"), table_name="prises")
    op.drop_table("prises")
    op.drop_index(op.f("ix_medicament_horaires_medicament_id"), table_name="medicament_horaires")
    op.drop_table("medicament_horaires")
    op.drop_index(op.f("ix_medicaments_patient_traitement_id"), table_name="medicaments")
    op.drop_table("medicaments")
    op.drop_index(
        op.f("ix_patient_traitement_attributs_patient_traitement_id"),
        table_name="patient_traitement_attributs",
    )
    op.drop_index(
        op.f("ix_patient_traitement_attributs_code"), table_name="patient_traitement_attributs"
    )
    op.drop_table("patient_traitement_attributs")
    op.drop_constraint(
        "fk_patient_traitements_protocole_id", "patient_traitements", type_="foreignkey"
    )
    op.drop_index(op.f("ix_patient_traitements_statut"), table_name="patient_traitements")
    op.drop_index(op.f("ix_patient_traitements_protocole_id"), table_name="patient_traitements")
    op.drop_column("patient_traitements", "updated_at")
    op.drop_column("patient_traitements", "statut")
    op.drop_column("patient_traitements", "lieu_suivi")
    op.drop_column("patient_traitements", "maladie_libelle")
    op.drop_column("patient_traitements", "date_fin_prevue")
    op.drop_column("patient_traitements", "en_traitement")
    op.drop_column("patient_traitements", "protocole_id")
    op.drop_column("patients", "notifications_discretes")
    op.drop_index(
        op.f("ix_protocole_medicaments_suggeres_protocole_id"),
        table_name="protocole_medicaments_suggeres",
    )
    op.drop_table("protocole_medicaments_suggeres")
    op.drop_index(op.f("ix_protocoles_traitement_maladie_id"), table_name="protocoles_traitement")
    op.drop_table("protocoles_traitement")
    op.drop_table("maladie_configs")
    op.drop_index(op.f("ix_maladies_code"), table_name="maladies")
    op.drop_column("maladies", "updated_at")
    op.drop_column("maladies", "created_at")
    op.drop_column("maladies", "code")

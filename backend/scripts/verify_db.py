"""Vérification rapide connexion Neon + schéma suivi."""

from __future__ import annotations

import asyncio

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from app.core.config import settings
from app.services.catalog_seed_service import ensure_default_maladies
from app.db.session import AsyncSessionLocal


NEW_TABLES = (
    "maladies",
    "maladie_configs",
    "protocoles_traitement",
    "protocole_medicaments_suggeres",
    "patient_traitement_attributs",
    "medicaments",
    "medicament_horaires",
    "prises",
)


async def main() -> None:
    engine = create_async_engine(settings.database_url, pool_pre_ping=True)
    async with engine.connect() as conn:
        rev = await conn.scalar(text("SELECT version_num FROM alembic_version"))
        result = await conn.execute(
            text(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                  AND table_name = ANY(:names)
                ORDER BY table_name
                """
            ),
            {"names": list(NEW_TABLES)},
        )
        table_list = [row[0] for row in result]
        counts: dict[str, int] = {}
        for table in ("maladies", "protocoles_traitement", "medicaments", "prises"):
            if table in table_list:
                counts[table] = await conn.scalar(text(f"SELECT COUNT(*) FROM {table}"))
    await engine.dispose()

    print(f"database: connected (pool_pre_ping ok)")
    print(f"alembic_revision: {rev}")
    print(f"new_tables ({len(table_list)}/{len(NEW_TABLES)}): {', '.join(table_list)}")
    print(f"row_counts_before_seed: {counts}")

    async with AsyncSessionLocal() as session:
        await ensure_default_maladies(session)
        maladies = await session.scalar(text("SELECT COUNT(*) FROM maladies"))
        protocoles = await session.scalar(text("SELECT COUNT(*) FROM protocoles_traitement"))
        suggestions = await session.scalar(
            text("SELECT COUNT(*) FROM protocole_medicaments_suggeres")
        )

    print(f"catalogue_seed: maladies={maladies}, protocoles={protocoles}, suggestions={suggestions}")


if __name__ == "__main__":
    asyncio.run(main())

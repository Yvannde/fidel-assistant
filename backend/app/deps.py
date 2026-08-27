"""Dépendances FastAPI communes (get_current_user, get_db, require_role…)."""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db as _get_db

get_db = _get_db


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    async for session in _get_db():
        yield session

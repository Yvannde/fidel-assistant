"""Enregistrement des tokens push FCM."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import DevicePushToken, User


async def upsert_push_token(
    db: AsyncSession,
    *,
    user: User,
    token: str,
    platform: str = "android",
) -> dict:
    token = token.strip()
    if not token:
        from app.core.exceptions import AppException

        raise AppException(
            "TOKEN_INVALIDE",
            "Le token push est vide.",
            status_code=400,
        )

    plat = (platform or "android").strip().lower() or "android"
    existing = (
        await db.execute(
            select(DevicePushToken).where(
                DevicePushToken.user_id == user.id,
                DevicePushToken.token == token,
            )
        )
    ).scalar_one_or_none()
    now = datetime.now(UTC)
    if existing is not None:
        existing.platform = plat
        existing.updated_at = now
        await db.commit()
        await db.refresh(existing)
        return {"token": existing.token, "platform": existing.platform}

    # Un seul token actif par user+platform : remplace les anciens.
    old = (
        await db.execute(
            select(DevicePushToken).where(
                DevicePushToken.user_id == user.id,
                DevicePushToken.platform == plat,
            )
        )
    ).scalars().all()
    for row in old:
        await db.delete(row)

    row = DevicePushToken(user_id=user.id, token=token, platform=plat)
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return {"token": row.token, "platform": row.platform}


async def tokens_for_users(db: AsyncSession, *, user_ids: list) -> list[str]:
    if not user_ids:
        return []
    rows = (
        await db.execute(
            select(DevicePushToken.token).where(DevicePushToken.user_id.in_(user_ids))
        )
    ).scalars().all()
    return list(rows)

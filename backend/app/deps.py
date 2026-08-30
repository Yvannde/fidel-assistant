"""Dépendances FastAPI communes (get_current_user, get_db, rate-limits…)."""

from collections.abc import AsyncGenerator, Callable, Coroutine
from typing import Annotated, Any
from uuid import UUID

from fastapi import Depends, Header, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppException
from app.core.rate_limit import check_rate_limit
from app.core.security import decode_token
from app.db.session import get_db as _get_db
from app.models import User
from app.services import auth_service

get_db = _get_db

bearer_scheme = HTTPBearer(auto_error=False)


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    async for session in _get_db():
        yield session


def client_ip(
    request: Request,
    x_forwarded_for: Annotated[str | None, Header()] = None,
) -> str | None:
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    if request.client and request.client.host:
        return request.client.host
    return None


def _rate_limit_ip_key(ip: str | None) -> str:
    return ip or "unknown"


async def rate_limit_auth_ip(ip: Annotated[str | None, Depends(client_ip)]) -> None:
    """Limite globale par IP — appliquée à tout le router /auth."""
    if settings.app_env == "test":
        return
    check_rate_limit(
        f"auth:ip:{_rate_limit_ip_key(ip)}",
        max_attempts=settings.auth_ip_max_per_minute,
        window_seconds=60,
        error_code="RATE_LIMITED",
        message="Trop de requêtes d'authentification. Réessaie dans une minute.",
    )


def rate_limit_auth_action(
    action: str,
) -> Callable[..., Coroutine[Any, Any, None]]:
    """Limite stricte par IP pour une action sensible."""

    async def _dep(ip: Annotated[str | None, Depends(client_ip)]) -> None:
        if settings.app_env == "test":
            return
        check_rate_limit(
            f"auth:{action}:{_rate_limit_ip_key(ip)}",
            max_attempts=settings.auth_sensitive_max_attempts,
            window_seconds=settings.auth_sensitive_window_minutes * 60,
            error_code="RATE_LIMITED",
            message=(
                "Trop de tentatives sur cette action. "
                f"Réessaie dans environ {settings.auth_sensitive_window_minutes} minutes."
            ),
        )

    return _dep


async def get_current_user(
    db: Annotated[AsyncSession, Depends(get_db)],
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise AppException("UNAUTHORIZED", "Authentification requise.", status_code=401)
    try:
        payload = decode_token(credentials.credentials)
    except ValueError as exc:
        raise AppException("UNAUTHORIZED", "Jeton invalide ou expiré.", status_code=401) from exc
    if payload.get("type") != "access":
        raise AppException("UNAUTHORIZED", "Jeton invalide.", status_code=401)
    user = await auth_service.get_user_by_id(db, UUID(payload["sub"]))
    if user is None:
        raise AppException("UNAUTHORIZED", "Utilisateur introuvable.", status_code=401)
    return user


async def get_user_from_temp_token(
    db: Annotated[AsyncSession, Depends(get_db)],
    temp_token: str,
) -> User:
    try:
        payload = decode_token(temp_token)
    except ValueError as exc:
        raise AppException(
            "TEMP_TOKEN_INVALID",
            "Jeton temporaire invalide ou expiré.",
            status_code=401,
        ) from exc
    if payload.get("type") != "temp":
        raise AppException("TEMP_TOKEN_INVALID", "Jeton temporaire invalide.", status_code=401)
    user = await auth_service.get_user_by_id(db, UUID(payload["sub"]))
    if user is None:
        raise AppException("TEMP_TOKEN_INVALID", "Jeton temporaire invalide.", status_code=401)
    return user


async def get_user_from_temp_or_access(
    db: Annotated[AsyncSession, Depends(get_db)],
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    temp_token: str | None = None,
) -> User:
    if temp_token:
        return await get_user_from_temp_token(db, temp_token)
    return await get_current_user(db, credentials)

from datetime import UTC, datetime, timedelta
from hashlib import sha256
from secrets import token_urlsafe
from typing import Any
from uuid import UUID

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def hash_otp(code: str) -> str:
    return pwd_context.hash(code)


def verify_otp(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def hash_token(raw: str) -> str:
    return sha256(raw.encode("utf-8")).hexdigest()


def create_access_token(subject: str, extra: dict[str, Any] | None = None) -> str:
    expire = datetime.now(UTC) + timedelta(minutes=settings.access_token_expire_minutes)
    payload: dict[str, Any] = {"sub": subject, "exp": expire, "type": "access"}
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_temp_token(user_id: UUID) -> str:
    expire = datetime.now(UTC) + timedelta(minutes=settings.temp_token_expire_minutes)
    payload = {"sub": str(user_id), "exp": expire, "type": "temp"}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_opaque_refresh_token() -> str:
    return token_urlsafe(48)


def decode_token(token: str) -> dict[str, Any]:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError as exc:
        raise ValueError("token_invalid") from exc


def generate_otp_code() -> str:
    # 6 chiffres, évite 000000 uniquement par hasard — secrets.randbelow
    from secrets import randbelow

    return f"{randbelow(1_000_000):06d}"

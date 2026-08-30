from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppException
from app.core.security import generate_otp_code, hash_otp, verify_otp
from app.models import OtpCode, User
from app.services.email_service import send_otp_email


async def _count_recent_otps(db: AsyncSession, user_id: UUID, otp_type: str) -> int:
    since = datetime.now(UTC) - timedelta(hours=1)
    result = await db.execute(
        select(func.count())
        .select_from(OtpCode)
        .where(
            OtpCode.user_id == user_id,
            OtpCode.type == otp_type,
            OtpCode.created_at >= since,
        )
    )
    return int(result.scalar_one())


async def issue_otp(
    db: AsyncSession,
    *,
    user: User,
    otp_type: str,
    send_to_email: str | None = None,
) -> str:
    if await _count_recent_otps(db, user.id, otp_type) >= settings.otp_resend_max_per_hour:
        raise AppException(
            "RESEND_LIMIT_REACHED",
            "Tu as demandé trop de codes récemment. Attends un peu avant de réessayer.",
            status_code=429,
        )

    code = generate_otp_code()
    otp = OtpCode(
        user_id=user.id,
        code_hash=hash_otp(code),
        type=otp_type,
        expires_at=datetime.now(UTC) + timedelta(minutes=settings.otp_expire_minutes),
        tentatives=0,
    )
    db.add(otp)
    await db.flush()

    await send_otp_email(
        to_email=send_to_email or user.email,
        code=code,
        purpose=otp_type,
    )
    return code


async def verify_user_otp(
    db: AsyncSession,
    *,
    user: User,
    otp_type: str,
    code: str,
) -> None:
    result = await db.execute(
        select(OtpCode)
        .where(
            OtpCode.user_id == user.id,
            OtpCode.type == otp_type,
            OtpCode.used_at.is_(None),
        )
        .order_by(OtpCode.created_at.desc())
        .limit(1)
    )
    otp = result.scalar_one_or_none()
    if otp is None:
        raise AppException(
            "OTP_INVALID",
            "Ce code ne correspond pas. Vérifie les 6 chiffres ou demande un nouveau code.",
            status_code=400,
        )

    expires_at = otp.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=UTC)
    if expires_at < datetime.now(UTC):
        raise AppException(
            "OTP_EXPIRED",
            "Ce code a expiré. Demande un nouveau code par email.",
            status_code=400,
        )

    if otp.tentatives >= settings.otp_max_attempts:
        raise AppException(
            "OTP_MAX_ATTEMPTS",
            "Trop d'essais incorrects. Demande un nouveau code pour continuer.",
            status_code=400,
        )

    if not verify_otp(code, otp.code_hash):
        otp.tentatives += 1
        await db.flush()
        restantes = settings.otp_max_attempts - otp.tentatives
        if restantes <= 0:
            raise AppException(
                "OTP_MAX_ATTEMPTS",
                "Trop d'essais incorrects. Demande un nouveau code pour continuer.",
                status_code=400,
            )
        raise AppException(
            "OTP_INVALID",
            f"Code incorrect. Il te reste {restantes} essai(s).",
            status_code=400,
        )

    otp.used_at = datetime.now(UTC)
    await db.flush()

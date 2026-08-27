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
    background_send: bool = True,
) -> str:
    if await _count_recent_otps(db, user.id, otp_type) >= settings.otp_resend_max_per_hour:
        raise AppException(
            "RESEND_LIMIT_REACHED",
            "Trop de renvois. Réessaie plus tard.",
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

    if background_send:
        await send_otp_email(to_email=user.email, code=code, purpose=otp_type)
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
        raise AppException("OTP_INVALID", "Code invalide.", status_code=400)

    if otp.expires_at < datetime.now(UTC):
        raise AppException(
            "OTP_EXPIRED",
            "Le code a expiré, demande-en un nouveau.",
            status_code=400,
        )

    if otp.tentatives >= settings.otp_max_attempts:
        raise AppException(
            "OTP_MAX_ATTEMPTS",
            "Trop de tentatives. Demande un nouveau code.",
            status_code=400,
        )

    if not verify_otp(code, otp.code_hash):
        otp.tentatives += 1
        await db.flush()
        raise AppException("OTP_INVALID", "Code invalide.", status_code=400)

    otp.used_at = datetime.now(UTC)
    await db.flush()

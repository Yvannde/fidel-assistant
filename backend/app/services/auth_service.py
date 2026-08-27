from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import AppException
from app.core.security import (
    create_access_token,
    create_opaque_refresh_token,
    create_temp_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.models import CguAcceptance, ConsentementSante, Session, User
from app.services import otp_service
from app.services.google_auth_service import verify_google_id_token


def _validate_password(password: str) -> None:
    if len(password) < settings.password_min_length:
        raise AppException(
            "PASSWORD_TOO_WEAK",
            f"Le mot de passe doit faire au moins {settings.password_min_length} caractères.",
            status_code=400,
        )


def _providers_add(current: list | None, provider: str) -> list:
    items = list(current or [])
    if provider not in items:
        items.append(provider)
    return items


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(
        select(User).where(User.email == email.lower(), User.deleted_at.is_(None))
    )
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: UUID) -> User | None:
    result = await db.execute(
        select(User)
        .where(User.id == user_id, User.deleted_at.is_(None))
        .options(
            selectinload(User.cgu_acceptances),
            selectinload(User.consentement_sante),
        )
    )
    return result.scalar_one_or_none()


async def register(db: AsyncSession, *, email: str, langue: str) -> str:
    email_norm = email.lower()
    user = await get_user_by_email(db, email_norm)

    if user and user.email_verified_at is not None:
        raise AppException(
            "EMAIL_ALREADY_VERIFIED",
            "Un compte existe déjà avec cet email. Connecte-toi ou utilise mot de passe oublié.",
            status_code=409,
        )

    if user is None:
        user = User(
            email=email_norm,
            langue=langue,
            auth_providers=["email"],
            onboarding_step=None,
        )
        db.add(user)
        await db.flush()
    else:
        user.langue = langue
        user.auth_providers = _providers_add(user.auth_providers, "email")

    await otp_service.issue_otp(db, user=user, otp_type="inscription")
    await db.commit()
    return "Un code de vérification a été envoyé à ton email."


async def resend_otp(db: AsyncSession, *, email: str, otp_type: str) -> str:
    user = await get_user_by_email(db, email.lower())
    # Réponse neutre si inconnu (anti-énumération)
    if user is None:
        return "Si un compte existe, un nouveau code a été envoyé."

    if otp_type == "inscription" and user.email_verified_at is not None:
        raise AppException(
            "EMAIL_ALREADY_VERIFIED",
            "Cet email est déjà vérifié. Connecte-toi.",
            status_code=409,
        )

    await otp_service.issue_otp(db, user=user, otp_type=otp_type)
    await db.commit()
    return "Si un compte existe, un nouveau code a été envoyé."


async def verify_otp(db: AsyncSession, *, email: str, code: str) -> str:
    user = await get_user_by_email(db, email.lower())
    if user is None:
        raise AppException("OTP_INVALID", "Code invalide.", status_code=400)

    await otp_service.verify_user_otp(db, user=user, otp_type="inscription", code=code)
    user.email_verified_at = datetime.now(UTC)
    await db.commit()
    return create_temp_token(user.id)


async def set_password(db: AsyncSession, *, user: User, password: str) -> str:
    _validate_password(password)
    user.password_hash = hash_password(password)
    user.auth_providers = _providers_add(user.auth_providers, "email")
    await db.commit()
    return "Mot de passe enregistré."


async def accept_cgu(
    db: AsyncSession,
    *,
    user: User,
    version: str,
    ip: str | None,
) -> str:
    if version != settings.cgu_current_version:
        raise AppException(
            "CGU_VERSION_OUTDATED",
            "Cette version des CGU n'est plus valide.",
            status_code=400,
        )
    db.add(CguAcceptance(user_id=user.id, version=version, ip=ip))
    await db.commit()
    return "CGU acceptées."


async def accept_consentement_sante(db: AsyncSession, *, user: User) -> str:
    existing = await db.execute(
        select(ConsentementSante).where(ConsentementSante.user_id == user.id)
    )
    if existing.scalar_one_or_none() is None:
        db.add(ConsentementSante(user_id=user.id))
        if user.onboarding_step is None:
            user.onboarding_step = "choix_role"
        await db.commit()
    return "Consentement santé enregistré."


async def _create_session(db: AsyncSession, user: User, device_info: str | None = None) -> str:
    raw = create_opaque_refresh_token()
    db.add(
        Session(
            user_id=user.id,
            refresh_token_hash=hash_token(raw),
            device_info=device_info,
        )
    )
    await db.flush()
    return raw


async def login(db: AsyncSession, *, email: str, password: str) -> dict:
    user = await get_user_by_email(db, email.lower())
    if user is None or not user.password_hash:
        raise AppException(
            "INVALID_CREDENTIALS",
            "Email ou mot de passe incorrect.",
            status_code=401,
        )
    if user.email_verified_at is None:
        raise AppException(
            "EMAIL_NOT_VERIFIED",
            "Email non vérifié. Valide d'abord ton code OTP.",
            status_code=403,
        )
    if not verify_password(password, user.password_hash):
        raise AppException(
            "INVALID_CREDENTIALS",
            "Email ou mot de passe incorrect.",
            status_code=401,
        )

    refresh = await _create_session(db, user)
    await db.commit()
    return {
        "access_token": create_access_token(str(user.id)),
        "refresh_token": refresh,
        "role": user.role,
        "onboarding_step": user.onboarding_step,
    }


async def google_auth(
    db: AsyncSession,
    *,
    id_token_str: str,
    langue: str,
    fuseau_horaire: str | None,
) -> dict:
    payload = verify_google_id_token(id_token_str)
    google_sub = payload["sub"]
    email = str(payload["email"]).lower()

    result = await db.execute(
        select(User)
        .where(User.deleted_at.is_(None))
        .where(or_(User.google_sub == google_sub, User.email == email))
        .options(
            selectinload(User.cgu_acceptances),
            selectinload(User.consentement_sante),
        )
    )
    user = result.scalars().first()
    is_new = False

    if user is None:
        is_new = True
        user = User(
            email=email,
            google_sub=google_sub,
            auth_providers=["google"],
            email_verified_at=datetime.now(UTC),
            langue=langue,
            fuseau_horaire=fuseau_horaire,
            onboarding_step="choix_role",
        )
        db.add(user)
        await db.flush()
    else:
        if user.google_sub is None:
            user.google_sub = google_sub
        user.auth_providers = _providers_add(user.auth_providers, "google")
        if user.email_verified_at is None:
            user.email_verified_at = datetime.now(UTC)
        if langue:
            user.langue = langue
        if fuseau_horaire:
            user.fuseau_horaire = fuseau_horaire
        await db.flush()
        # reload relations
        user = await get_user_by_id(db, user.id)
        assert user is not None

    needs_cgu = not any(c.version == settings.cgu_current_version for c in user.cgu_acceptances)
    needs_consent = user.consentement_sante is None

    refresh = await _create_session(db, user)
    await db.commit()

    return {
        "access_token": create_access_token(str(user.id)),
        "refresh_token": refresh,
        "role": user.role,
        "onboarding_step": user.onboarding_step,
        "is_new_user": is_new,
        "needs_cgu": needs_cgu,
        "needs_consentement_sante": needs_consent,
    }


async def refresh_access(db: AsyncSession, *, refresh_token: str) -> str:
    token_hash = hash_token(refresh_token)
    result = await db.execute(
        select(Session).where(
            Session.refresh_token_hash == token_hash,
            Session.revoked_at.is_(None),
        )
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise AppException(
            "REFRESH_TOKEN_INVALID_OR_EXPIRED",
            "Session expirée. Reconnecte-toi.",
            status_code=401,
        )
    user = await get_user_by_id(db, session.user_id)
    if user is None:
        raise AppException(
            "REFRESH_TOKEN_INVALID_OR_EXPIRED",
            "Session expirée. Reconnecte-toi.",
            status_code=401,
        )
    return create_access_token(str(user.id))


async def logout(db: AsyncSession, *, user_id: UUID, refresh_token: str) -> str:
    token_hash = hash_token(refresh_token)
    result = await db.execute(
        select(Session).where(
            Session.refresh_token_hash == token_hash,
            Session.user_id == user_id,
            Session.revoked_at.is_(None),
        )
    )
    session = result.scalar_one_or_none()
    if session is not None:
        session.revoked_at = datetime.now(UTC)
        await db.commit()
    return "Déconnexion réussie."


async def forgot_password(db: AsyncSession, *, email: str) -> str:
    user = await get_user_by_email(db, email.lower())
    if user and user.email_verified_at is not None:
        await otp_service.issue_otp(db, user=user, otp_type="reset_password")
        await db.commit()
    return "Si un compte existe, un code a été envoyé."


async def reset_password(db: AsyncSession, *, email: str, code: str, nouveau_password: str) -> str:
    _validate_password(nouveau_password)
    user = await get_user_by_email(db, email.lower())
    if user is None:
        raise AppException("OTP_INVALID", "Code invalide.", status_code=400)
    await otp_service.verify_user_otp(db, user=user, otp_type="reset_password", code=code)
    user.password_hash = hash_password(nouveau_password)
    user.auth_providers = _providers_add(user.auth_providers, "email")
    await db.commit()
    return "Mot de passe mis à jour."

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import AppException
from app.core.rate_limit import check_rate_limit, clear_rate_limit
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
            selectinload(User.patient),
            selectinload(User.aidant_relations),
        )
    )
    return result.scalar_one_or_none()


async def register(
    db: AsyncSession,
    *,
    email: str,
    langue: str,
    fuseau_horaire: str | None = None,
) -> str:
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
            fuseau_horaire=fuseau_horaire,
            auth_providers=["email"],
            onboarding_step=None,
        )
        db.add(user)
        await db.flush()
    else:
        user.langue = langue
        if fuseau_horaire:
            user.fuseau_horaire = fuseau_horaire
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
            user.onboarding_step = "infos"
        await db.commit()
    return "Consentement santé enregistré."


async def _create_session(
    db: AsyncSession, user: User, device_info: str | None = None
) -> tuple[str, UUID]:
    raw = create_opaque_refresh_token()
    session = Session(
        user_id=user.id,
        refresh_token_hash=hash_token(raw),
        device_info=device_info,
    )
    db.add(session)
    await db.flush()
    return raw, session.id


def _token_extras(*, onboarding_step: str | None, user: User, session_id: UUID) -> dict:
    from app.services.onboarding_service import capabilities

    return {
        "expires_in": settings.access_token_expire_minutes * 60,
        "session_id": session_id,
        "onboarding_step": onboarding_step,
        **capabilities(user),
    }


async def login(
    db: AsyncSession,
    *,
    email: str,
    password: str,
    device_info: str | None = None,
) -> dict:
    email_norm = email.lower()
    rate_key = f"login:{email_norm}"
    check_rate_limit(
        rate_key,
        max_attempts=settings.login_max_attempts,
        window_seconds=settings.login_window_minutes * 60,
        error_code="LOGIN_RATE_LIMITED",
        message=(
            "Trop de tentatives de connexion. "
            f"Attends environ {settings.login_window_minutes} minutes "
            "ou réinitialise ton mot de passe."
        ),
    )

    user = await get_user_by_email(db, email_norm)
    if user is None or not user.password_hash:
        raise AppException(
            "INVALID_CREDENTIALS",
            "Email ou mot de passe incorrect.",
            status_code=401,
        )
    if user.email_verified_at is None:
        raise AppException(
            "EMAIL_NOT_VERIFIED",
            "Ton email n'est pas encore vérifié. Entre le code reçu par email pour continuer.",
            status_code=403,
        )
    if not verify_password(password, user.password_hash):
        raise AppException(
            "INVALID_CREDENTIALS",
            "Email ou mot de passe incorrect.",
            status_code=401,
        )

    clear_rate_limit(rate_key)
    user = await get_user_by_id(db, user.id)
    assert user is not None
    refresh, session_id = await _create_session(db, user, device_info=device_info)
    await db.commit()
    return {
        "access_token": create_access_token(str(user.id)),
        "refresh_token": refresh,
        **_token_extras(
            onboarding_step=user.onboarding_step, user=user, session_id=session_id
        ),
    }


async def google_auth(
    db: AsyncSession,
    *,
    id_token_str: str,
    langue: str,
    fuseau_horaire: str | None,
    device_info: str | None = None,
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
            onboarding_step="infos",
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

    user = await get_user_by_id(db, user.id)
    assert user is not None

    needs_cgu = not any(c.version == settings.cgu_current_version for c in user.cgu_acceptances)
    needs_consent = user.consentement_sante is None

    refresh, session_id = await _create_session(db, user, device_info=device_info)
    await db.commit()

    return {
        "access_token": create_access_token(str(user.id)),
        "refresh_token": refresh,
        "is_new_user": is_new,
        "needs_cgu": needs_cgu,
        "needs_consentement_sante": needs_consent,
        **_token_extras(
            onboarding_step=user.onboarding_step, user=user, session_id=session_id
        ),
    }


async def refresh_access(db: AsyncSession, *, refresh_token: str) -> dict:
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
            "Ta session a expiré. Reconnecte-toi pour continuer.",
            status_code=401,
        )
    user = await get_user_by_id(db, session.user_id)
    if user is None:
        raise AppException(
            "REFRESH_TOKEN_INVALID_OR_EXPIRED",
            "Ta session a expiré. Reconnecte-toi pour continuer.",
            status_code=401,
        )
    return {
        "access_token": create_access_token(str(user.id)),
        "expires_in": settings.access_token_expire_minutes * 60,
    }


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


def build_me(user: User) -> dict:
    from app.services.onboarding_service import capabilities

    needs_cgu = not any(
        c.version == settings.cgu_current_version for c in (user.cgu_acceptances or [])
    )
    return {
        "id": user.id,
        "email": user.email,
        "phone": user.phone,
        "nom_complet": user.nom_complet,
        "date_naissance": user.date_naissance,
        "sexe": user.sexe,
        "localisation": user.localisation,
        "onboarding_step": user.onboarding_step,
        "langue": user.langue,
        "fuseau_horaire": user.fuseau_horaire,
        "auth_providers": list(user.auth_providers or []),
        "email_verified_at": user.email_verified_at,
        "has_password": bool(user.password_hash),
        "needs_cgu": needs_cgu,
        "needs_consentement_sante": user.consentement_sante is None,
        "pending_email": user.pending_email,
        **capabilities(user),
    }


async def update_me(
    db: AsyncSession,
    *,
    user: User,
    langue: str | None,
    fuseau_horaire: str | None,
    phone: str | None,
) -> dict:
    if langue is not None:
        user.langue = langue
    if fuseau_horaire is not None:
        user.fuseau_horaire = fuseau_horaire
    if phone is not None:
        user.phone = phone
    await db.commit()
    refreshed = await get_user_by_id(db, user.id)
    assert refreshed is not None
    return build_me(refreshed)


async def change_password(
    db: AsyncSession,
    *,
    user: User,
    current_password: str | None,
    nouveau_password: str,
) -> str:
    _validate_password(nouveau_password)
    if user.password_hash:
        if not current_password or not verify_password(current_password, user.password_hash):
            raise AppException(
                "INVALID_CREDENTIALS",
                "Mot de passe actuel incorrect.",
                status_code=401,
            )
    user.password_hash = hash_password(nouveau_password)
    user.auth_providers = _providers_add(user.auth_providers, "email")
    await db.commit()
    return "Mot de passe mis à jour."


async def link_google(db: AsyncSession, *, user: User, id_token_str: str) -> dict:
    payload = verify_google_id_token(id_token_str)
    google_sub = payload["sub"]
    email = str(payload["email"]).lower()

    if user.google_sub and user.google_sub != google_sub:
        raise AppException(
            "GOOGLE_ALREADY_LINKED",
            "Un autre compte Google est déjà lié.",
            status_code=409,
        )

    other = await db.execute(
        select(User).where(
            User.google_sub == google_sub,
            User.id != user.id,
            User.deleted_at.is_(None),
        )
    )
    if other.scalar_one_or_none() is not None:
        raise AppException(
            "GOOGLE_ALREADY_LINKED",
            "Ce compte Google est déjà utilisé.",
            status_code=409,
        )

    if email != user.email and user.email_verified_at:
        # Lien autorisé même si emails diffèrent, mais on garde l'email du compte
        pass

    user.google_sub = google_sub
    user.auth_providers = _providers_add(user.auth_providers, "google")
    if user.email_verified_at is None:
        user.email_verified_at = datetime.now(UTC)
    await db.commit()
    return {
        "message": "Compte Google lié.",
        "auth_providers": list(user.auth_providers or []),
    }


async def request_email_change(db: AsyncSession, *, user: User, nouvel_email: str) -> str:
    new_email = nouvel_email.lower()
    if new_email == user.email:
        return "C'est déjà ton email actuel."

    existing = await get_user_by_email(db, new_email)
    if existing is not None:
        raise AppException(
            "EMAIL_ALREADY_VERIFIED",
            "Cet email est déjà utilisé par un autre compte.",
            status_code=409,
        )

    user.pending_email = new_email
    await otp_service.issue_otp(
        db, user=user, otp_type="change_email", send_to_email=new_email
    )
    await db.commit()
    return "Un code a été envoyé à la nouvelle adresse email."


async def confirm_email_change(
    db: AsyncSession, *, user: User, nouvel_email: str, code: str
) -> dict:
    new_email = nouvel_email.lower()
    if user.pending_email != new_email:
        raise AppException(
            "OTP_INVALID",
            "Aucune demande de changement pour cet email.",
            status_code=400,
        )
    await otp_service.verify_user_otp(db, user=user, otp_type="change_email", code=code)
    existing = await get_user_by_email(db, new_email)
    if existing is not None and existing.id != user.id:
        raise AppException(
            "EMAIL_ALREADY_VERIFIED",
            "Cet email est déjà utilisé par un autre compte.",
            status_code=409,
        )
    user.email = new_email
    user.pending_email = None
    user.email_verified_at = datetime.now(UTC)
    await db.commit()
    return {"message": "Email mis à jour.", "email": user.email}


async def list_sessions(
    db: AsyncSession, *, user_id: UUID, current_session_id: UUID | None = None
) -> list[dict]:
    result = await db.execute(
        select(Session)
        .where(Session.user_id == user_id, Session.revoked_at.is_(None))
        .order_by(Session.created_at.desc())
    )
    rows = list(result.scalars().all())
    return [
        {
            "id": s.id,
            "device_info": s.device_info,
            "created_at": s.created_at,
            "revoked_at": s.revoked_at,
            "is_current": current_session_id is not None and s.id == current_session_id,
        }
        for s in rows
    ]


async def logout_all(db: AsyncSession, *, user_id: UUID) -> str:
    result = await db.execute(
        select(Session).where(Session.user_id == user_id, Session.revoked_at.is_(None))
    )
    now = datetime.now(UTC)
    for session in result.scalars().all():
        session.revoked_at = now
    await db.commit()
    return "Toutes les sessions ont été révoquées."


async def revoke_session(db: AsyncSession, *, user_id: UUID, session_id: UUID) -> str:
    result = await db.execute(
        select(Session).where(
            Session.id == session_id,
            Session.user_id == user_id,
            Session.revoked_at.is_(None),
        )
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise AppException("SESSION_NOT_FOUND", "Session introuvable.", status_code=404)
    session.revoked_at = datetime.now(UTC)
    await db.commit()
    return "Session révoquée."


async def delete_account(db: AsyncSession, *, user: User, password: str | None) -> str:
    if user.password_hash:
        if not password or not verify_password(password, user.password_hash):
            raise AppException(
                "INVALID_CREDENTIALS",
                "Mot de passe incorrect.",
                status_code=401,
            )
    result = await db.execute(
        select(Session).where(Session.user_id == user.id, Session.revoked_at.is_(None))
    )
    now = datetime.now(UTC)
    for session in result.scalars().all():
        session.revoked_at = now
    user.deleted_at = now
    user.email = f"deleted+{user.id}@invalid.local"
    user.google_sub = None
    user.pending_email = None
    await db.commit()
    return "Compte supprimé."

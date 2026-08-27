from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import (
    bearer_scheme,
    client_ip,
    get_current_user,
    get_db,
    get_user_from_temp_or_access,
    get_user_from_temp_token,
)
from app.models import User
from app.schemas.auth import (
    AcceptCguIn,
    AcceptConsentementIn,
    AccessTokenOut,
    ForgotPasswordIn,
    GoogleAuthIn,
    GoogleAuthOut,
    LoginIn,
    LogoutIn,
    MessageOut,
    RefreshIn,
    RegisterIn,
    ResendOtpIn,
    ResetPasswordIn,
    SetPasswordIn,
    TempTokenOut,
    TokenPairOut,
    VerifyOtpIn,
)
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=MessageOut)
async def register(body: RegisterIn, db: Annotated[AsyncSession, Depends(get_db)]) -> MessageOut:
    message = await auth_service.register(db, email=body.email, langue=body.langue)
    return MessageOut(message=message)


@router.post("/resend-otp", response_model=MessageOut)
async def resend_otp(body: ResendOtpIn, db: Annotated[AsyncSession, Depends(get_db)]) -> MessageOut:
    message = await auth_service.resend_otp(db, email=body.email, otp_type=body.type)
    return MessageOut(message=message)


@router.post("/verify-otp", response_model=TempTokenOut)
async def verify_otp(
    body: VerifyOtpIn, db: Annotated[AsyncSession, Depends(get_db)]
) -> TempTokenOut:
    token = await auth_service.verify_otp(db, email=body.email, code=body.code)
    return TempTokenOut(temp_token=token)


@router.post("/set-password", response_model=MessageOut)
async def set_password(
    body: SetPasswordIn,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MessageOut:
    user = await get_user_from_temp_token(db, body.temp_token)
    message = await auth_service.set_password(db, user=user, password=body.password)
    return MessageOut(message=message)


@router.post("/accept-cgu", response_model=MessageOut)
async def accept_cgu(
    body: AcceptCguIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    ip: Annotated[str | None, Depends(client_ip)],
) -> MessageOut:
    user = await get_user_from_temp_or_access(db, credentials, body.temp_token)
    message = await auth_service.accept_cgu(db, user=user, version=body.version, ip=ip)
    return MessageOut(message=message)


@router.post("/accept-consentement-sante", response_model=MessageOut)
async def accept_consentement_sante(
    body: AcceptConsentementIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> MessageOut:
    user = await get_user_from_temp_or_access(db, credentials, body.temp_token)
    message = await auth_service.accept_consentement_sante(db, user=user)
    return MessageOut(message=message)


@router.post("/login", response_model=TokenPairOut)
async def login(body: LoginIn, db: Annotated[AsyncSession, Depends(get_db)]) -> TokenPairOut:
    data = await auth_service.login(db, email=body.email, password=body.password)
    return TokenPairOut(**data)


@router.post("/google", response_model=GoogleAuthOut)
async def google_login(
    body: GoogleAuthIn, db: Annotated[AsyncSession, Depends(get_db)]
) -> GoogleAuthOut:
    data = await auth_service.google_auth(
        db,
        id_token_str=body.id_token,
        langue=body.langue,
        fuseau_horaire=body.fuseau_horaire,
    )
    return GoogleAuthOut(**data)


@router.post("/refresh", response_model=AccessTokenOut)
async def refresh(body: RefreshIn, db: Annotated[AsyncSession, Depends(get_db)]) -> AccessTokenOut:
    access = await auth_service.refresh_access(db, refresh_token=body.refresh_token)
    return AccessTokenOut(access_token=access)


@router.post("/logout", response_model=MessageOut)
async def logout(
    body: LogoutIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    message = await auth_service.logout(db, user_id=user.id, refresh_token=body.refresh_token)
    return MessageOut(message=message)


@router.post("/forgot-password", response_model=MessageOut)
async def forgot_password(
    body: ForgotPasswordIn, db: Annotated[AsyncSession, Depends(get_db)]
) -> MessageOut:
    message = await auth_service.forgot_password(db, email=body.email)
    return MessageOut(message=message)


@router.post("/reset-password", response_model=MessageOut)
async def reset_password(
    body: ResetPasswordIn, db: Annotated[AsyncSession, Depends(get_db)]
) -> MessageOut:
    message = await auth_service.reset_password(
        db,
        email=body.email,
        code=body.code,
        nouveau_password=body.nouveau_password,
    )
    return MessageOut(message=message)

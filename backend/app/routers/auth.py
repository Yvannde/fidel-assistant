from typing import Annotated
from uuid import UUID

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
    rate_limit_auth_action,
    rate_limit_auth_ip,
)
from app.models import User
from app.schemas.auth import (
    AcceptCguIn,
    AcceptConsentementIn,
    AccessTokenOut,
    ChangePasswordIn,
    ConfirmEmailChangeIn,
    DeleteAccountIn,
    EmailChangeOut,
    ForgotPasswordIn,
    GoogleAuthIn,
    GoogleAuthOut,
    LinkGoogleIn,
    LinkGoogleOut,
    LoginIn,
    LogoutIn,
    MeOut,
    MessageOut,
    RefreshIn,
    RegisterIn,
    RequestEmailChangeIn,
    ResendOtpIn,
    ResetPasswordIn,
    SessionOut,
    SetPasswordIn,
    TempTokenOut,
    TokenPairOut,
    UpdateMeIn,
    VerifyOtpIn,
)
from app.services import auth_service

router = APIRouter(
    prefix="/auth",
    tags=["auth"],
    dependencies=[Depends(rate_limit_auth_ip)],
)

_rl_register = Depends(rate_limit_auth_action("register"))
_rl_resend = Depends(rate_limit_auth_action("resend_otp"))
_rl_verify = Depends(rate_limit_auth_action("verify_otp"))
_rl_set_password = Depends(rate_limit_auth_action("set_password"))
_rl_login = Depends(rate_limit_auth_action("login"))
_rl_google = Depends(rate_limit_auth_action("google"))
_rl_refresh = Depends(rate_limit_auth_action("refresh"))
_rl_forgot = Depends(rate_limit_auth_action("forgot_password"))
_rl_reset = Depends(rate_limit_auth_action("reset_password"))
_rl_change_pw = Depends(rate_limit_auth_action("change_password"))
_rl_link_google = Depends(rate_limit_auth_action("link_google"))
_rl_email_change = Depends(rate_limit_auth_action("email_change"))
_rl_delete = Depends(rate_limit_auth_action("delete_account"))


@router.post("/register", response_model=MessageOut, dependencies=[_rl_register])
async def register(body: RegisterIn, db: Annotated[AsyncSession, Depends(get_db)]) -> MessageOut:
    message = await auth_service.register(
        db,
        email=body.email,
        langue=body.langue,
        fuseau_horaire=body.fuseau_horaire,
    )
    return MessageOut(message=message)


@router.post("/resend-otp", response_model=MessageOut, dependencies=[_rl_resend])
async def resend_otp(body: ResendOtpIn, db: Annotated[AsyncSession, Depends(get_db)]) -> MessageOut:
    message = await auth_service.resend_otp(db, email=body.email, otp_type=body.type)
    return MessageOut(message=message)


@router.post("/verify-otp", response_model=TempTokenOut, dependencies=[_rl_verify])
async def verify_otp(
    body: VerifyOtpIn, db: Annotated[AsyncSession, Depends(get_db)]
) -> TempTokenOut:
    token = await auth_service.verify_otp(db, email=body.email, code=body.code)
    return TempTokenOut(temp_token=token)


@router.post("/set-password", response_model=MessageOut, dependencies=[_rl_set_password])
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


@router.post("/login", response_model=TokenPairOut, dependencies=[_rl_login])
async def login(body: LoginIn, db: Annotated[AsyncSession, Depends(get_db)]) -> TokenPairOut:
    data = await auth_service.login(
        db,
        email=body.email,
        password=body.password,
        device_info=body.device_info,
    )
    return TokenPairOut(**data)


@router.post("/google", response_model=GoogleAuthOut, dependencies=[_rl_google])
async def google_login(
    body: GoogleAuthIn, db: Annotated[AsyncSession, Depends(get_db)]
) -> GoogleAuthOut:
    data = await auth_service.google_auth(
        db,
        id_token_str=body.id_token,
        langue=body.langue,
        fuseau_horaire=body.fuseau_horaire,
        device_info=body.device_info,
    )
    return GoogleAuthOut(**data)


@router.post("/refresh", response_model=AccessTokenOut, dependencies=[_rl_refresh])
async def refresh(body: RefreshIn, db: Annotated[AsyncSession, Depends(get_db)]) -> AccessTokenOut:
    data = await auth_service.refresh_access(db, refresh_token=body.refresh_token)
    return AccessTokenOut(**data)


@router.post("/logout", response_model=MessageOut)
async def logout(
    body: LogoutIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    message = await auth_service.logout(db, user_id=user.id, refresh_token=body.refresh_token)
    return MessageOut(message=message)


@router.post("/forgot-password", response_model=MessageOut, dependencies=[_rl_forgot])
async def forgot_password(
    body: ForgotPasswordIn, db: Annotated[AsyncSession, Depends(get_db)]
) -> MessageOut:
    message = await auth_service.forgot_password(db, email=body.email)
    return MessageOut(message=message)


@router.post("/reset-password", response_model=MessageOut, dependencies=[_rl_reset])
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


@router.get("/me", response_model=MeOut)
async def me(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MeOut:
    refreshed = await auth_service.get_user_by_id(db, user.id)
    assert refreshed is not None
    return MeOut(**auth_service.build_me(refreshed))


@router.patch("/me", response_model=MeOut)
async def update_me(
    body: UpdateMeIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MeOut:
    data = await auth_service.update_me(
        db,
        user=user,
        langue=body.langue,
        fuseau_horaire=body.fuseau_horaire,
        phone=body.phone,
    )
    return MeOut(**data)


@router.post("/change-password", response_model=MessageOut, dependencies=[_rl_change_pw])
async def change_password(
    body: ChangePasswordIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    message = await auth_service.change_password(
        db,
        user=user,
        current_password=body.current_password,
        nouveau_password=body.nouveau_password,
    )
    return MessageOut(message=message)


@router.post("/link-google", response_model=LinkGoogleOut, dependencies=[_rl_link_google])
async def link_google(
    body: LinkGoogleIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> LinkGoogleOut:
    data = await auth_service.link_google(db, user=user, id_token_str=body.id_token)
    return LinkGoogleOut(**data)


@router.post(
    "/request-email-change",
    response_model=MessageOut,
    dependencies=[_rl_email_change],
)
async def request_email_change(
    body: RequestEmailChangeIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    message = await auth_service.request_email_change(db, user=user, nouvel_email=body.nouvel_email)
    return MessageOut(message=message)


@router.post(
    "/confirm-email-change",
    response_model=EmailChangeOut,
    dependencies=[_rl_email_change],
)
async def confirm_email_change(
    body: ConfirmEmailChangeIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> EmailChangeOut:
    data = await auth_service.confirm_email_change(
        db,
        user=user,
        nouvel_email=body.nouvel_email,
        code=body.code,
    )
    return EmailChangeOut(**data)


@router.get("/sessions", response_model=list[SessionOut])
async def sessions(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    current_session_id: UUID | None = None,
) -> list[SessionOut]:
    rows = await auth_service.list_sessions(
        db, user_id=user.id, current_session_id=current_session_id
    )
    return [SessionOut(**row) for row in rows]


@router.post("/logout-all", response_model=MessageOut)
async def logout_all(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    message = await auth_service.logout_all(db, user_id=user.id)
    return MessageOut(message=message)


@router.delete("/sessions/{session_id}", response_model=MessageOut)
async def revoke_session(
    session_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    message = await auth_service.revoke_session(db, user_id=user.id, session_id=session_id)
    return MessageOut(message=message)


@router.delete("/me", response_model=MessageOut, dependencies=[_rl_delete])
async def delete_me(
    body: DeleteAccountIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    message = await auth_service.delete_account(db, user=user, password=body.password)
    return MessageOut(message=message)

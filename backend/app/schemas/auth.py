from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class MessageOut(BaseModel):
    message: str


class RegisterIn(BaseModel):
    email: EmailStr
    langue: str = Field(min_length=2, max_length=16, examples=["fr"])
    fuseau_horaire: str | None = Field(default=None, max_length=64)


class ResendOtpIn(BaseModel):
    email: EmailStr
    type: str = Field(pattern="^(inscription|reset_password|change_email)$")


class VerifyOtpIn(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, examples=["123456"])


class TempTokenOut(BaseModel):
    temp_token: str


class SetPasswordIn(BaseModel):
    temp_token: str
    password: str = Field(min_length=8)


class AcceptCguIn(BaseModel):
    version: str = Field(examples=["v1.0"])
    temp_token: str | None = None


class AcceptConsentementIn(BaseModel):
    temp_token: str | None = None


class LoginIn(BaseModel):
    email: EmailStr
    password: str
    device_info: str | None = None


class TokenPairOut(BaseModel):
    access_token: str
    refresh_token: str
    role: str | None = None
    onboarding_step: str | None = None


class GoogleAuthIn(BaseModel):
    id_token: str
    langue: str = Field(min_length=2, max_length=16)
    fuseau_horaire: str | None = None
    device_info: str | None = None


class GoogleAuthOut(TokenPairOut):
    is_new_user: bool
    needs_cgu: bool
    needs_consentement_sante: bool


class RefreshIn(BaseModel):
    refresh_token: str


class AccessTokenOut(BaseModel):
    access_token: str


class LogoutIn(BaseModel):
    refresh_token: str


class ForgotPasswordIn(BaseModel):
    email: EmailStr


class ResetPasswordIn(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6)
    nouveau_password: str = Field(min_length=8)


class MeOut(BaseModel):
    id: UUID
    email: EmailStr
    phone: str | None
    role: str | None
    onboarding_step: str | None
    langue: str | None
    fuseau_horaire: str | None
    auth_providers: list[str]
    email_verified_at: datetime | None
    has_password: bool
    needs_cgu: bool
    needs_consentement_sante: bool
    pending_email: str | None = None


class UpdateMeIn(BaseModel):
    langue: str | None = Field(default=None, min_length=2, max_length=16)
    fuseau_horaire: str | None = Field(default=None, max_length=64)
    phone: str | None = Field(default=None, max_length=32)


class ChangePasswordIn(BaseModel):
    current_password: str | None = None
    nouveau_password: str = Field(min_length=8)


class LinkGoogleIn(BaseModel):
    id_token: str


class LinkGoogleOut(BaseModel):
    message: str
    auth_providers: list[str]


class RequestEmailChangeIn(BaseModel):
    nouvel_email: EmailStr


class ConfirmEmailChangeIn(BaseModel):
    nouvel_email: EmailStr
    code: str = Field(min_length=6, max_length=6)


class EmailChangeOut(BaseModel):
    message: str
    email: EmailStr


class SessionOut(BaseModel):
    id: UUID
    device_info: str | None
    created_at: datetime
    revoked_at: datetime | None = None


class DeleteAccountIn(BaseModel):
    password: str | None = None

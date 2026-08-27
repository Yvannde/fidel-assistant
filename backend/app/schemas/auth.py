from pydantic import BaseModel, EmailStr, Field


class MessageOut(BaseModel):
    message: str


class RegisterIn(BaseModel):
    email: EmailStr
    langue: str = Field(min_length=2, max_length=16, examples=["fr"])


class ResendOtpIn(BaseModel):
    email: EmailStr
    type: str = Field(pattern="^(inscription|reset_password)$")


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


class TokenPairOut(BaseModel):
    access_token: str
    refresh_token: str
    role: str | None = None
    onboarding_step: str | None = None


class GoogleAuthIn(BaseModel):
    id_token: str
    langue: str = Field(min_length=2, max_length=16)
    fuseau_horaire: str | None = None


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

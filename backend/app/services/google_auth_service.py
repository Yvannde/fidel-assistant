from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from app.core.config import settings
from app.core.exceptions import AppException


def verify_google_id_token(token: str) -> dict:
    audiences = settings.google_client_ids
    if not audiences:
        raise AppException(
            "GOOGLE_TOKEN_INVALID",
            "Google Sign-In n'est pas configuré sur le serveur.",
            status_code=503,
        )

    try:
        payload = id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            audience=audiences,
        )
    except ValueError as exc:
        msg = str(exc).lower()
        if "audience" in msg:
            raise AppException(
                "GOOGLE_AUD_MISMATCH",
                "Ce jeton Google n'est pas destiné à cette application.",
                status_code=401,
            ) from exc
        raise AppException(
            "GOOGLE_TOKEN_INVALID",
            "Jeton Google invalide ou expiré.",
            status_code=401,
        ) from exc

    if not payload.get("email_verified"):
        raise AppException(
            "GOOGLE_EMAIL_NOT_VERIFIED",
            "L'email Google n'est pas vérifié.",
            status_code=400,
        )

    if not payload.get("sub") or not payload.get("email"):
        raise AppException(
            "GOOGLE_TOKEN_INVALID",
            "Jeton Google incomplet.",
            status_code=401,
        )

    return payload

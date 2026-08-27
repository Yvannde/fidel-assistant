import asyncio
import logging

import resend

from app.core.config import settings

logger = logging.getLogger(__name__)

_PURPOSE_LABELS = {
    "inscription": "vérification d'inscription",
    "reset_password": "réinitialisation du mot de passe",
    "change_email": "changement d'email",
}


def _otp_html(*, code: str, purpose: str, minutes: int) -> str:
    label = _PURPOSE_LABELS.get(purpose, purpose)
    return f"""\
<!DOCTYPE html>
<html>
  <body style="font-family: sans-serif; line-height: 1.5; color: #111;">
    <p>Bonjour,</p>
    <p>Voici ton code pour <strong>{label}</strong> sur {settings.app_name} :</p>
    <p style="font-size: 28px; letter-spacing: 6px; font-weight: bold;">{code}</p>
    <p>Ce code expire dans {minutes} minutes.
       Si tu n'as pas fait cette demande, ignore cet email.</p>
    <p>— L'équipe {settings.app_name}</p>
  </body>
</html>
"""


def _otp_text(*, code: str, purpose: str, minutes: int) -> str:
    label = _PURPOSE_LABELS.get(purpose, purpose)
    return (
        f"Ton code {settings.app_name} ({label}) : {code}\n"
        f"Expire dans {minutes} minutes.\n"
    )


def _send_via_resend(*, to_email: str, subject: str, text: str, html: str) -> str:
    resend.api_key = settings.resend_api_key
    result = resend.Emails.send(
        {
            "from": settings.email_from,
            "to": [to_email],
            "subject": subject,
            "text": text,
            "html": html,
        }
    )
    return str(result.get("id", ""))


async def send_otp_email(*, to_email: str, code: str, purpose: str) -> None:
    """Envoie l'OTP via Resend. Sans clé API : log en console (dev only)."""
    label = _PURPOSE_LABELS.get(purpose, purpose)
    subject = f"[{settings.app_name}] Code {label}"
    text = _otp_text(code=code, purpose=purpose, minutes=settings.otp_expire_minutes)
    html = _otp_html(code=code, purpose=purpose, minutes=settings.otp_expire_minutes)

    if not settings.resend_api_key:
        logger.warning(
            "RESEND_API_KEY manquant — OTP %s pour %s : %s (dev only)",
            purpose,
            to_email,
            code,
        )
        return

    try:
        email_id = await asyncio.to_thread(
            _send_via_resend,
            to_email=to_email,
            subject=subject,
            text=text,
            html=html,
        )
        logger.info("OTP %s envoyé à %s via Resend (id=%s)", purpose, to_email, email_id)
    except Exception:
        logger.exception("Échec envoi OTP Resend vers %s", to_email)
        raise

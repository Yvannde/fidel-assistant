import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


async def send_otp_email(*, to_email: str, code: str, purpose: str) -> None:
    """Envoie l'OTP par email. En dev sans SMTP : log uniquement (jamais en prod réelle)."""
    subject = f"[{settings.app_name}] Code {purpose}"
    if not settings.smtp_host:
        logger.warning(
            "SMTP non configuré — OTP %s pour %s : %s (dev only)",
            purpose,
            to_email,
            code,
        )
        return

    # Envoi SMTP réel à brancher (aiosmtplib / etc.) — placeholder pour V1
    logger.info("Envoi OTP %s vers %s (SMTP %s)", purpose, to_email, settings.smtp_host)
    _ = subject

"""Envoi FCM (HTTP legacy) — no-op si FCM_SERVER_KEY absent."""

from __future__ import annotations

import logging

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

_FCM_URL = "https://fcm.googleapis.com/fcm/send"


async def send_data_message(
    *,
    tokens: list[str],
    data: dict[str, str],
    title: str,
    body: str,
    channel_id: str = "fidel_sos_aidant",
) -> int:
    """Envoie une notif haute priorité. Retourne le nombre de tokens acceptés."""
    if not tokens:
        return 0
    key = (settings.fcm_server_key or "").strip()
    if not key:
        logger.info("FCM skipped (no FCM_SERVER_KEY): %s tokens, data=%s", len(tokens), data)
        return 0

    channel = (channel_id or "fidel_sos_aidant").strip() or "fidel_sos_aidant"
    sent = 0
    headers = {
        "Authorization": f"key={key}",
        "Content-Type": "application/json",
    }
    async with httpx.AsyncClient(timeout=15.0) as client:
        for token in tokens:
            payload = {
                "to": token,
                "priority": "high",
                "content_available": True,
                "notification": {
                    "title": title,
                    "body": body,
                    "sound": "default",
                    "channel_id": channel,
                },
                "data": data,
                "android": {
                    "priority": "high",
                    "notification": {
                        "channel_id": channel,
                        "priority": "max",
                        "default_vibrate_timings": True,
                    },
                },
            }
            try:
                res = await client.post(_FCM_URL, headers=headers, json=payload)
                if res.status_code < 300:
                    sent += 1
                else:
                    logger.warning("FCM HTTP %s: %s", res.status_code, res.text[:200])
            except Exception:
                logger.exception("FCM send failed for token …%s", token[-8:])
    return sent

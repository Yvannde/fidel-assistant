"""Job mark-prises-manquees + confirmation tardive après manquee."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Prise
from app.tests.test_aidant_prise_push_api import _add_med_and_prise
from app.tests.test_aidant_api import _patient_and_aidant


@pytest.mark.asyncio
async def test_mark_prises_manquees_grace_and_late_confirm(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    from app.core.config import settings

    monkeypatch.setattr(settings, "cron_secret", "test-cron-secret")
    monkeypatch.setattr(settings, "prise_manquee_grace_hours", 12)
    api = settings.api_v1_prefix

    r = await client.post(f"{api}/internal/jobs/mark-prises-manquees")
    assert r.status_code == 401

    headers_p, _headers_a, _patient_id = await _patient_and_aidant(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        patient_email="mark.manquee.p@example.com",
        aidant_email="mark.manquee.a@example.com",
    )
    prise_id = await _add_med_and_prise(client, api, headers_p)
    prise = await db_session.get(Prise, UUID(prise_id))
    assert prise is not None
    assert prise.statut == "en_attente"

    # Dans la fenêtre de grâce (+1 h) → pas marquée
    prise.heure_prevue = datetime.now(UTC) - timedelta(hours=1)
    await db_session.commit()

    r = await client.post(
        f"{api}/internal/jobs/mark-prises-manquees",
        headers={"X-Cron-Secret": "test-cron-secret"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["marked"] == 0
    await db_session.refresh(prise)
    assert prise.statut == "en_attente"

    # Hors grâce (+13 h) → manquee
    prise.heure_prevue = datetime.now(UTC) - timedelta(hours=13)
    version_before = int(getattr(prise, "server_version", 1) or 1)
    await db_session.commit()

    r = await client.post(
        f"{api}/internal/jobs/mark-prises-manquees",
        headers={"X-Cron-Secret": "test-cron-secret"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["scanned"] >= 1
    assert body["marked"] >= 1
    await db_session.refresh(prise)
    assert prise.statut == "manquee"
    assert int(prise.server_version) > version_before

    # Idempotent : second run ne re-marque pas
    r = await client.post(
        f"{api}/internal/jobs/mark-prises-manquees",
        headers={"X-Cron-Secret": "test-cron-secret"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["marked"] == 0

    # Confirmation tardive manquee → confirmee
    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers_p,
        json={"canal": "app"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["statut"] == "confirmee"
    assert r.json()["confirmee_at"] is not None
    await db_session.refresh(prise)
    assert prise.statut == "confirmee"
    assert prise.confirmee_at is not None


@pytest.mark.asyncio
async def test_mark_prises_manquees_skips_confirmee(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    from app.core.config import settings

    monkeypatch.setattr(settings, "cron_secret", "test-cron-secret")
    monkeypatch.setattr(settings, "prise_manquee_grace_hours", 12)
    api = settings.api_v1_prefix

    headers_p, _headers_a, _patient_id = await _patient_and_aidant(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        patient_email="mark.confirmee.p@example.com",
        aidant_email="mark.confirmee.a@example.com",
    )
    prise_id = await _add_med_and_prise(client, api, headers_p)

    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers_p,
        json={"canal": "app"},
    )
    assert r.status_code == 200, r.text

    prise = await db_session.get(Prise, UUID(prise_id))
    assert prise is not None
    prise.heure_prevue = datetime.now(UTC) - timedelta(hours=13)
    await db_session.commit()

    r = await client.post(
        f"{api}/internal/jobs/mark-prises-manquees",
        headers={"X-Cron-Secret": "test-cron-secret"},
    )
    assert r.status_code == 200, r.text
    await db_session.refresh(prise)
    assert prise.statut == "confirmee"

"""Pushes FCM aidant — prise confirmée (hook) + scan non confirmée (cron)."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import NotificationLog, Prise
from app.tests.test_aidant_api import _patient_and_aidant


async def _add_med_and_prise(
    client: AsyncClient, api: str, headers: dict
) -> str:
    r = await client.get(f"{api}/patients/me/dashboard", headers=headers)
    assert r.status_code == 200, r.text
    traitement_id = r.json()["traitements"][0]["id"]

    r = await client.post(
        f"{api}/traitements/{traitement_id}/medicaments",
        headers=headers,
        json={
            "nom": "ARV Test",
            "dosage": "1 cp",
            "forme": "comprime",
            "horaires": [{"heure": "08:00:00", "jours": ["tous"]}],
        },
    )
    assert r.status_code == 201, r.text

    r = await client.get(f"{api}/patients/me/prises", headers=headers)
    assert r.status_code == 200, r.text
    prises = r.json()
    assert len(prises) >= 1
    return prises[0]["id"]


@pytest.mark.asyncio
async def test_confirm_prise_no_push_without_opt_in(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers_p, _headers_a, _patient_id = await _patient_and_aidant(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        patient_email="push.noptin.p@example.com",
        aidant_email="push.noptin.a@example.com",
    )
    prise_id = await _add_med_and_prise(client, api, headers_p)

    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers_p,
        json={"canal": "app"},
    )
    assert r.status_code == 200, r.text

    logs = (
        await db_session.execute(
            select(NotificationLog).where(
                NotificationLog.type == "prise_confirmee_aidant"
            )
        )
    ).scalars().all()
    assert logs == []


@pytest.mark.asyncio
async def test_confirm_prise_opt_in_journals_and_dedup(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers_p, headers_a, patient_id = await _patient_and_aidant(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        patient_email="push.optin.p@example.com",
        aidant_email="push.optin.a@example.com",
    )
    prise_id = await _add_med_and_prise(client, api, headers_p)

    r = await client.patch(
        f"{api}/users/me/preferences-consentement/prise_confirmee_aidant",
        headers=headers_p,
        json={"toujours_demander": False, "regle_auto": {"enabled": True}},
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers_p,
        json={"canal": "app", "client_mutation_id": str(uuid4())},
    )
    assert r.status_code == 200, r.text

    db_session.expire_all()
    logs = (
        await db_session.execute(
            select(NotificationLog).where(
                NotificationLog.type == "prise_confirmee_aidant"
            )
        )
    ).scalars().all()
    assert len(logs) == 1
    assert logs[0].declencheur["prise_id"] == prise_id
    assert logs[0].declencheur["patient_id"] == patient_id

    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers_p,
        json={"canal": "app", "client_mutation_id": str(uuid4())},
    )
    assert r.status_code == 200, r.text

    db_session.expire_all()
    logs2 = (
        await db_session.execute(
            select(NotificationLog).where(
                NotificationLog.type == "prise_confirmee_aidant"
            )
        )
    ).scalars().all()
    assert len(logs2) == 1

    r = await client.get(f"{api}/users/me/notifications", headers=headers_a)
    assert r.status_code == 200, r.text
    types = [n["type"] for n in r.json()]
    assert "prise_confirmee_aidant_tiers" in types


@pytest.mark.asyncio
async def test_confirm_skips_aidant_without_observance(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers_p, headers_a, _pid = await _patient_and_aidant(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        patient_email="push.noobs.p@example.com",
        aidant_email="push.noobs.a@example.com",
    )

    r = await client.get(f"{api}/patients/me/aidants", headers=headers_p)
    aidant_id = r.json()[0]["aidant_id"]
    r = await client.patch(
        f"{api}/patients/me/aidants/{aidant_id}/permissions",
        headers=headers_p,
        json={"niveau_permission": {"observance": False, "constantes": False}},
    )
    assert r.status_code == 200, r.text

    await client.patch(
        f"{api}/users/me/preferences-consentement/prise_confirmee_aidant",
        headers=headers_p,
        json={"toujours_demander": False, "regle_auto": {"enabled": True}},
    )
    prise_id = await _add_med_and_prise(client, api, headers_p)
    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers_p,
        json={"canal": "app"},
    )
    assert r.status_code == 200, r.text

    r = await client.get(f"{api}/users/me/notifications", headers=headers_a)
    types = [n["type"] for n in r.json()]
    assert "prise_confirmee_aidant_tiers" not in types


@pytest.mark.asyncio
async def test_cron_scan_secret_and_non_confirmee(
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
    api = settings.api_v1_prefix

    r = await client.post(f"{api}/internal/jobs/scan-prises-non-confirmees")
    assert r.status_code == 401

    r = await client.post(
        f"{api}/internal/jobs/scan-prises-non-confirmees",
        headers={"X-Cron-Secret": "wrong"},
    )
    assert r.status_code == 401

    headers_p, headers_a, _patient_id = await _patient_and_aidant(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        patient_email="push.cron.p@example.com",
        aidant_email="push.cron.a@example.com",
    )
    prise_id = await _add_med_and_prise(client, api, headers_p)

    await client.patch(
        f"{api}/users/me/preferences-consentement/prise_non_confirmee_aidant",
        headers=headers_p,
        json={"toujours_demander": False, "regle_auto": {"delai_heures": 2}},
    )

    prise = await db_session.get(Prise, UUID(prise_id))
    assert prise is not None
    prise.heure_prevue = datetime.now(UTC) - timedelta(hours=3)
    await db_session.commit()

    r = await client.post(
        f"{api}/internal/jobs/scan-prises-non-confirmees",
        headers={"X-Cron-Secret": "test-cron-secret"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["notified"] >= 1
    assert body["scanned"] >= 1

    r = await client.post(
        f"{api}/internal/jobs/scan-prises-non-confirmees",
        headers={"X-Cron-Secret": "test-cron-secret"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["skipped"] >= 1

    r = await client.get(f"{api}/users/me/notifications", headers=headers_a)
    types = [n["type"] for n in r.json()]
    assert "prise_non_confirmee_aidant_tiers" in types

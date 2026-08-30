"""Batterie API check-in et SOS."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.models import NotificationLog, SosAlerte
from app.tests.test_onboarding_api import _auth, _infos, _register_login


async def _onboard_patient(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    *,
    email: str,
) -> dict:
    tokens = await _register_login(
        client, auth_prefix, otp_inbox, cgu_version, email=email
    )
    headers = _auth(tokens["access_token"])
    await _infos(client, onboarding_prefix, headers)
    await client.post(
        f"{onboarding_prefix}/besoin-suivi", headers=headers, json={"actif": True}
    )
    r = await client.get(f"{onboarding_prefix}/maladies")
    maladie_id = r.json()[0]["id"]
    await client.post(
        f"{onboarding_prefix}/patient/traitement",
        headers=headers,
        json={
            "en_traitement": True,
            "traitements": [{"maladie_id": maladie_id, "phase": "debut"}],
        },
    )
    await client.post(
        f"{onboarding_prefix}/patient/permissions",
        headers=headers,
        json={"notifications_accordees": True, "batterie_exemptee": False},
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers)
    return headers


@pytest.mark.asyncio
async def test_check_in_once_per_day(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="checkin.patient@example.com",
    )

    r = await client.post(
        f"{api}/patients/me/check-in", headers=headers, json={"statut": "ca_va"}
    )
    assert r.status_code == 201, r.text
    assert r.json()["statut"] == "ca_va"

    r = await client.post(
        f"{api}/patients/me/check-in", headers=headers, json={"statut": "pas_top"}
    )
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "CHECK_IN_DEJA_FAIT_AUJOURDHUI"

    r = await client.get(f"{api}/patients/me/check-in", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1


@pytest.mark.asyncio
async def test_sos_requires_contact_cancel_and_too_late(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    db_session,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="sos.patient@example.com",
    )

    r = await client.post(f"{api}/patients/me/sos", headers=headers)
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "AUCUN_CONTACT_URGENCE"

    r = await client.post(
        f"{api}/patients/me/contacts-urgence",
        headers=headers,
        json={"nom": "Marie", "telephone": "+237690000099", "relation": "fille"},
    )
    assert r.status_code == 201, r.text

    r = await client.post(f"{api}/patients/me/sos", headers=headers)
    assert r.status_code == 201, r.text
    sos_id = r.json()["sos_id"]
    assert "annulable_jusqu_a" in r.json()

    r = await client.post(f"{api}/sos/{sos_id}/annuler", headers=headers)
    assert r.status_code == 200, r.text
    assert "annul" in r.json()["message"].lower()

    r = await client.post(f"{api}/patients/me/sos", headers=headers)
    assert r.status_code == 201
    sos_id2 = r.json()["sos_id"]

    sos = await db_session.get(SosAlerte, UUID(sos_id2))
    assert sos is not None
    sos.annulable_jusqu_a = datetime.now(UTC) - timedelta(seconds=1)
    await db_session.commit()

    r = await client.post(f"{api}/sos/{sos_id2}/annuler", headers=headers)
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "SOS_TROP_TARD"

    logs = (
        await db_session.execute(
            select(NotificationLog).where(NotificationLog.type == "sos_declenche")
        )
    ).scalars().all()
    assert len(logs) >= 1
    assert "Marie" in logs[-1].contenu

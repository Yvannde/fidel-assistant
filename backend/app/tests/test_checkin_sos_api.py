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
async def test_check_in_four_levels_and_reject_invalid(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    for i, statut in enumerate(("tres_mal", "pas_top", "ca_va", "super")):
        headers = await _onboard_patient(
            client,
            auth_prefix,
            onboarding_prefix,
            otp_inbox,
            cgu_version,
            email=f"checkin.level{i}@example.com",
        )
        r = await client.post(
            f"{api}/patients/me/check-in",
            headers=headers,
            json={"statut": statut},
        )
        assert r.status_code == 201, r.text
        assert r.json()["statut"] == statut

    headers = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="checkin.invalid@example.com",
    )
    r = await client.post(
        f"{api}/patients/me/check-in",
        headers=headers,
        json={"statut": "moyen"},
    )
    assert r.status_code == 422


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


@pytest.mark.asyncio
async def test_sos_confirm_fallback_without_aidant_tokens(
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
        email="sos.confirm@example.com",
    )
    await client.post(
        f"{api}/patients/me/contacts-urgence",
        headers=headers,
        json={"nom": "Jean", "telephone": "+237690000011", "relation": "frere"},
    )
    r = await client.post(f"{api}/patients/me/sos", headers=headers)
    assert r.status_code == 201
    sos_id = r.json()["sos_id"]

    r = await client.post(f"{api}/patients/me/sos/{sos_id}/confirm", headers=headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["statut"] == "envoye"
    assert body["fallback_call_recommended"] is True
    assert body["aidants_notifies"] == 0
    assert body["acked"] is False

    r = await client.get(f"{api}/patients/me/sos/{sos_id}", headers=headers)
    assert r.status_code == 200
    assert r.json()["statut"] == "envoye"
    assert r.json()["acked"] is False


@pytest.mark.asyncio
async def test_sos_confirm_no_fallback_when_aidant_linked_without_fcm(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    """Aidant lié mais pas de FCM → attendre ack, pas d'appel immédiat."""
    from app.core.config import settings
    from app.tests.test_aidant_api import _patient_and_aidant

    api = settings.api_v1_prefix
    headers_p, _headers_a, _patient_id = await _patient_and_aidant(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        patient_email="sos.nofallback.patient@example.com",
        aidant_email="sos.nofallback.aidant@example.com",
    )
    await client.post(
        f"{api}/patients/me/contacts-urgence",
        headers=headers_p,
        json={"nom": "Paul", "telephone": "+237690000033", "relation": "ami"},
    )
    r = await client.post(f"{api}/patients/me/sos", headers=headers_p)
    assert r.status_code == 201
    sos_id = r.json()["sos_id"]

    r = await client.post(f"{api}/patients/me/sos/{sos_id}/confirm", headers=headers_p)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["statut"] == "envoye"
    assert body["fallback_call_recommended"] is False
    assert body["acked"] is False


@pytest.mark.asyncio
async def test_sos_aidant_ack_and_active_list(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings
    from app.tests.test_aidant_api import _patient_and_aidant

    api = settings.api_v1_prefix
    headers_p, headers_a, _patient_id = await _patient_and_aidant(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        patient_email="sos.ack.patient@example.com",
        aidant_email="sos.ack.aidant@example.com",
    )
    await client.post(
        f"{api}/patients/me/contacts-urgence",
        headers=headers_p,
        json={"nom": "Claire", "telephone": "+237690000022", "relation": "soeur"},
    )
    r = await client.post(
        f"{api}/devices/push-token",
        headers=headers_a,
        json={"token": "fake-fcm-token-aidant-ack-001", "platform": "android"},
    )
    assert r.status_code == 200, r.text

    r = await client.post(f"{api}/patients/me/sos", headers=headers_p)
    sos_id = r.json()["sos_id"]
    r = await client.post(f"{api}/patients/me/sos/{sos_id}/confirm", headers=headers_p)
    assert r.status_code == 200
    # Sans FCM_SERVER_KEY → 0 notify mais SOS envoye ; aidant lié → pas de fallback immédiat
    assert r.json()["statut"] == "envoye"
    assert r.json()["fallback_call_recommended"] is False

    r = await client.get(f"{api}/aidants/me/sos/active", headers=headers_a)
    assert r.status_code == 200
    active = r.json()
    assert any(row["sos_id"] == sos_id for row in active)

    r = await client.post(f"{api}/aidants/me/sos/{sos_id}/ack", headers=headers_a)
    assert r.status_code == 200, r.text

    r = await client.get(f"{api}/patients/me/sos/{sos_id}", headers=headers_p)
    assert r.json()["acked"] is True

    r = await client.get(f"{api}/aidants/me/sos/active", headers=headers_a)
    assert all(row["sos_id"] != sos_id for row in r.json())

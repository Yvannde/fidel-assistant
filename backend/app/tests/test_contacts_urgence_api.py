"""Batterie API contacts d'urgence."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

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
async def test_contacts_urgence_crud(
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
        email="contacts.patient@example.com",
    )

    r = await client.get(f"{api}/patients/me/contacts-urgence", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json() == []

    r = await client.post(
        f"{api}/patients/me/contacts-urgence",
        headers=headers,
        json={"nom": "Jean Mbarga", "telephone": "+237690000001", "relation": "fils"},
    )
    assert r.status_code == 201, r.text
    contact = r.json()
    assert contact["nom"] == "Jean Mbarga"
    assert contact["telephone"] == "+237690000001"
    assert contact["relation"] == "fils"
    contact_id = contact["id"]

    r = await client.get(f"{api}/patients/me/contacts-urgence", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = await client.delete(
        f"{api}/patients/me/contacts-urgence/{contact_id}", headers=headers
    )
    assert r.status_code == 200, r.text
    assert "supprimé" in r.json()["message"].lower()

    r = await client.get(f"{api}/patients/me/contacts-urgence", headers=headers)
    assert r.json() == []

    r = await client.delete(
        f"{api}/patients/me/contacts-urgence/{contact_id}", headers=headers
    )
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "CONTACT_NOT_FOUND"


@pytest.mark.asyncio
async def test_contacts_urgence_requires_patient(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    tokens = await _register_login(
        client,
        auth_prefix,
        otp_inbox,
        cgu_version,
        email="contacts.no.patient@example.com",
    )
    headers = _auth(tokens["access_token"])
    await _infos(client, onboarding_prefix, headers)
    await client.post(
        f"{onboarding_prefix}/besoin-suivi", headers=headers, json={"actif": False}
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers)

    r = await client.get(
        f"{settings.api_v1_prefix}/patients/me/contacts-urgence", headers=headers
    )
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "NOT_A_PATIENT"

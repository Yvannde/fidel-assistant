"""Batterie API réglages patient + alerte stock."""

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
async def test_patch_patient_settings(
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
        email="settings.patient@example.com",
    )

    r = await client.get(f"{api}/patients/me", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["notifications_accordees"] is True
    assert r.json()["batterie_exemptee"] is False
    assert r.json()["notifications_discretes"] is False

    r = await client.patch(
        f"{api}/patients/me",
        headers=headers,
        json={
            "localisation": "Yaoundé",
            "notifications_accordees": False,
            "batterie_exemptee": True,
            "notifications_discretes": True,
        },
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["localisation"] == "Yaoundé"
    assert body["notifications_accordees"] is False
    assert body["batterie_exemptee"] is True
    assert body["notifications_discretes"] is True

    r = await client.get(f"{api}/patients/me", headers=headers)
    assert r.json()["notifications_accordees"] is False
    assert r.json()["notifications_discretes"] is True


@pytest.mark.asyncio
async def test_medicament_seuil_and_stock_alert(
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
        email="settings.stock@example.com",
    )

    r = await client.get(f"{api}/patients/me/traitements", headers=headers)
    traitement_id = r.json()[0]["id"]

    r = await client.post(
        f"{api}/traitements/{traitement_id}/medicaments",
        headers=headers,
        json={
            "nom": "Metformine",
            "dosage": "500mg",
            "forme": "comprime",
            "stock_restant": 20,
            "seuil_alerte_stock": 5,
            "horaires": [{"heure": "08:00:00", "jours": ["tous"]}],
        },
    )
    assert r.status_code == 201, r.text
    med_id = r.json()["id"]

    r = await client.patch(
        f"{api}/medicaments/{med_id}",
        headers=headers,
        json={"seuil_alerte_stock": 10, "actif": True},
    )
    assert r.status_code == 200, r.text
    assert r.json()["seuil_alerte_stock"] == 10

    r = await client.patch(
        f"{api}/medicaments/{med_id}/stock",
        headers=headers,
        json={"stock_restant": 8},
    )
    assert r.status_code == 200, r.text
    assert r.json()["alerte_declenchee"] is True

    r = await client.get(f"{api}/users/me/notifications", headers=headers)
    assert r.status_code == 200
    assert any(n["type"] == "stock_medicament_bas" for n in r.json())

    r = await client.patch(
        f"{api}/medicaments/{med_id}/stock",
        headers=headers,
        json={"stock_restant": 7},
    )
    assert r.status_code == 200
    assert r.json()["alerte_declenchee"] is True
    stock_notifs = [
        n
        for n in (
            await client.get(f"{api}/users/me/notifications", headers=headers)
        ).json()
        if n["type"] == "stock_medicament_bas"
    ]
    assert len(stock_notifs) == 1

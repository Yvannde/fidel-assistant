"""Batterie API suivi patient — dashboard, médicaments, prises."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

from app.tests.test_onboarding_api import (
    EMAIL_A,
    _auth,
    _infos,
    _register_login,
)


async def _onboard_patient(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    *,
    email: str = EMAIL_A,
) -> tuple[dict, dict]:
    tokens = await _register_login(
        client, auth_prefix, otp_inbox, cgu_version, email=email
    )
    headers = _auth(tokens["access_token"])
    await _infos(client, onboarding_prefix, headers)

    await client.post(
        f"{onboarding_prefix}/besoin-suivi",
        headers=headers,
        json={"actif": True},
    )

    r = await client.get(f"{onboarding_prefix}/maladies")
    assert r.status_code == 200, r.text
    maladie_id = r.json()[0]["id"]

    await client.post(
        f"{onboarding_prefix}/patient/traitement",
        headers=headers,
        json={
            "en_traitement": True,
            "traitements": [{"maladie_id": maladie_id, "phase": "en_cours"}],
        },
    )
    await client.post(
        f"{onboarding_prefix}/patient/permissions",
        headers=headers,
        json={"notifications_accordees": True, "batterie_exemptee": True},
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers)
    return headers, {"maladie_id": maladie_id}


@pytest.mark.asyncio
async def test_patient_suivi_dashboard_to_prise(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers, _ctx = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="suivi.flow@example.com",
    )

    r = await client.get(f"{api}/patients/me/dashboard", headers=headers)
    assert r.status_code == 200, r.text
    dashboard = r.json()
    assert dashboard["prochaine_action"] == "configurer_medicaments"
    assert dashboard["medicaments_configures"] is False
    assert dashboard["notifications_accordees"] is True
    assert len(dashboard["traitements"]) == 1
    assert dashboard["traitements"][0]["medicaments_configures"] is False
    traitement_id = dashboard["traitements"][0]["id"]

    r = await client.post(
        f"{api}/traitements/{traitement_id}/medicaments",
        headers=headers,
        json={
            "nom": "Paracétamol",
            "dosage": "500 mg",
            "forme": "comprime",
            "horaires": [{"heure": "08:00:00", "jours": ["tous"]}],
        },
    )
    assert r.status_code == 201, r.text
    medicament = r.json()
    assert medicament["nom"] == "Paracétamol"
    assert len(medicament["horaires"]) == 1

    r = await client.get(f"{api}/patients/me/dashboard", headers=headers)
    assert r.status_code == 200, r.text
    dashboard = r.json()
    assert dashboard["prochaine_action"] == "aucune"
    assert dashboard["medicaments_configures"] is True
    assert dashboard["traitements"][0]["medicaments_configures"] is True

    r = await client.get(f"{api}/patients/me/prises", headers=headers)
    assert r.status_code == 200, r.text
    prises = r.json()
    assert len(prises) >= 1
    prise_id = prises[0]["id"]

    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers,
        json={"canal": "app"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["statut"] == "confirmee"

    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers,
        json={"canal": "app"},
    )
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "PRISE_DEJA_CONFIRMEE"


@pytest.mark.asyncio
async def test_list_traitements_and_medicaments(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers, _ctx = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="suivi.list@example.com",
    )

    r = await client.get(f"{api}/patients/me/traitements", headers=headers)
    assert r.status_code == 200, r.text
    assert len(r.json()) == 1

    r = await client.get(f"{api}/patients/me/medicaments", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json() == []

"""Batterie API constantes de santé."""

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
async def test_constantes_create_trend_and_list(
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
        email="constantes.patient@example.com",
    )

    r = await client.post(
        f"{api}/patients/me/constantes",
        headers=headers,
        json={
            "type": "poids",
            "valeur": 68.0,
            "unite": "kg",
            "mesure_at": "2026-08-01T08:00:00Z",
            "source": "manuel",
        },
    )
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["tendance"] == "insuffisant"
    assert body["constante"]["valeur"] == 68.0

    r = await client.post(
        f"{api}/patients/me/constantes",
        headers=headers,
        json={
            "type": "poids",
            "valeur": 69.5,
            "unite": "kg",
            "mesure_at": "2026-08-15T08:00:00Z",
            "source": "manuel",
        },
    )
    assert r.status_code == 201, r.text
    assert r.json()["tendance"] == "amelioration"

    r = await client.get(f"{api}/patients/me/constantes", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 2

    r = await client.get(
        f"{api}/patients/me/constantes", headers=headers, params={"type": "poids"}
    )
    assert len(r.json()) == 2

    r = await client.post(
        f"{api}/patients/me/constantes",
        headers=headers,
        json={
            "type": "inconnu",
            "valeur": 1,
            "unite": "x",
            "mesure_at": "2026-08-16T08:00:00Z",
            "source": "manuel",
        },
    )
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "TYPE_INVALIDE"


@pytest.mark.asyncio
async def test_aidant_constantes_permission(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    api = settings.api_v1_prefix
    headers_p = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="const.aid.patient@example.com",
    )
    await client.post(
        f"{api}/patients/me/constantes",
        headers=headers_p,
        json={
            "type": "glycemie",
            "valeur": 1.2,
            "unite": "g/L",
            "mesure_at": "2026-08-10T07:00:00Z",
            "source": "manuel",
        },
    )

    r = await client.post(f"{api}/patients/me/sync-code", headers=headers_p)
    code = r.json()["code"]

    tokens_a = await _register_login(
        client,
        auth_prefix,
        otp_inbox,
        cgu_version,
        email="const.aid.viewer@example.com",
    )
    headers_a = _auth(tokens_a["access_token"])
    await client.post(
        f"{onboarding_prefix}/infos",
        headers=headers_a,
        json={
            "nom_complet": "Paul Aidant",
            "date_naissance": "1990-01-01",
            "sexe": "M",
            "localisation": "Douala",
        },
    )
    await client.post(
        f"{onboarding_prefix}/besoin-suivi", headers=headers_a, json={"actif": False}
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers_a)
    r = await client.post(
        f"{api}/aidants/me/sync", headers=headers_a, json={"code": code}
    )
    patient_id = r.json()["patient_id"]

    r = await client.get(
        f"{api}/aidants/me/patients/{patient_id}/constantes", headers=headers_a
    )
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "PERMISSION_REFUSEE"

    r = await client.get(f"{api}/patients/me/aidants", headers=headers_p)
    aidant_id = r.json()[0]["aidant_id"]
    await client.patch(
        f"{api}/patients/me/aidants/{aidant_id}/permissions",
        headers=headers_p,
        json={"niveau_permission": {"observance": True, "constantes": True}},
    )

    r = await client.get(
        f"{api}/aidants/me/patients/{patient_id}/constantes", headers=headers_a
    )
    assert r.status_code == 200, r.text
    assert len(r.json()) == 1
    assert r.json()[0]["type"] == "glycemie"

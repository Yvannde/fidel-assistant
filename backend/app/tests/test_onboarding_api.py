"""Batterie API onboarding — parcours court, patient, sync aidant."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

EMAIL_A = "amina.onboard@example.com"
EMAIL_B = "paul.onboard@example.com"
PASSWORD = "Secret123!"


async def _register_login(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    *,
    email: str,
) -> dict:
    await client.post(
        f"{auth_prefix}/register",
        json={"email": email, "langue": "fr", "fuseau_horaire": "Africa/Douala"},
    )
    r = await client.post(
        f"{auth_prefix}/verify-otp",
        json={"email": email, "code": otp_inbox[email]},
    )
    temp = r.json()["temp_token"]
    await client.post(
        f"{auth_prefix}/set-password",
        json={"temp_token": temp, "password": PASSWORD},
    )
    await client.post(
        f"{auth_prefix}/accept-cgu",
        json={"temp_token": temp, "version": cgu_version},
    )
    await client.post(
        f"{auth_prefix}/accept-consentement-sante",
        json={"temp_token": temp},
    )
    r = await client.post(
        f"{auth_prefix}/login",
        json={"email": email, "password": PASSWORD},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["onboarding_step"] == "infos"
    assert body["has_patient_profile"] is False
    assert body["is_aidant"] is False
    return body


def _auth(headers_token: str) -> dict:
    return {"Authorization": f"Bearer {headers_token}"}


async def _infos(client: AsyncClient, onboarding_prefix: str, headers: dict) -> None:
    r = await client.post(
        f"{onboarding_prefix}/infos",
        headers=headers,
        json={
            "nom_complet": "Amina Nguema",
            "date_naissance": "1995-03-12",
            "sexe": "F",
            "localisation": "Douala",
            "phone": "+237600000001",
        },
    )
    assert r.status_code == 200, r.text
    assert r.json()["onboarding_step"] == "besoin_suivi"


@pytest.mark.asyncio
async def test_onboarding_short_path_no_suivi(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    tokens = await _register_login(
        client, auth_prefix, otp_inbox, cgu_version, email=EMAIL_A
    )
    headers = _auth(tokens["access_token"])
    await _infos(client, onboarding_prefix, headers)

    r = await client.post(
        f"{onboarding_prefix}/besoin-suivi",
        headers=headers,
        json={"actif": False},
    )
    assert r.status_code == 200, r.text
    assert r.json()["has_patient_profile"] is False

    r = await client.post(f"{onboarding_prefix}/complete", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["onboarding_step"] == "termine"

    r = await client.get(f"{onboarding_prefix}/status", headers=headers)
    assert r.json() == {
        "onboarding_step": "termine",
        "has_patient_profile": False,
        "is_aidant": False,
    }


@pytest.mark.asyncio
async def test_onboarding_patient_path_and_sync_aidant(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    # Amina — suivi pour elle
    tokens_a = await _register_login(
        client, auth_prefix, otp_inbox, cgu_version, email=EMAIL_A
    )
    headers_a = _auth(tokens_a["access_token"])
    await _infos(client, onboarding_prefix, headers_a)

    r = await client.post(
        f"{onboarding_prefix}/besoin-suivi",
        headers=headers_a,
        json={"actif": True},
    )
    assert r.status_code == 200, r.text
    assert r.json()["has_patient_profile"] is True
    assert r.json()["onboarding_step"] == "patient_traitement"

    r = await client.get(f"{onboarding_prefix}/maladies")
    assert r.status_code == 200, r.text
    maladies = r.json()
    assert len(maladies) >= 1
    maladie_id = maladies[0]["id"]

    r = await client.post(
        f"{onboarding_prefix}/patient/traitement",
        headers=headers_a,
        json={
            "en_traitement": True,
            "traitements": [{"maladie_id": maladie_id, "phase": "en_cours"}],
        },
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{onboarding_prefix}/patient/permissions",
        headers=headers_a,
        json={"notifications_accordees": True, "batterie_exemptee": True},
    )
    assert r.status_code == 200, r.text

    r = await client.post(f"{onboarding_prefix}/complete", headers=headers_a)
    assert r.status_code == 200
    assert r.json()["onboarding_step"] == "termine"

    r = await client.post(
        f"{settings.api_v1_prefix}/patients/me/sync-code",
        headers=headers_a,
    )
    assert r.status_code == 200, r.text
    code = r.json()["code"]

    # Paul — parcours court puis sync
    tokens_b = await _register_login(
        client, auth_prefix, otp_inbox, cgu_version, email=EMAIL_B
    )
    headers_b = _auth(tokens_b["access_token"])
    r = await client.post(
        f"{onboarding_prefix}/infos",
        headers=headers_b,
        json={
            "nom_complet": "Paul Mbarga",
            "date_naissance": "1990-01-01",
            "sexe": "M",
            "localisation": "Yaoundé",
        },
    )
    assert r.status_code == 200
    await client.post(
        f"{onboarding_prefix}/besoin-suivi",
        headers=headers_b,
        json={"actif": False},
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers_b)

    r = await client.post(
        f"{settings.api_v1_prefix}/aidants/me/sync",
        headers=headers_b,
        json={"code": code},
    )
    assert r.status_code == 200, r.text
    assert r.json()["is_aidant"] is True
    assert r.json()["patient_prenom"] == "Amina"

    r = await client.get(f"{onboarding_prefix}/status", headers=headers_b)
    assert r.json()["is_aidant"] is True
    assert r.json()["has_patient_profile"] is False


@pytest.mark.asyncio
async def test_activate_patient_from_home(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    from app.core.config import settings

    tokens = await _register_login(
        client, auth_prefix, otp_inbox, cgu_version, email="later.patient@example.com"
    )
    headers = _auth(tokens["access_token"])
    await _infos(client, onboarding_prefix, headers)
    await client.post(
        f"{onboarding_prefix}/besoin-suivi", headers=headers, json={"actif": False}
    )
    await client.post(f"{onboarding_prefix}/complete", headers=headers)

    r = await client.post(
        f"{settings.api_v1_prefix}/patients/me/activate",
        headers=headers,
    )
    assert r.status_code == 200, r.text
    assert r.json()["has_patient_profile"] is True

    r = await client.post(
        f"{settings.api_v1_prefix}/patients/me/activate",
        headers=headers,
    )
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "PATIENT_ALREADY_ACTIVE"

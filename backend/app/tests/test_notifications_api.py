"""Batterie API préférences consentement + réponses notifications."""

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
async def test_preferences_and_notification_response(
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
        email="notif.prefs@example.com",
    )

    r = await client.get(f"{api}/users/me/preferences-consentement", headers=headers)
    assert r.status_code == 200, r.text
    prefs = r.json()
    assert len(prefs) >= 1
    assert all(p["toujours_demander"] is True for p in prefs)
    assert any(p["type_alerte"] == "constante_degradation" for p in prefs)

    r = await client.patch(
        f"{api}/users/me/preferences-consentement/checkin_absence",
        headers=headers,
        json={"toujours_demander": False, "regle_auto": {"delai_heures": 48}},
    )
    assert r.status_code == 200, r.text
    assert r.json()["toujours_demander"] is False
    assert r.json()["regle_auto"]["delai_heures"] == 48
    assert r.json()["id"] is not None

    # Dégradation → proposition (registre)
    await client.post(
        f"{api}/patients/me/constantes",
        headers=headers,
        json={
            "type": "glycemie",
            "valeur": 1.0,
            "unite": "g/L",
            "mesure_at": "2026-08-01T08:00:00Z",
            "source": "manuel",
        },
    )
    r = await client.post(
        f"{api}/patients/me/constantes",
        headers=headers,
        json={
            "type": "glycemie",
            "valeur": 1.5,
            "unite": "g/L",
            "mesure_at": "2026-08-10T08:00:00Z",
            "source": "manuel",
        },
    )
    assert r.status_code == 201
    assert r.json()["tendance"] == "degradation"

    r = await client.get(f"{api}/users/me/notifications", headers=headers)
    assert r.status_code == 200, r.text
    notifs = r.json()
    assert len(notifs) >= 1
    prop = next(n for n in notifs if n["type"] == "constante_degradation")
    assert prop["proposition"] is True
    assert prop["reponse"] is None

    r = await client.post(
        f"{api}/notifications/{prop['id']}/reponse",
        headers=headers,
        json={"reponse": "non"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["action_declenchee"] is False

    r = await client.post(
        f"{api}/notifications/{prop['id']}/reponse",
        headers=headers,
        json={"reponse": "oui"},
    )
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "DEJA_REPONDU"


@pytest.mark.asyncio
async def test_notification_oui_with_tiers(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    db_session,
) -> None:
    from uuid import UUID

    from app.core.config import settings
    from app.services import notification_service

    api = settings.api_v1_prefix
    headers_p = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="notif.tiers.patient@example.com",
    )
    r = await client.post(f"{api}/patients/me/sync-code", headers=headers_p)
    code = r.json()["code"]

    tokens_a = await _register_login(
        client,
        auth_prefix,
        otp_inbox,
        cgu_version,
        email="notif.tiers.aidant@example.com",
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
    await client.post(f"{api}/aidants/me/sync", headers=headers_a, json={"code": code})

    r = await client.get(f"{api}/patients/me/aidants", headers=headers_p)
    aidant_id = UUID(r.json()[0]["aidant_id"])
    r = await client.get(f"{api}/auth/me", headers=headers_p)
    patient_id = UUID(r.json()["id"])

    log = await notification_service.trigger(
        db_session,
        type_alerte="constante_degradation",
        user_id=patient_id,
        contexte={"test": True},
        contenu="On observe une hausse. Ce n'est pas forcément grave.",
        tiers_potentiel=aidant_id,
    )
    await db_session.commit()

    r = await client.post(
        f"{api}/notifications/{log.id}/reponse",
        headers=headers_p,
        json={"reponse": "oui"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["action_declenchee"] is True

    r = await client.get(f"{api}/users/me/notifications", headers=headers_a)
    assert r.status_code == 200
    assert any(n["type"] == "constante_degradation_tiers" for n in r.json())

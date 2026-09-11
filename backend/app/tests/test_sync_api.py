"""Tests Sync V2 — push / pull Phase 4."""

from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient

from app.core.config import settings
from app.tests.test_patient_suivi_api import _onboard_patient


async def _setup_prise(
    client: AsyncClient,
    headers: dict,
    api: str,
) -> str:
    r = await client.get(f"{api}/patients/me/dashboard", headers=headers)
    assert r.status_code == 200, r.text
    traitement_id = r.json()["traitements"][0]["id"]
    r = await client.post(
        f"{api}/traitements/{traitement_id}/medicaments",
        headers=headers,
        json={
            "nom": "Aspi",
            "dosage": "100mg",
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
async def test_sync_push_idempotent_and_pull(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    api = settings.api_v1_prefix
    headers, _ = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="sync.v2@example.com",
    )
    prise_id = await _setup_prise(client, headers, api)
    mutation_id = str(uuid4())

    body = {
        "mutations": [
            {
                "mutation_id": mutation_id,
                "entity": "prise",
                "entity_id": prise_id,
                "op": "confirm",
                "payload": {"canal": "app"},
                "client_ts": "2026-09-11T08:00:00+00:00",
            }
        ]
    }
    r = await client.post(f"{api}/sync/push", headers=headers, json=body)
    assert r.status_code == 200, r.text
    assert r.json()["results"][0]["status"] == "applied"

    r = await client.post(f"{api}/sync/push", headers=headers, json=body)
    assert r.status_code == 200, r.text
    assert r.json()["results"][0]["status"] == "duplicate"

    r = await client.get(f"{api}/sync/pull", headers=headers)
    assert r.status_code == 200, r.text
    data = r.json()
    assert "server_time" in data
    prises = [e for e in data["entities"] if e.get("type") == "prise"]
    assert any(e["id"] == prise_id and e["statut"] == "confirmee" for e in prises)
    assert any(e.get("server_version", 0) >= 1 for e in prises)


@pytest.mark.asyncio
async def test_sync_push_report_on_confirmed_rejected(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    api = settings.api_v1_prefix
    headers, _ = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="sync.conflict@example.com",
    )
    prise_id = await _setup_prise(client, headers, api)

    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers,
        json={"canal": "app"},
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{api}/sync/push",
        headers=headers,
        json={
            "mutations": [
                {
                    "mutation_id": str(uuid4()),
                    "entity": "prise",
                    "entity_id": prise_id,
                    "op": "report",
                    "payload": {"nouvelle_heure": "2026-09-11T12:00:00+00:00"},
                }
            ]
        },
    )
    assert r.status_code == 200, r.text
    assert r.json()["results"][0]["status"] == "rejected"
    assert r.json()["results"][0]["reason"] == "SYNC_CONFLICT"

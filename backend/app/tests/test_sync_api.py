"""Tests Sync V2 — push / pull Phases 4–5."""

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


@pytest.mark.asyncio
async def test_sync_push_constante_and_check_in_phase5(
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
        email="sync.p5@example.com",
    )

    const_mut = str(uuid4())
    body_const = {
        "mutations": [
            {
                "mutation_id": const_mut,
                "entity": "constante",
                "entity_id": None,
                "op": "create_constante",
                "payload": {
                    "type": "poids",
                    "valeur": 72.5,
                    "unite": "kg",
                    "mesure_at": "2026-09-11T10:00:00+00:00",
                    "source": "manuel",
                },
            }
        ]
    }
    r = await client.post(f"{api}/sync/push", headers=headers, json=body_const)
    assert r.status_code == 200, r.text
    assert r.json()["results"][0]["status"] == "applied"

    r = await client.post(f"{api}/sync/push", headers=headers, json=body_const)
    assert r.status_code == 200, r.text
    assert r.json()["results"][0]["status"] == "duplicate"

    check_mut = str(uuid4())
    body_check = {
        "mutations": [
            {
                "mutation_id": check_mut,
                "entity": "check_in",
                "entity_id": None,
                "op": "create_check_in",
                "payload": {"statut": "ca_va"},
            }
        ]
    }
    r = await client.post(f"{api}/sync/push", headers=headers, json=body_check)
    assert r.status_code == 200, r.text
    assert r.json()["results"][0]["status"] == "applied"

    r = await client.post(f"{api}/sync/push", headers=headers, json=body_check)
    assert r.status_code == 200, r.text
    assert r.json()["results"][0]["status"] == "duplicate"

    r = await client.post(
        f"{api}/sync/push",
        headers=headers,
        json={
            "mutations": [
                {
                    "mutation_id": str(uuid4()),
                    "entity": "check_in",
                    "op": "create_check_in",
                    "payload": {"statut": "pas_top"},
                }
            ]
        },
    )
    assert r.status_code == 200, r.text
    assert r.json()["results"][0]["status"] == "rejected"
    assert r.json()["results"][0]["reason"] == "CHECK_IN_DEJA_FAIT_AUJOURDHUI"

    r = await client.get(f"{api}/sync/pull", headers=headers)
    assert r.status_code == 200, r.text
    entities = r.json()["entities"]
    assert any(e.get("type") == "constante" for e in entities)
    assert any(e.get("type") == "check_in" for e in entities)
    cursor = r.json().get("next_cursor")
    assert cursor is None or cursor.count("|") >= 2


@pytest.mark.asyncio
async def test_sync_push_mutation_id_replay_x3(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    """QA Phase 6 #1 — même mutation_id ×3 → 1 applied + 2 duplicate."""
    api = settings.api_v1_prefix
    headers, _ = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="sync.replay3@example.com",
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
            }
        ]
    }

    statuses = []
    for _ in range(3):
        r = await client.post(f"{api}/sync/push", headers=headers, json=body)
        assert r.status_code == 200, r.text
        statuses.append(r.json()["results"][0]["status"])

    assert statuses == ["applied", "duplicate", "duplicate"]

    r = await client.get(f"{api}/patients/me/prises", headers=headers)
    assert r.status_code == 200, r.text
    matches = [p for p in r.json() if p["id"] == prise_id]
    assert len(matches) == 1
    assert matches[0]["statut"] == "confirmee"


@pytest.mark.asyncio
async def test_sync_offline_no_downgrade_confirmee(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    """QA Phase 6 #5 — serveur confirmee + client en_attente → conflict."""
    api = settings.api_v1_prefix
    headers, _ = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="sync.nodowngrade@example.com",
    )
    prise_id = await _setup_prise(client, headers, api)

    r = await client.post(
        f"{api}/prises/{prise_id}/confirmer",
        headers=headers,
        json={"canal": "app"},
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{api}/prises/sync-offline",
        headers=headers,
        json=[
            {
                "id": prise_id,
                "statut": "en_attente",
                "client_mutation_id": str(uuid4()),
            }
        ],
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert prise_id in [str(x) for x in body.get("conflicts", [])]
    assert prise_id not in [str(x) for x in body.get("synced", [])]

    r = await client.get(f"{api}/patients/me/prises", headers=headers)
    assert r.status_code == 200, r.text
    matches = [p for p in r.json() if p["id"] == prise_id]
    assert matches[0]["statut"] == "confirmee"

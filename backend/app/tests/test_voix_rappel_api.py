"""Batterie API voix de rappel — validation type/poids."""

from __future__ import annotations

import struct

import pytest
from httpx import AsyncClient

from app.tests.test_onboarding_api import _auth, _infos, _register_login


def _fake_mp3(size: int = 256) -> bytes:
    body = b"ID3" + b"\x03\x00\x00\x00\x00\x00\x00" + b"\xff\xfb\x90\x00"
    if size <= len(body):
        return body[:size]
    return body + b"\x00" * (size - len(body))


def _fake_m4a(size: int = 256) -> bytes:
    payload = b"M4A " + b"\x00\x00\x00\x00" + b"isom" + b"mp42"
    header = struct.pack(">I", 8 + len(payload)) + b"ftyp" + payload
    if size <= len(header):
        return header
    return header + b"\x00" * (size - len(header))


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
async def test_voix_rappel_upload_and_download(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    tmp_path,
    monkeypatch,
) -> None:
    from app.core.config import settings

    monkeypatch.setattr(settings, "media_root", str(tmp_path / "media"))
    monkeypatch.setattr(settings, "voix_rappel_max_bytes", 2 * 1024 * 1024)

    api = settings.api_v1_prefix
    headers = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="voix.patient@example.com",
    )

    r = await client.get(f"{api}/patients/me/voix-rappel", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["type"] == "systeme"
    assert r.json()["fichier_audio_url"] is None

    audio = _fake_m4a(512)
    r = await client.put(
        f"{api}/patients/me/voix-rappel",
        headers=headers,
        data={"type": "personnalisee"},
        files={"fichier": ("note.m4a", audio, "audio/mp4")},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["type"] == "personnalisee"
    assert body["fichier_audio_url"] is not None
    assert body["enregistree_par"] is not None

    r = await client.get(f"{api}/patients/me/voix-rappel/fichier", headers=headers)
    assert r.status_code == 200, r.text
    assert r.content == audio

    r = await client.put(
        f"{api}/patients/me/voix-rappel",
        headers=headers,
        data={"type": "systeme"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["type"] == "systeme"
    assert r.json()["fichier_audio_url"] is None


@pytest.mark.asyncio
async def test_voix_rappel_rejects_bad_type_and_oversize(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    tmp_path,
    monkeypatch,
) -> None:
    from app.core.config import settings

    monkeypatch.setattr(settings, "media_root", str(tmp_path / "media"))
    monkeypatch.setattr(settings, "voix_rappel_max_bytes", 1024)

    api = settings.api_v1_prefix
    headers = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="voix.reject@example.com",
    )

    r = await client.put(
        f"{api}/patients/me/voix-rappel",
        headers=headers,
        data={"type": "personnalisee"},
        files={"fichier": ("fake.mp3", b"not-an-audio-file!!!!", "audio/mpeg")},
    )
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "FICHIER_AUDIO_INVALIDE"

    r = await client.put(
        f"{api}/patients/me/voix-rappel",
        headers=headers,
        data={"type": "personnalisee"},
        files={"fichier": ("note.wav", _fake_mp3(), "audio/wav")},
    )
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "FICHIER_AUDIO_INVALIDE"

    r = await client.put(
        f"{api}/patients/me/voix-rappel",
        headers=headers,
        data={"type": "personnalisee"},
        files={"fichier": ("big.mp3", _fake_mp3(2048), "audio/mpeg")},
    )
    assert r.status_code == 413
    assert r.json()["error"]["code"] == "FICHIER_AUDIO_TROP_LOURD"


@pytest.mark.asyncio
async def test_aidant_can_upload_voix(
    client: AsyncClient,
    auth_prefix: str,
    onboarding_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
    tmp_path,
    monkeypatch,
) -> None:
    from app.core.config import settings

    monkeypatch.setattr(settings, "media_root", str(tmp_path / "media"))

    api = settings.api_v1_prefix
    headers_p = await _onboard_patient(
        client,
        auth_prefix,
        onboarding_prefix,
        otp_inbox,
        cgu_version,
        email="voix.aid.patient@example.com",
    )
    r = await client.post(f"{api}/patients/me/sync-code", headers=headers_p)
    code = r.json()["code"]
    patient_id = (await client.get(f"{api}/auth/me", headers=headers_p)).json()["id"]

    tokens_a = await _register_login(
        client,
        auth_prefix,
        otp_inbox,
        cgu_version,
        email="voix.aidant@example.com",
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

    audio = _fake_mp3(300)
    r = await client.post(
        f"{api}/aidants/me/patients/{patient_id}/voix-rappel",
        headers=headers_a,
        files={"fichier": ("proche.mp3", audio, "audio/mpeg")},
    )
    assert r.status_code == 201, r.text
    assert r.json()["type"] == "personnalisee"

    r = await client.get(f"{api}/patients/me/voix-rappel", headers=headers_p)
    assert r.status_code == 200
    assert r.json()["type"] == "personnalisee"

"""Batterie API auth — flux inscription → session → reset → sessions."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

EMAIL = "patient.test@example.com"
PASSWORD = "Secret123!"


async def _register_and_verify(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    *,
    email: str = EMAIL,
) -> str:
    r = await client.post(
        f"{auth_prefix}/register",
        json={"email": email, "langue": "fr", "fuseau_horaire": "Africa/Douala"},
    )
    assert r.status_code == 200, r.text
    assert email.lower() in otp_inbox

    r = await client.post(
        f"{auth_prefix}/verify-otp",
        json={"email": email, "code": otp_inbox[email.lower()]},
    )
    assert r.status_code == 200, r.text
    return r.json()["temp_token"]


async def _complete_onboarding_legal(
    client: AsyncClient,
    auth_prefix: str,
    *,
    temp_token: str,
    cgu_version: str,
) -> None:
    r = await client.post(
        f"{auth_prefix}/set-password",
        json={"temp_token": temp_token, "password": PASSWORD},
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{auth_prefix}/accept-cgu",
        json={"temp_token": temp_token, "version": cgu_version},
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{auth_prefix}/accept-consentement-sante",
        json={"temp_token": temp_token},
    )
    assert r.status_code == 200, r.text


async def _login(client: AsyncClient, auth_prefix: str, *, email: str = EMAIL) -> dict:
    r = await client.post(
        f"{auth_prefix}/login",
        json={"email": email, "password": PASSWORD, "device_info": "pytest"},
    )
    assert r.status_code == 200, r.text
    return r.json()


@pytest.mark.asyncio
async def test_register_duplicate_verified_fails(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    temp = await _register_and_verify(client, auth_prefix, otp_inbox)
    await _complete_onboarding_legal(
        client, auth_prefix, temp_token=temp, cgu_version=cgu_version
    )

    r = await client.post(
        f"{auth_prefix}/register",
        json={"email": EMAIL, "langue": "fr"},
    )
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "EMAIL_ALREADY_VERIFIED"


@pytest.mark.asyncio
async def test_verify_otp_invalid_code(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
) -> None:
    await client.post(
        f"{auth_prefix}/register",
        json={"email": EMAIL, "langue": "fr"},
    )
    assert EMAIL in otp_inbox

    r = await client.post(
        f"{auth_prefix}/verify-otp",
        json={"email": EMAIL, "code": "000000"},
    )
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "OTP_INVALID"


@pytest.mark.asyncio
async def test_full_email_auth_flow(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    temp = await _register_and_verify(client, auth_prefix, otp_inbox)
    await _complete_onboarding_legal(
        client, auth_prefix, temp_token=temp, cgu_version=cgu_version
    )

    tokens = await _login(client, auth_prefix)
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    assert tokens["onboarding_step"] == "choix_role"

    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    r = await client.get(f"{auth_prefix}/me", headers=headers)
    assert r.status_code == 200, r.text
    me = r.json()
    assert me["email"] == EMAIL
    assert me["has_password"] is True
    assert me["needs_cgu"] is False
    assert me["needs_consentement_sante"] is False
    assert "email" in me["auth_providers"]

    r = await client.patch(
        f"{auth_prefix}/me",
        headers=headers,
        json={"phone": "+237600000000"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["phone"] == "+237600000000"

    r = await client.post(
        f"{auth_prefix}/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert r.status_code == 200, r.text
    assert "access_token" in r.json()

    r = await client.get(f"{auth_prefix}/sessions", headers=headers)
    assert r.status_code == 200, r.text
    sessions = r.json()
    assert len(sessions) >= 1
    assert sessions[0]["device_info"] == "pytest"

    r = await client.post(
        f"{auth_prefix}/logout",
        headers=headers,
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{auth_prefix}/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "REFRESH_TOKEN_INVALID_OR_EXPIRED"


@pytest.mark.asyncio
async def test_login_wrong_password(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    temp = await _register_and_verify(client, auth_prefix, otp_inbox)
    await _complete_onboarding_legal(
        client, auth_prefix, temp_token=temp, cgu_version=cgu_version
    )

    r = await client.post(
        f"{auth_prefix}/login",
        json={"email": EMAIL, "password": "WrongPass1"},
    )
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "INVALID_CREDENTIALS"


@pytest.mark.asyncio
async def test_forgot_and_reset_password(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    temp = await _register_and_verify(client, auth_prefix, otp_inbox)
    await _complete_onboarding_legal(
        client, auth_prefix, temp_token=temp, cgu_version=cgu_version
    )

    otp_inbox.clear()
    r = await client.post(f"{auth_prefix}/forgot-password", json={"email": EMAIL})
    assert r.status_code == 200, r.text
    assert EMAIL in otp_inbox

    new_password = "NewSecret9!"
    r = await client.post(
        f"{auth_prefix}/reset-password",
        json={
            "email": EMAIL,
            "code": otp_inbox[EMAIL],
            "nouveau_password": new_password,
        },
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{auth_prefix}/login",
        json={"email": EMAIL, "password": PASSWORD},
    )
    assert r.status_code == 401

    r = await client.post(
        f"{auth_prefix}/login",
        json={"email": EMAIL, "password": new_password},
    )
    assert r.status_code == 200, r.text


@pytest.mark.asyncio
async def test_change_password_and_logout_all(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    temp = await _register_and_verify(client, auth_prefix, otp_inbox)
    await _complete_onboarding_legal(
        client, auth_prefix, temp_token=temp, cgu_version=cgu_version
    )
    tokens = await _login(client, auth_prefix)
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    r = await client.post(
        f"{auth_prefix}/change-password",
        headers=headers,
        json={"current_password": PASSWORD, "nouveau_password": "Changed456!"},
    )
    assert r.status_code == 200, r.text

    r = await client.post(f"{auth_prefix}/logout-all", headers=headers)
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{auth_prefix}/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_email_change_flow(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    temp = await _register_and_verify(client, auth_prefix, otp_inbox)
    await _complete_onboarding_legal(
        client, auth_prefix, temp_token=temp, cgu_version=cgu_version
    )
    tokens = await _login(client, auth_prefix)
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    new_email = "nouveau.patient@example.com"
    otp_inbox.clear()
    r = await client.post(
        f"{auth_prefix}/request-email-change",
        headers=headers,
        json={"nouvel_email": new_email},
    )
    assert r.status_code == 200, r.text
    assert new_email in otp_inbox

    r = await client.post(
        f"{auth_prefix}/confirm-email-change",
        headers=headers,
        json={"nouvel_email": new_email, "code": otp_inbox[new_email]},
    )
    assert r.status_code == 200, r.text
    assert r.json()["email"] == new_email

    r = await client.get(f"{auth_prefix}/me", headers=headers)
    assert r.status_code == 200
    assert r.json()["email"] == new_email


@pytest.mark.asyncio
async def test_delete_account(
    client: AsyncClient,
    auth_prefix: str,
    otp_inbox: dict[str, str],
    cgu_version: str,
) -> None:
    temp = await _register_and_verify(client, auth_prefix, otp_inbox)
    await _complete_onboarding_legal(
        client, auth_prefix, temp_token=temp, cgu_version=cgu_version
    )
    tokens = await _login(client, auth_prefix)
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}

    r = await client.request(
        "DELETE",
        f"{auth_prefix}/me",
        headers=headers,
        json={"password": PASSWORD},
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"{auth_prefix}/login",
        json={"email": EMAIL, "password": PASSWORD},
    )
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_google_auth_mocked(
    client: AsyncClient,
    auth_prefix: str,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def _fake_verify(_token: str) -> dict:
        return {
            "sub": "google-sub-test-001",
            "email": "google.user@example.com",
            "email_verified": True,
        }

    monkeypatch.setattr(
        "app.services.auth_service.verify_google_id_token",
        _fake_verify,
    )

    r = await client.post(
        f"{auth_prefix}/google",
        json={
            "id_token": "fake.jwt.token",
            "langue": "fr",
            "fuseau_horaire": "Africa/Douala",
        },
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["is_new_user"] is True
    assert body["needs_cgu"] is True
    assert body["needs_consentement_sante"] is True
    assert "access_token" in body

    headers = {"Authorization": f"Bearer {body['access_token']}"}
    r = await client.get(f"{auth_prefix}/me", headers=headers)
    assert r.status_code == 200
    me = r.json()
    assert me["email"] == "google.user@example.com"
    assert "google" in me["auth_providers"]
    assert me["has_password"] is False


@pytest.mark.asyncio
async def test_me_unauthorized(client: AsyncClient, auth_prefix: str) -> None:
    r = await client.get(f"{auth_prefix}/me")
    assert r.status_code in (401, 403)

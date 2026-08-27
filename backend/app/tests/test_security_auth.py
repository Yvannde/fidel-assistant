"""Unité — sécurité auth (hash, JWT, OTP)."""

from uuid import uuid4

from app.core.security import (
    create_access_token,
    create_opaque_refresh_token,
    create_temp_token,
    decode_token,
    generate_otp_code,
    hash_otp,
    hash_password,
    hash_token,
    verify_otp,
    verify_password,
)


def test_password_hash_roundtrip() -> None:
    hashed = hash_password("Secret123!")
    assert verify_password("Secret123!", hashed)
    assert not verify_password("wrong", hashed)


def test_access_and_temp_token_types() -> None:
    user_id = uuid4()
    access = create_access_token(str(user_id))
    payload = decode_token(access)
    assert payload["type"] == "access"
    assert payload["sub"] == str(user_id)

    temp = create_temp_token(user_id)
    temp_payload = decode_token(temp)
    assert temp_payload["type"] == "temp"


def test_otp_code_format() -> None:
    code = generate_otp_code()
    assert len(code) == 6
    assert code.isdigit()


def test_otp_hash_roundtrip() -> None:
    code = "482913"
    hashed = hash_otp(code)
    assert verify_otp(code, hashed)
    assert not verify_otp("000000", hashed)


def test_refresh_token_opaque_and_hash() -> None:
    raw = create_opaque_refresh_token()
    assert len(raw) > 32
    digest = hash_token(raw)
    assert digest == hash_token(raw)
    assert digest != hash_token(raw + "x")


def test_decode_invalid_token_raises() -> None:
    try:
        decode_token("not.a.jwt")
        raise AssertionError("expected ValueError")
    except ValueError as exc:
        assert "token_invalid" in str(exc)

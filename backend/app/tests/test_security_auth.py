from app.core.security import (
    create_access_token,
    create_temp_token,
    decode_token,
    generate_otp_code,
    hash_password,
    verify_password,
)


def test_password_hash_roundtrip() -> None:
    hashed = hash_password("Secret123!")
    assert verify_password("Secret123!", hashed)
    assert not verify_password("wrong", hashed)


def test_access_and_temp_token_types() -> None:
    from uuid import uuid4

    access = create_access_token(str(uuid4()))
    payload = decode_token(access)
    assert payload["type"] == "access"

    temp = create_temp_token(uuid4())
    temp_payload = decode_token(temp)
    assert temp_payload["type"] == "temp"


def test_otp_code_format() -> None:
    code = generate_otp_code()
    assert len(code) == 6
    assert code.isdigit()

"""Validation stricte des fichiers audio pour notes vocales."""

from __future__ import annotations

from dataclasses import dataclass

from app.core.config import settings
from app.core.exceptions import AppException

# Formats adaptés aux notes vocales mobiles (Flutter/Android/iOS) + mp3.
ALLOWED_EXTENSIONS = frozenset({"mp3", "m4a", "aac", "ogg", "opus"})
ALLOWED_CONTENT_TYPES = frozenset(
    {
        "audio/mpeg",
        "audio/mp3",
        "audio/mp4",
        "audio/x-m4a",
        "audio/m4a",
        "audio/aac",
        "audio/ogg",
        "audio/opus",
        "application/ogg",
    }
)


def raise_too_large(max_bytes: int | None = None) -> None:
    limit = max_bytes if max_bytes is not None else settings.voix_rappel_max_bytes
    max_mo = limit / (1024 * 1024)
    raise AppException(
        "FICHIER_AUDIO_TROP_LOURD",
        f"Fichier trop lourd. Maximum autorisé : {max_mo:.0f} Mo.",
        status_code=413,
    )


async def read_upload_limited(upload, *, max_bytes: int | None = None) -> bytes:
    """Lit un UploadFile en flux ; coupe dès que la limite est dépassée."""
    limit = max_bytes if max_bytes is not None else settings.voix_rappel_max_bytes
    chunks: list[bytes] = []
    total = 0
    while True:
        chunk = await upload.read(64 * 1024)
        if not chunk:
            break
        total += len(chunk)
        if total > limit:
            raise_too_large(limit)
        chunks.append(chunk)
    return b"".join(chunks)


@dataclass(frozen=True)
class AudioValidationResult:
    extension: str
    content_type: str


def validate_voice_note(
    *,
    filename: str | None,
    content_type: str | None,
    data: bytes,
) -> AudioValidationResult:
    max_bytes = settings.voix_rappel_max_bytes
    if len(data) == 0:
        raise AppException(
            "FICHIER_AUDIO_INVALIDE",
            "Le fichier audio est vide.",
            status_code=400,
        )
    if len(data) > max_bytes:
        raise_too_large(max_bytes)

    ext = _extension(filename)
    if ext not in ALLOWED_EXTENSIONS:
        raise AppException(
            "FICHIER_AUDIO_INVALIDE",
            "Format non autorisé. Utilise mp3, m4a, aac, ogg ou opus.",
            status_code=400,
        )

    kind = _detect_kind(data)
    if kind is None:
        raise AppException(
            "FICHIER_AUDIO_INVALIDE",
            "Le contenu du fichier n'est pas un audio voix valide (mp3/m4a/aac/ogg/opus).",
            status_code=400,
        )

    # Extension doit coller au contenu détecté
    if not _extension_matches_kind(ext, kind):
        raise AppException(
            "FICHIER_AUDIO_INVALIDE",
            "L'extension du fichier ne correspond pas à son contenu audio.",
            status_code=400,
        )

    ct = (content_type or "").split(";")[0].strip().lower()
    if ct and ct not in ALLOWED_CONTENT_TYPES and ct != "application/octet-stream":
        raise AppException(
            "FICHIER_AUDIO_INVALIDE",
            "Type MIME non autorisé pour une note vocale.",
            status_code=400,
        )

    return AudioValidationResult(
        extension=ext,
        content_type=ct or _default_content_type(kind),
    )


def _extension(filename: str | None) -> str:
    if not filename or "." not in filename:
        return ""
    return filename.rsplit(".", 1)[-1].strip().lower()


def _detect_kind(data: bytes) -> str | None:
    if len(data) < 12:
        return None
    # MP3 : ID3 tag ou frame sync
    if data[:3] == b"ID3":
        return "mp3"
    if data[0] == 0xFF and (data[1] & 0xE0) == 0xE0:
        return "mp3"
    # OGG / Opus container
    if data[:4] == b"OggS":
        return "ogg"
    # ADTS AAC (souvent .aac)
    if data[0] == 0xFF and (data[1] & 0xF6) == 0xF0:
        return "aac"
    # MP4 / M4A : 'ftyp' à l'offset 4
    if data[4:8] == b"ftyp":
        brand = data[8:12]
        # Marques courantes notes vocales / AAC-in-MP4
        if brand in (
            b"M4A ",
            b"M4B ",
            b"mp42",
            b"isom",
            b"iso2",
            b"mp41",
            b"dash",
        ) or b"M4A" in data[8:24] or b"mp4a" in data[8:64]:
            return "m4a"
        # Rejeter autres ftyp (ex: video)
        if brand in (b"qt  ",) or b"qt  " in data[8:24]:
            return "m4a"
        return None
    return None


def _extension_matches_kind(ext: str, kind: str) -> bool:
    if kind == "mp3":
        return ext == "mp3"
    if kind == "m4a":
        return ext in {"m4a", "aac"}
    if kind == "aac":
        return ext in {"aac", "m4a"}
    if kind == "ogg":
        return ext in {"ogg", "opus"}
    return False


def _default_content_type(kind: str) -> str:
    return {
        "mp3": "audio/mpeg",
        "m4a": "audio/mp4",
        "aac": "audio/aac",
        "ogg": "audio/ogg",
    }.get(kind, "application/octet-stream")

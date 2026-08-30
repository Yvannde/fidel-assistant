"""Voix de rappel — stockage local + CRUD."""

from __future__ import annotations

from pathlib import Path
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.audio_validation import validate_voice_note
from app.core.config import settings
from app.core.exceptions import AppException
from app.models import User, VoixRappel
from app.services import aidant_service
from app.services.onboarding_service import _require_patient


def _media_root() -> Path:
    root = Path(settings.media_root)
    if not root.is_absolute():
        # Relatif au dossier backend/ (cwd typique uvicorn)
        root = Path.cwd() / root
    root.mkdir(parents=True, exist_ok=True)
    return root


def _absolute_path(relative: str) -> Path:
    path = _media_root() / relative
    # Anti path-traversal
    try:
        path.resolve().relative_to(_media_root().resolve())
    except ValueError as exc:
        raise AppException(
            "VOIX_NOT_FOUND",
            "Fichier audio introuvable.",
            status_code=404,
        ) from exc
    return path


def _public_fichier_url() -> str:
    base = settings.public_base_url.rstrip("/")
    prefix = settings.api_v1_prefix.rstrip("/")
    return f"{base}{prefix}/patients/me/voix-rappel/fichier"


def _serialize(voix: VoixRappel | None, *, patient_id: UUID) -> dict:
    if voix is None:
        return {
            "id": None,
            "patient_id": patient_id,
            "type": "systeme",
            "fichier_audio_url": None,
            "enregistree_par": None,
            "created_at": None,
        }
    return {
        "id": voix.id,
        "patient_id": voix.patient_id,
        "type": voix.type,
        "fichier_audio_url": (
            _public_fichier_url()
            if voix.type == "personnalisee" and voix.fichier_audio_url
            else None
        ),
        "enregistree_par": voix.enregistree_par,
        "created_at": voix.created_at,
    }


async def get_voix(db: AsyncSession, *, user: User) -> dict:
    patient = _require_patient(user)
    voix = await _get_row(db, patient_id=patient.user_id)
    return _serialize(voix, patient_id=patient.user_id)


async def upsert_patient_voix(
    db: AsyncSession,
    *,
    user: User,
    type_: str,
    filename: str | None,
    content_type: str | None,
    data: bytes | None,
) -> dict:
    patient = _require_patient(user)
    return await _upsert(
        db,
        patient_id=patient.user_id,
        recorded_by=user.id,
        type_=type_,
        filename=filename,
        content_type=content_type,
        data=data,
    )


async def upsert_aidant_voix(
    db: AsyncSession,
    *,
    user: User,
    patient_id: UUID,
    filename: str | None,
    content_type: str | None,
    data: bytes,
) -> dict:
    await aidant_service.require_aidant_of_patient(
        db, aidant_id=user.id, patient_id=patient_id
    )
    return await _upsert(
        db,
        patient_id=patient_id,
        recorded_by=user.id,
        type_="personnalisee",
        filename=filename,
        content_type=content_type,
        data=data,
    )


async def resolve_audio_file(db: AsyncSession, *, user: User) -> tuple[Path, str]:
    patient = _require_patient(user)
    voix = await _get_row(db, patient_id=patient.user_id)
    if voix is None or voix.type != "personnalisee" or not voix.fichier_audio_url:
        raise AppException(
            "VOIX_NOT_FOUND",
            "Aucune voix personnalisée n'est configurée.",
            status_code=404,
        )
    path = _absolute_path(voix.fichier_audio_url)
    if not path.is_file():
        raise AppException(
            "VOIX_NOT_FOUND",
            "Le fichier audio est introuvable sur le serveur.",
            status_code=404,
        )
    # content-type approx depuis extension
    ext = path.suffix.lstrip(".").lower()
    media = {
        "mp3": "audio/mpeg",
        "m4a": "audio/mp4",
        "aac": "audio/aac",
        "ogg": "audio/ogg",
        "opus": "audio/ogg",
    }.get(ext, "application/octet-stream")
    return path, media


async def _upsert(
    db: AsyncSession,
    *,
    patient_id: UUID,
    recorded_by: UUID,
    type_: str,
    filename: str | None,
    content_type: str | None,
    data: bytes | None,
) -> dict:
    type_norm = (type_ or "").strip().lower()
    if type_norm not in {"systeme", "personnalisee"}:
        raise AppException(
            "TYPE_INVALIDE",
            "Type de voix invalide. Choisis systeme ou personnalisee.",
            status_code=400,
        )

    existing = await _get_row(db, patient_id=patient_id)
    old_relative = existing.fichier_audio_url if existing else None

    if type_norm == "systeme":
        if existing is None:
            existing = VoixRappel(
                patient_id=patient_id,
                type="systeme",
                fichier_audio_url=None,
                enregistree_par=None,
            )
            db.add(existing)
        else:
            existing.type = "systeme"
            existing.fichier_audio_url = None
            existing.enregistree_par = None
        await db.commit()
        await db.refresh(existing)
        _delete_file_quiet(old_relative)
        return _serialize(existing, patient_id=patient_id)

    if data is None:
        raise AppException(
            "FICHIER_AUDIO_INVALIDE",
            "Un fichier audio est obligatoire pour une voix personnalisée.",
            status_code=400,
        )

    validated = validate_voice_note(
        filename=filename, content_type=content_type, data=data
    )
    relative = f"voix_rappel/{patient_id}/{uuid4()}.{validated.extension}"
    dest = _absolute_path(relative)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)

    if existing is None:
        existing = VoixRappel(
            patient_id=patient_id,
            type="personnalisee",
            fichier_audio_url=relative,
            enregistree_par=recorded_by,
        )
        db.add(existing)
    else:
        existing.type = "personnalisee"
        existing.fichier_audio_url = relative
        existing.enregistree_par = recorded_by

    await db.commit()
    await db.refresh(existing)
    if old_relative and old_relative != relative:
        _delete_file_quiet(old_relative)
    return _serialize(existing, patient_id=patient_id)


async def _get_row(db: AsyncSession, *, patient_id: UUID) -> VoixRappel | None:
    result = await db.execute(
        select(VoixRappel).where(VoixRappel.patient_id == patient_id)
    )
    return result.scalar_one_or_none()


def _delete_file_quiet(relative: str | None) -> None:
    if not relative:
        return
    try:
        path = _absolute_path(relative)
        if path.is_file():
            path.unlink()
    except AppException:
        return
    except OSError:
        return

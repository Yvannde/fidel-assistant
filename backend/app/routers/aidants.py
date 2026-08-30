from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, File, Query, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.audio_validation import read_upload_limited
from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.aidant import AidantPatientOut, ObservanceOut
from app.schemas.constante import ConstanteOut
from app.schemas.onboarding import AidantSyncIn, AidantSyncOut
from app.schemas.voix_rappel import VoixRappelOut
from app.services import aidant_service, constante_service, onboarding_service, voix_rappel_service

router = APIRouter(prefix="/aidants", tags=["aidants"])


@router.post("/me/sync", response_model=AidantSyncOut)
async def sync_aidant(
    body: AidantSyncIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> AidantSyncOut:
    data = await onboarding_service.sync_aidant(db, user=user, code=body.code)
    return AidantSyncOut(**data)


@router.get("/me/patients", response_model=list[AidantPatientOut])
async def list_my_patients(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> list[AidantPatientOut]:
    rows = await aidant_service.list_aidant_patients(db, user=user)
    return [AidantPatientOut(**row) for row in rows]


@router.get("/me/patients/{patient_id}/observance", response_model=ObservanceOut)
async def patient_observance(
    patient_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    depuis: Annotated[date | None, Query()] = None,
    jusqu_a: Annotated[date | None, Query()] = None,
) -> ObservanceOut:
    return ObservanceOut(
        **await aidant_service.get_patient_observance(
            db,
            user=user,
            patient_id=patient_id,
            depuis=depuis,
            jusqu_a=jusqu_a,
        )
    )


@router.get("/me/patients/{patient_id}/constantes", response_model=list[ConstanteOut])
async def patient_constantes(
    patient_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    type: Annotated[str | None, Query()] = None,
    depuis: Annotated[datetime | None, Query()] = None,
    jusqu_a: Annotated[datetime | None, Query()] = None,
) -> list[ConstanteOut]:
    rows = await constante_service.list_aidant_constantes(
        db,
        user=user,
        patient_id=patient_id,
        type_=type,
        depuis=depuis,
        jusqu_a=jusqu_a,
    )
    return [ConstanteOut(**row) for row in rows]


@router.post(
    "/me/patients/{patient_id}/voix-rappel",
    response_model=VoixRappelOut,
    status_code=201,
)
async def upload_patient_voix_rappel(
    patient_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    fichier: Annotated[UploadFile, File()],
) -> VoixRappelOut:
    data = await read_upload_limited(fichier)
    return VoixRappelOut(
        **await voix_rappel_service.upsert_aidant_voix(
            db,
            user=user,
            patient_id=patient_id,
            filename=fichier.filename,
            content_type=fichier.content_type,
            data=data,
        )
    )

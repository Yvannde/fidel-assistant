from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.aidant import AidantPatientOut, ObservanceOut
from app.schemas.onboarding import AidantSyncIn, AidantSyncOut
from app.services import aidant_service, onboarding_service

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

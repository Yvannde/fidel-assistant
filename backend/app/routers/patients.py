from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.onboarding import ActivatePatientOut, PatientOut, SyncCodeOut
from app.services import onboarding_service

router = APIRouter(prefix="/patients", tags=["patients"])


@router.post("/me/activate", response_model=ActivatePatientOut)
async def activate_patient(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> ActivatePatientOut:
    return ActivatePatientOut(**await onboarding_service.activate_patient(db, user=user))


@router.get("/me", response_model=PatientOut)
async def get_patient_me(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> PatientOut:
    return PatientOut(**await onboarding_service.get_patient_me(db, user=user))


@router.post("/me/sync-code", response_model=SyncCodeOut)
async def create_sync_code(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> SyncCodeOut:
    return SyncCodeOut(**await onboarding_service.create_sync_code(db, user=user))

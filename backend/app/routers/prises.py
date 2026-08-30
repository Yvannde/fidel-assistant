from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.medication import (
    PriseConfirmerIn,
    PriseReporterIn,
    PriseSyncItemIn,
    PriseSyncOut,
)
from app.services import patient_suivi_service

router = APIRouter(prefix="/prises", tags=["prises"])


@router.post("/{prise_id}/confirmer")
async def confirmer_prise(
    prise_id: UUID,
    body: PriseConfirmerIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> dict:
    return await patient_suivi_service.confirmer_prise(
        db, user=user, prise_id=prise_id, canal=body.canal
    )


@router.post("/{prise_id}/reporter")
async def reporter_prise(
    prise_id: UUID,
    body: PriseReporterIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> dict:
    return await patient_suivi_service.reporter_prise(
        db, user=user, prise_id=prise_id, nouvelle_heure=body.nouvelle_heure
    )


@router.post("/sync-offline", response_model=PriseSyncOut)
async def sync_prises_offline(
    body: list[PriseSyncItemIn],
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> PriseSyncOut:
    items = [item.model_dump() for item in body]
    result = await patient_suivi_service.sync_prises_offline(db, user=user, items=items)
    return PriseSyncOut(**result)

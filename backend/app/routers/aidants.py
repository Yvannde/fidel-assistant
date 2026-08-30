from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.onboarding import AidantSyncIn, AidantSyncOut
from app.services import onboarding_service

router = APIRouter(prefix="/aidants", tags=["aidants"])


@router.post("/me/sync", response_model=AidantSyncOut)
async def sync_aidant(
    body: AidantSyncIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> AidantSyncOut:
    data = await onboarding_service.sync_aidant(db, user=user, code=body.code)
    return AidantSyncOut(**data)

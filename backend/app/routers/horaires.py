from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.medication import MessageOut
from app.services import patient_suivi_service

router = APIRouter(prefix="/horaires", tags=["horaires"])


@router.delete("/{horaire_id}", response_model=MessageOut)
async def deactivate_horaire(
    horaire_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    return MessageOut(
        **await patient_suivi_service.deactivate_horaire(db, user=user, horaire_id=horaire_id)
    )

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.checkin_sos import MessageOut
from app.services import checkin_sos_service

router = APIRouter(prefix="/sos", tags=["sos"])


@router.post("/{sos_id}/annuler", response_model=MessageOut)
async def annuler_sos(
    sos_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    return MessageOut(
        **await checkin_sos_service.cancel_sos(db, user=user, sos_id=sos_id)
    )

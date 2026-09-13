from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.checkin_sos import PushTokenIn, PushTokenOut
from app.services import device_push_service

router = APIRouter(prefix="/devices", tags=["devices"])


@router.post("/push-token", response_model=PushTokenOut)
async def register_push_token(
    body: PushTokenIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> PushTokenOut:
    data = await device_push_service.upsert_push_token(
        db,
        user=user,
        token=body.token,
        platform=body.platform,
    )
    return PushTokenOut(**data)

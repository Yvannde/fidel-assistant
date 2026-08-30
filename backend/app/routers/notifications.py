from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.notification import (
    NotificationLogOut,
    NotificationReponseIn,
    NotificationReponseOut,
    PreferenceConsentementIn,
    PreferenceConsentementOut,
)
from app.services import notification_service

router = APIRouter(tags=["notifications"])


@router.get(
    "/users/me/preferences-consentement",
    response_model=list[PreferenceConsentementOut],
)
async def list_preferences(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> list[PreferenceConsentementOut]:
    rows = await notification_service.list_preferences(db, user=user)
    return [PreferenceConsentementOut(**row) for row in rows]


@router.patch(
    "/users/me/preferences-consentement/{type_alerte}",
    response_model=PreferenceConsentementOut,
)
async def upsert_preference(
    type_alerte: str,
    body: PreferenceConsentementIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> PreferenceConsentementOut:
    return PreferenceConsentementOut(
        **await notification_service.upsert_preference(
            db,
            user=user,
            type_alerte=type_alerte,
            toujours_demander=body.toujours_demander,
            regle_auto=body.regle_auto,
        )
    )


@router.get("/users/me/notifications", response_model=list[NotificationLogOut])
async def list_notifications(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    depuis: Annotated[datetime | None, Query()] = None,
) -> list[NotificationLogOut]:
    rows = await notification_service.list_notifications(db, user=user, depuis=depuis)
    return [NotificationLogOut(**row) for row in rows]


@router.post("/notifications/{notification_id}/reponse", response_model=NotificationReponseOut)
async def respond_notification(
    notification_id: UUID,
    body: NotificationReponseIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> NotificationReponseOut:
    return NotificationReponseOut(
        **await notification_service.respond(
            db, user=user, notification_id=notification_id, reponse=body.reponse
        )
    )

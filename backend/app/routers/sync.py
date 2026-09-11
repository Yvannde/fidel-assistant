"""Router Sync V2 — /sync/push + /sync/pull."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.sync import SyncPushIn, SyncPushOut, SyncPullOut
from app.services import sync_service

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/push", response_model=SyncPushOut)
async def sync_push(
    body: SyncPushIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> SyncPushOut:
    mutations = [m.model_dump() for m in body.mutations]
    result = await sync_service.push_mutations(db, user=user, mutations=mutations)
    return SyncPushOut(**result)


@router.get("/pull", response_model=SyncPullOut)
async def sync_pull(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    since: Annotated[str | None, Query()] = None,
) -> SyncPullOut:
    result = await sync_service.pull_delta(db, user=user, since=since)
    return SyncPullOut(**result)

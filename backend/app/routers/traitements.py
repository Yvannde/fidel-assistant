from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.medication import MedicamentCreateIn, MedicamentOut
from app.services import patient_suivi_service

router = APIRouter(prefix="/traitements", tags=["traitements"])


@router.post("/{traitement_id}/medicaments", response_model=MedicamentOut, status_code=201)
async def create_medicament(
    traitement_id: UUID,
    body: MedicamentCreateIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MedicamentOut:
    horaires = [h.model_dump() for h in body.horaires]
    data = body.model_dump(exclude={"horaires"})
    data["horaires"] = horaires
    return MedicamentOut(
        **await patient_suivi_service.create_medicament(
            db, user=user, traitement_id=traitement_id, data=data
        )
    )

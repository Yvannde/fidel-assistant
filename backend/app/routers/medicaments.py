from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.medication import (
    HoraireIn,
    HoraireOut,
    MedicamentOut,
    MedicamentStockIn,
    MedicamentStockOut,
    MedicamentUpdateIn,
)
from app.services import patient_suivi_service

router = APIRouter(prefix="/medicaments", tags=["medicaments"])


@router.patch("/{medicament_id}", response_model=MedicamentOut)
async def update_medicament(
    medicament_id: UUID,
    body: MedicamentUpdateIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MedicamentOut:
    data = body.model_dump(exclude_unset=True)
    return MedicamentOut(
        **await patient_suivi_service.update_medicament(
            db, user=user, medicament_id=medicament_id, data=data
        )
    )


@router.patch("/{medicament_id}/stock", response_model=MedicamentStockOut)
async def update_stock(
    medicament_id: UUID,
    body: MedicamentStockIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MedicamentStockOut:
    return MedicamentStockOut(
        **await patient_suivi_service.update_stock(
            db, user=user, medicament_id=medicament_id, stock_restant=body.stock_restant
        )
    )


@router.post("/{medicament_id}/horaires", response_model=HoraireOut, status_code=201)
async def add_horaire(
    medicament_id: UUID,
    body: HoraireIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> HoraireOut:
    return HoraireOut(
        **await patient_suivi_service.add_horaire(
            db,
            user=user,
            medicament_id=medicament_id,
            heure=body.heure,
            jours=body.jours,
        )
    )

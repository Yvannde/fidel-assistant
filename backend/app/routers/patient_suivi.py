from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.medication import (
    DashboardOut,
    MedicamentOut,
    PatientTraitementCreateIn,
    PatientTraitementOut,
    PriseOut,
)
from app.services import patient_suivi_service

router = APIRouter(prefix="/patients", tags=["patients"])


@router.get("/me/dashboard", response_model=DashboardOut)
async def patient_dashboard(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> DashboardOut:
    return DashboardOut(**await patient_suivi_service.get_dashboard(db, user=user))


@router.get("/me/traitements", response_model=list[PatientTraitementOut])
async def list_traitements(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> list[PatientTraitementOut]:
    rows = await patient_suivi_service.list_traitements(db, user=user)
    return [PatientTraitementOut(**row) for row in rows]


@router.post("/me/traitements", response_model=PatientTraitementOut, status_code=201)
async def create_traitement(
    body: PatientTraitementCreateIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> PatientTraitementOut:
    data = body.model_dump()
    return PatientTraitementOut(
        **await patient_suivi_service.create_traitement(db, user=user, data=data)
    )


@router.get("/me/medicaments", response_model=list[MedicamentOut])
async def list_medicaments(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> list[MedicamentOut]:
    rows = await patient_suivi_service.list_medicaments(db, user=user)
    return [MedicamentOut(**row) for row in rows]


@router.get("/me/prises", response_model=list[PriseOut])
async def list_prises(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    date: Annotated[str | None, Query(alias="date")] = None,
) -> list[PriseOut]:
    from datetime import date as date_type

    target = date_type.fromisoformat(date) if date else None
    rows = await patient_suivi_service.list_prises(db, user=user, target_date=target)
    return [PriseOut(**row) for row in rows]

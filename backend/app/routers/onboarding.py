from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.onboarding import (
    BesoinSuiviIn,
    BesoinSuiviOut,
    InfosIn,
    MaladieOut,
    OnboardingStatusOut,
    OnboardingStepOut,
    PermissionsIn,
    TraitementIn,
)
from app.services import onboarding_service

router = APIRouter(prefix="/onboarding", tags=["onboarding"])


@router.get("/status", response_model=OnboardingStatusOut)
async def onboarding_status(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> OnboardingStatusOut:
    return OnboardingStatusOut(**await onboarding_service.status(db, user=user))


@router.post("/infos", response_model=OnboardingStepOut)
async def onboarding_infos(
    body: InfosIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> OnboardingStepOut:
    data = await onboarding_service.save_infos(
        db,
        user=user,
        nom_complet=body.nom_complet,
        date_naissance=body.date_naissance,
        sexe=body.sexe,
        localisation=body.localisation,
        phone=body.phone,
    )
    return OnboardingStepOut(**data)


@router.post("/besoin-suivi", response_model=BesoinSuiviOut)
async def onboarding_besoin_suivi(
    body: BesoinSuiviIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> BesoinSuiviOut:
    data = await onboarding_service.set_besoin_suivi(db, user=user, actif=body.actif)
    return BesoinSuiviOut(**data)


@router.get("/maladies", response_model=list[MaladieOut])
async def onboarding_maladies(db: Annotated[AsyncSession, Depends(get_db)]) -> list[MaladieOut]:
    rows = await onboarding_service.list_maladies(db)
    return [MaladieOut(**row) for row in rows]


@router.post("/patient/traitement", response_model=OnboardingStepOut)
async def onboarding_traitement(
    body: TraitementIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> OnboardingStepOut:
    items = None
    if body.traitements:
        items = [t.model_dump() for t in body.traitements]
    data = await onboarding_service.save_traitement(
        db,
        user=user,
        en_traitement=body.en_traitement,
        traitements=items,
    )
    return OnboardingStepOut(**data)


@router.post("/patient/permissions", response_model=OnboardingStepOut)
async def onboarding_permissions(
    body: PermissionsIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> OnboardingStepOut:
    data = await onboarding_service.save_permissions(
        db,
        user=user,
        notifications_accordees=body.notifications_accordees,
        batterie_exemptee=body.batterie_exemptee,
    )
    return OnboardingStepOut(**data)


@router.post("/complete", response_model=OnboardingStepOut)
async def onboarding_complete(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> OnboardingStepOut:
    return OnboardingStepOut(**await onboarding_service.complete(db, user=user))

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.aidant import (
    AidantPermissionsIn,
    AidantRelationOut,
    MessageOut,
)
from app.schemas.contact_urgence import ContactUrgenceIn, ContactUrgenceOut
from app.schemas.onboarding import ActivatePatientOut, PatientOut, SyncCodeOut
from app.services import aidant_service, contact_urgence_service, onboarding_service

router = APIRouter(prefix="/patients", tags=["patients"])


@router.post("/me/activate", response_model=ActivatePatientOut)
async def activate_patient(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> ActivatePatientOut:
    return ActivatePatientOut(**await onboarding_service.activate_patient(db, user=user))


@router.get("/me", response_model=PatientOut)
async def get_patient_me(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> PatientOut:
    return PatientOut(**await onboarding_service.get_patient_me(db, user=user))


@router.post("/me/sync-code", response_model=SyncCodeOut)
async def create_sync_code(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> SyncCodeOut:
    return SyncCodeOut(**await onboarding_service.create_sync_code(db, user=user))


@router.get("/me/aidants", response_model=list[AidantRelationOut])
async def list_my_aidants(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> list[AidantRelationOut]:
    rows = await aidant_service.list_patient_aidants(db, user=user)
    return [AidantRelationOut(**row) for row in rows]


@router.patch("/me/aidants/{aidant_id}/permissions", response_model=AidantRelationOut)
async def update_aidant_permissions(
    aidant_id: UUID,
    body: AidantPermissionsIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> AidantRelationOut:
    return AidantRelationOut(
        **await aidant_service.update_aidant_permissions(
            db,
            user=user,
            aidant_id=aidant_id,
            niveau_permission=body.niveau_permission.model_dump(),
        )
    )


@router.delete("/me/aidants/{aidant_id}", response_model=MessageOut)
async def revoke_aidant(
    aidant_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    return MessageOut(
        **await aidant_service.revoke_aidant(db, user=user, aidant_id=aidant_id)
    )


@router.get("/me/contacts-urgence", response_model=list[ContactUrgenceOut])
async def list_contacts_urgence(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> list[ContactUrgenceOut]:
    rows = await contact_urgence_service.list_contacts(db, user=user)
    return [ContactUrgenceOut(**row) for row in rows]


@router.post("/me/contacts-urgence", response_model=ContactUrgenceOut, status_code=201)
async def create_contact_urgence(
    body: ContactUrgenceIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> ContactUrgenceOut:
    return ContactUrgenceOut(
        **await contact_urgence_service.create_contact(
            db,
            user=user,
            nom=body.nom,
            telephone=body.telephone,
            relation=body.relation,
        )
    )


@router.delete("/me/contacts-urgence/{contact_id}", response_model=MessageOut)
async def delete_contact_urgence(
    contact_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> MessageOut:
    return MessageOut(
        **await contact_urgence_service.delete_contact(
            db, user=user, contact_id=contact_id
        )
    )

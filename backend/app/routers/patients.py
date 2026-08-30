from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.audio_validation import read_upload_limited
from app.deps import get_current_user, get_db
from app.models import User
from app.schemas.aidant import (
    AidantPermissionsIn,
    AidantRelationOut,
    MessageOut,
)
from app.schemas.checkin_sos import CheckInIn, CheckInOut, SosTriggerOut
from app.schemas.constante import ConstanteCreateOut, ConstanteIn, ConstanteOut
from app.schemas.contact_urgence import ContactUrgenceIn, ContactUrgenceOut
from app.schemas.onboarding import (
    ActivatePatientOut,
    PatientOut,
    PatientUpdateIn,
    SyncCodeOut,
)
from app.schemas.voix_rappel import VoixRappelOut
from app.services import (
    aidant_service,
    checkin_sos_service,
    constante_service,
    contact_urgence_service,
    onboarding_service,
    voix_rappel_service,
)

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


@router.patch("/me", response_model=PatientOut)
async def update_patient_me(
    body: PatientUpdateIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> PatientOut:
    return PatientOut(
        **await onboarding_service.update_patient_me(
            db, user=user, data=body.model_dump(exclude_unset=True)
        )
    )


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


@router.post("/me/check-in", response_model=CheckInOut, status_code=201)
async def create_check_in(
    body: CheckInIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> CheckInOut:
    return CheckInOut(
        **await checkin_sos_service.create_check_in(db, user=user, statut=body.statut)
    )


@router.get("/me/check-in", response_model=list[CheckInOut])
async def list_check_ins(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    depuis: Annotated[date | None, Query()] = None,
) -> list[CheckInOut]:
    rows = await checkin_sos_service.list_check_ins(db, user=user, depuis=depuis)
    return [CheckInOut(**row) for row in rows]


@router.post("/me/sos", response_model=SosTriggerOut, status_code=201)
async def trigger_sos(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> SosTriggerOut:
    return SosTriggerOut(**await checkin_sos_service.trigger_sos(db, user=user))


@router.get("/me/constantes", response_model=list[ConstanteOut])
async def list_constantes(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    type: Annotated[str | None, Query()] = None,
    depuis: Annotated[datetime | None, Query()] = None,
    jusqu_a: Annotated[datetime | None, Query()] = None,
) -> list[ConstanteOut]:
    rows = await constante_service.list_constantes(
        db, user=user, type_=type, depuis=depuis, jusqu_a=jusqu_a
    )
    return [ConstanteOut(**row) for row in rows]


@router.post("/me/constantes", response_model=ConstanteCreateOut, status_code=201)
async def create_constante(
    body: ConstanteIn,
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> ConstanteCreateOut:
    return ConstanteCreateOut(
        **await constante_service.create_constante(
            db,
            user=user,
            type_=body.type,
            valeur=body.valeur,
            unite=body.unite,
            mesure_at=body.mesure_at,
            source=body.source,
        )
    )


@router.get("/me/voix-rappel", response_model=VoixRappelOut)
async def get_voix_rappel(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> VoixRappelOut:
    return VoixRappelOut(**await voix_rappel_service.get_voix(db, user=user))


@router.put("/me/voix-rappel", response_model=VoixRappelOut)
async def put_voix_rappel(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
    type: Annotated[str, Form()],
    fichier: Annotated[UploadFile | None, File()] = None,
) -> VoixRappelOut:
    data: bytes | None = None
    filename: str | None = None
    content_type: str | None = None
    if fichier is not None:
        data = await read_upload_limited(fichier)
        filename = fichier.filename
        content_type = fichier.content_type
    return VoixRappelOut(
        **await voix_rappel_service.upsert_patient_voix(
            db,
            user=user,
            type_=type,
            filename=filename,
            content_type=content_type,
            data=data,
        )
    )


@router.get("/me/voix-rappel/fichier")
async def download_voix_rappel(
    db: Annotated[AsyncSession, Depends(get_db)],
    user: Annotated[User, Depends(get_current_user)],
) -> FileResponse:
    path, media_type = await voix_rappel_service.resolve_audio_file(db, user=user)
    return FileResponse(
        path,
        media_type=media_type,
        filename=path.name,
        content_disposition_type="inline",
    )

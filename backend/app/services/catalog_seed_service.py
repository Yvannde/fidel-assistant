"""Seed catalogue maladies, configs et protocoles de référence."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import (
    Maladie,
    MaladieConfig,
    ProtocoleMedicamentSuggere,
    ProtocoleTraitement,
)

# Questions onboarding par code maladie (schéma JSON pour l'app)
_QUESTIONS_TB = [
    {
        "code": "dot_supervise",
        "type": "bool",
        "label": "Ta prise est-elle supervisée (DOT) ?",
        "required": False,
    },
]
_QUESTIONS_DIABETE = [
    {
        "code": "type_diabete",
        "type": "enum",
        "label": "Type de diabète",
        "required": True,
        "options": ["type_1", "type_2", "gestationnel", "inconnu"],
    },
    {
        "code": "mode_traitement",
        "type": "enum",
        "label": "Traitement actuel",
        "required": True,
        "options": ["insuline", "oral", "les_deux", "aucun"],
    },
]
_QUESTIONS_VIH = [
    {
        "code": "notifications_discretes",
        "type": "bool",
        "label": "Rappels discrets (sans nom du médicament) ?",
        "required": False,
    },
]
_QUESTIONS_AUTRE = [
    {
        "code": "maladie_libelle",
        "type": "string",
        "label": "Précise ta maladie",
        "required": True,
    },
]

_CATALOGUE: list[dict] = [
    {
        "code": "tuberculose",
        "nom": "Tuberculose",
        "description": "Traitement antituberculeux",
        "constantes": ["poids", "temperature"],
        "duree_jours": 180,
        "questions": _QUESTIONS_TB,
        "protocoles": [
            {
                "code": "tb_standard",
                "libelle": "Protocole standard (2RHZE / 4RH)",
                "phase_cible": "debut",
                "duree_jours": 180,
                "medicaments": [
                    {
                        "nom": "RHZE (association)",
                        "dosage": "4 comprimés",
                        "forme": "comprime",
                        "prise_avec_repas": "indifferent",
                        "horaires": [{"heure": "08:00", "jours": ["tous"]}],
                    },
                ],
            },
        ],
    },
    {
        "code": "diabete",
        "nom": "Diabète",
        "description": "Suivi glycémique et traitement",
        "constantes": ["glycemie", "poids"],
        "duree_jours": None,
        "questions": _QUESTIONS_DIABETE,
        "protocoles": [
            {
                "code": "db_metformine",
                "libelle": "Metformine (exemple)",
                "phase_cible": "maintenance",
                "duree_jours": None,
                "medicaments": [
                    {
                        "nom": "Metformine",
                        "dosage": "500 mg",
                        "forme": "comprime",
                        "prise_avec_repas": "apres_repas",
                        "horaires": [
                            {"heure": "08:00", "jours": ["tous"]},
                            {"heure": "20:00", "jours": ["tous"]},
                        ],
                    },
                ],
            },
        ],
    },
    {
        "code": "hypertension",
        "nom": "Hypertension",
        "description": "Suivi tensionnel",
        "constantes": ["tension", "poids"],
        "duree_jours": None,
        "questions": [],
        "protocoles": [
            {
                "code": "ht_amlodipine",
                "libelle": "Amlodipine (exemple)",
                "phase_cible": "maintenance",
                "duree_jours": None,
                "medicaments": [
                    {
                        "nom": "Amlodipine",
                        "dosage": "5 mg",
                        "forme": "comprime",
                        "prise_avec_repas": "indifferent",
                        "horaires": [{"heure": "08:00", "jours": ["tous"]}],
                    },
                ],
            },
        ],
    },
    {
        "code": "vih",
        "nom": "VIH",
        "description": "Traitement antirétroviral",
        "constantes": ["poids"],
        "duree_jours": None,
        "questions": _QUESTIONS_VIH,
        "notifications_discretes": True,
        "protocoles": [
            {
                "code": "vih_tar_1x",
                "libelle": "TAR 1 prise / jour (exemple)",
                "phase_cible": "maintenance",
                "duree_jours": None,
                "medicaments": [
                    {
                        "nom": "TAR (association)",
                        "dosage": "1 comprimé",
                        "forme": "comprime",
                        "prise_avec_repas": "indifferent",
                        "horaires": [{"heure": "21:00", "jours": ["tous"]}],
                    },
                ],
            },
        ],
    },
    {
        "code": "autre",
        "nom": "Autre",
        "description": "Autre pathologie chronique",
        "constantes": ["poids", "humeur"],
        "duree_jours": None,
        "questions": _QUESTIONS_AUTRE,
        "protocoles": [],
    },
]


async def ensure_catalogue(db: AsyncSession) -> None:
    """Idempotent : crée ou met à jour le catalogue maladies + protocoles."""
    result = await db.execute(select(Maladie).options(selectinload(Maladie.config)))
    all_maladies = list(result.scalars().all())
    existing_by_code = {m.code: m for m in all_maladies if m.code}
    existing_by_nom = {m.nom: m for m in all_maladies}

    for item in _CATALOGUE:
        maladie = existing_by_code.get(item["code"]) or existing_by_nom.get(item["nom"])
        if maladie is None:
            maladie = Maladie(
                code=item["code"],
                nom=item["nom"],
                description=item["description"],
                actif=True,
            )
            db.add(maladie)
            await db.flush()
            existing_by_code[item["code"]] = maladie
            existing_by_nom[item["nom"]] = maladie
        else:
            maladie.code = item["code"]
            maladie.nom = item["nom"]
            maladie.description = item["description"]
            maladie.actif = True

        cfg_result = await db.execute(
            select(MaladieConfig).where(MaladieConfig.maladie_id == maladie.id)
        )
        config = cfg_result.scalar_one_or_none()
        if config is None:
            db.add(
                MaladieConfig(
                    maladie_id=maladie.id,
                    questions_onboarding=item["questions"],
                    constantes_prioritaires=item["constantes"],
                    duree_traitement_jours_typique=item["duree_jours"],
                    notifications_discretes_defaut=item.get("notifications_discretes", False),
                )
            )
        else:
            config.questions_onboarding = item["questions"]
            config.constantes_prioritaires = item["constantes"]
            config.duree_traitement_jours_typique = item["duree_jours"]
            config.notifications_discretes_defaut = item.get("notifications_discretes", False)

        proto_result = await db.execute(
            select(ProtocoleTraitement).where(ProtocoleTraitement.maladie_id == maladie.id)
        )
        protos_by_code = {p.code: p for p in proto_result.scalars().all()}

        for idx, proto in enumerate(item["protocoles"]):
            row = protos_by_code.get(proto["code"])
            if row is None:
                row = ProtocoleTraitement(
                    maladie_id=maladie.id,
                    code=proto["code"],
                    libelle=proto["libelle"],
                    phase_cible=proto.get("phase_cible"),
                    duree_jours=proto.get("duree_jours"),
                    ordre=idx,
                    actif=True,
                )
                db.add(row)
                await db.flush()
                protos_by_code[proto["code"]] = row
            else:
                row.libelle = proto["libelle"]
                row.phase_cible = proto.get("phase_cible")
                row.duree_jours = proto.get("duree_jours")
                row.ordre = idx
                row.actif = True

            med_result = await db.execute(
                select(ProtocoleMedicamentSuggere).where(
                    ProtocoleMedicamentSuggere.protocole_id == row.id
                )
            )
            meds_by_nom = {m.nom: m for m in med_result.scalars().all()}

            for midx, med in enumerate(proto["medicaments"]):
                med_row = meds_by_nom.get(med["nom"])
                if med_row is None:
                    db.add(
                        ProtocoleMedicamentSuggere(
                            protocole_id=row.id,
                            nom=med["nom"],
                            dosage=med["dosage"],
                            forme=med["forme"],
                            prise_avec_repas=med.get("prise_avec_repas"),
                            horaires_suggestion=med["horaires"],
                            ordre=midx,
                            actif=True,
                        )
                    )
                else:
                    med_row.dosage = med["dosage"]
                    med_row.forme = med["forme"]
                    med_row.prise_avec_repas = med.get("prise_avec_repas")
                    med_row.horaires_suggestion = med["horaires"]
                    med_row.ordre = midx
                    med_row.actif = True

    await db.flush()


async def ensure_default_maladies(db: AsyncSession) -> None:
    """Compatibilité : délègue au seed catalogue complet."""
    await ensure_catalogue(db)
    await db.commit()


async def list_maladies_payload(db: AsyncSession) -> list[dict]:
    """Liste maladies + config pour l'API (sans lazy-load après commit)."""
    await ensure_catalogue(db)

    maladies = (
        await db.execute(select(Maladie).where(Maladie.actif.is_(True)).order_by(Maladie.nom))
    ).scalars().all()
    if not maladies:
        await db.commit()
        return []

    ids = [m.id for m in maladies]
    configs = (
        await db.execute(select(MaladieConfig).where(MaladieConfig.maladie_id.in_(ids)))
    ).scalars().all()
    cfg_map = {c.maladie_id: c for c in configs}

    payload = [
        {
            "id": m.id,
            "code": m.code,
            "nom": m.nom,
            "description": m.description,
            "constantes_prioritaires": (
                cfg_map[m.id].constantes_prioritaires if m.id in cfg_map else []
            ),
            "questions_onboarding": (
                cfg_map[m.id].questions_onboarding if m.id in cfg_map else []
            ),
        }
        for m in maladies
    ]
    await db.commit()
    return payload

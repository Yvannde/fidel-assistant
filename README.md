# Fidel Assistant

Plateforme mobile **gratuite et open source** d’accompagnement des patients dans la prise de leurs médicaments et le suivi de leur santé — en particulier pour les traitements chroniques (tuberculose, diabète, hypertension, VIH, etc.), avec un focus sur le contexte camerounais et africain (connectivité faible, téléphones basiques, réseau familial fort).

> **Ce n’est jamais un outil de diagnostic ni un substitut au médecin.**  
> C’est un **compagnon d’accompagnement**.

## Règle produit absolue

```
OBSERVER → ENCOURAGER / INFORMER → PROPOSER → ATTENDRE LE CONSENTEMENT EXPLICITE
```

Le système ne contacte jamais un tiers (aidant, médecin, urgence) automatiquement, sauf si le patient a explicitement pré-autorisé cette règle.

## Stack

| Couche | Techno |
|---|---|
| Backend | Python + FastAPI (`/api/v1`) — prod : `https://educampro.edu.cm` |
| Base de données | Neon (Postgres serverless) + Alembic |
| Mobile | Flutter (Android / iOS), offline-first |
| Auth | JWT + OTP maison + Google OAuth (IdP) |

## Structure du dépôt

```
.
├── backend/          # API FastAPI
├── mobile/           # Application Flutter
├── skills/           # Specs & contrats pour contributeurs / agents IA
├── docs/             # Documentation projet
├── .cursor/          # Architecture Cursor (@architecture)
└── .github/          # CI, templates issues & PR
```

## Prérequis

- Python **3.12+**
- Flutter **3.22+** (stable)
- Compte [Neon](https://neon.tech) (Postgres) pour le backend
- Git

## Démarrage rapide

### Backend

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate

pip install -e ".[dev]"
cp .env.example .env
# Éditer .env : DATABASE_URL, JWT_SECRET, etc.

alembic upgrade head
uvicorn app.main:app --reload --port 8000
```

API docs : http://localhost:8000/docs

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

Configurer l’URL de l’API dans `mobile/lib/core/config/` (voir `.env.example` côté backend).

## Documentation

| Document | Contenu |
|---|---|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Comment contribuer |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Code de conduite |
| [SECURITY.md](SECURITY.md) | Signalement de vulnérabilités |
| [skills/](skills/) | Specs produit & techniques (contrats) |
| [.cursor/architecture.md](.cursor/architecture.md) | Point d’entrée architecture |

## Rôles (V1)

- **Patient** — suivi personnel (médicaments, constantes, check-in)
- **Aidant** — accompagne un ou plusieurs patients (permissions par relation)

## Licence

Apache License 2.0 — voir [LICENSE](LICENSE).

## Avertissement santé

Ce logiciel fournit des rappels et un suivi d’observance. Il **ne fournit pas** de diagnostic, de posologie générée automatiquement, ni de conseil médical. Toute décision de santé relève d’un professionnel qualifié.

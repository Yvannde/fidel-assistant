# Architecture — Fidel Assistant

Quand ce fichier est mentionné via `@architecture`, **lire le dossier `skills/`** avant toute décision technique ou produit.

## Ordre de lecture obligatoire

1. Toujours commencer par `skills/project-overview/SKILL.md`
2. Ensuite, charger les skills pertinentes selon la tâche (liste ci-dessous)
3. Les fichiers `data-model` et `api-contract` sont des **contrats** : les respecter à la lettre ; si un champ ou une route manque, modifier d’abord le skill concerné, puis coder

## Index des skills

| Skill | Chemin | Quand la lire |
|---|---|---|
| Vue d’ensemble | `skills/project-overview/SKILL.md` | **Toujours en premier** — mission, stack, règle de consentement |
| Auth & onboarding | `skills/auth-onboarding/SKILL.md` | Inscription, OTP, Google OAuth, JWT, onboarding patient/aidant, sync |
| Backend FastAPI | `skills/backend-fastapi/SKILL.md` | Routes, structure `app/`, erreurs, sécurité |
| Base Neon | `skills/database-neon/SKILL.md` | Migrations, conventions, usage MCP Neon |
| Modèle de données | `skills/data-model/SKILL.md` | Entités, champs, relations (contrat) |
| Contrat API | `skills/api-contract/SKILL.md` | Endpoints méthode/entrée/sortie/erreurs (contrat) |
| Mobile Flutter | `skills/mobile-flutter/SKILL.md` | Offline-first, rappels, Riverpod, UI |
| Moteur d’engagement | `skills/engagement-principle/SKILL.md` | Notifications, consentement, types d’alerte |

## Stack (rappel)

| Couche | Techno |
|---|---|
| Backend | Python + FastAPI (`/api/v1`) — prod : **`https://educampro.edu.cm`** |
| Base de données | Neon (Postgres) + Alembic + MCP Neon |
| Mobile | Flutter (offline-first) |
| Auth | Maison — JWT + OTP + **Google OAuth** (IdP uniquement ; pas Firebase Auth / Auth0 / Supabase Auth) |

## Règle produit absolue

```
OBSERVER → ENCOURAGER / INFORMER → PROPOSER → ATTENDRE LE CONSENTEMENT EXPLICITE
```

Aucun contact automatique d’un tiers (aidant, médecin, urgence) sans consentement explicite préalable, sauf SOS (consentement = geste SOS) et `regle_auto` opt-in configurée par le patient.

## Instructions pour l’agent

- Avant de coder : lire `project-overview`, puis les skills du module touché
- Avant une table / migration : `data-model` + `database-neon`
- Avant une route API ou un appel Flutter : `api-contract`
- Avant une notification / alerte : `engagement-principle`
- Ne jamais inventer un endpoint, une entité ou un type d’alerte absents des contrats — les documenter d’abord dans le skill concerné

# Architecture — Fidel Assistant

Quand ce fichier est mentionné via `@architecture`, **lire le dossier `skills/`** avant toute décision technique ou produit.

## Ordre de lecture obligatoire

1. Toujours commencer par `skills/project-overview/SKILL.md`
2. Ensuite, charger les skills pertinentes selon la tâche (liste ci-dessous)
3. Les fichiers `data-model` et `api-contract` sont des **contrats** : les respecter à la lettre ; si un champ ou une route manque, modifier d’abord le skill concerné, puis coder

## Décision produit clé — Capacités (pas de rôle exclusif)

Un compte n’est **pas** « patient **ou** aidant ».

| Capacité | Activation |
|---|---|
| Profil patient (suivi pour soi) | Onboarding (« Tu veux un suivi pour toi ? ») **ou** plus tard depuis l’accueil |
| Aidant (accompagner quelqu’un) | Depuis l’accueil via code / QR — **pas** pendant l’onboarding initial |

Les deux sont **cumulables** sur le même compte. Détail : `skills/auth-onboarding/SKILL.md`.

Onboarding initial : infos communes → besoin de suivi ? → (si oui) **step C léger** (maladie, phase, date début, attributs optionnels — **pas** de médicaments/horaires) + permissions device → home.  
Médicaments + horaires : wizard **après** la home, via `GET /patients/me/dashboard` (`prochaine_action: configurer_medicaments`).  
Permissions notifs/batterie : seulement si branche suivi perso (option A).

## Avancement V1 (backend sur `main`)

| Bloc | Statut | Notes |
|---|---|---|
| Auth (OTP, Google IdP, JWT, sessions, Resend, rate limits `/auth`) | **Fait** | Tests verts |
| Onboarding capacités + sync aidant + activer suivi depuis home | **Fait** | Step C léger ; pas de rôle exclusif |
| Catalogue maladies / protocoles (seed) + schéma 4 couches | **Fait** | Migration `b4e8c1a29f3d` appliquée sur Neon |
| API dashboard, traitements, médicaments, horaires, prises + `POST /prises/sync-offline` | **Fait** | Prises pré-générées à la création d’horaire |
| App Flutter (auth, onboarding, alarmes locales) | **À faire** | Prochain chantier |
| Constantes / check-in / SOS / moteur `NotificationEngine` | **À faire** | Contrats existent, pas encore implémentés |

**Rappels médicaments** : 100 % **notification locale** sur le téléphone (offline, même avion). FastAPI ne sonne pas et ne poll pas les doses. Pas de Celery/Redis en V1. FCM (plus tard) uniquement pour l’aidant, et seulement via `engagement-principle` (`regle_auto` opt-in — jamais d’alerte tiers automatique).

## Index des skills

| Skill | Chemin | Quand la lire |
|---|---|---|
| Vue d’ensemble | `skills/project-overview/SKILL.md` | **Toujours en premier** — mission, stack, capacités, consentement |
| Auth & onboarding | `skills/auth-onboarding/SKILL.md` | Inscription, OTP, Google, JWT, onboarding capacités, sync aidant |
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
| Emails | Resend (`@educampro.edu.cm`) |

## Règle produit absolue

```
OBSERVER → ENCOURAGER / INFORMER → PROPOSER → ATTENDRE LE CONSENTEMENT EXPLICITE
```

Aucun contact automatique d’un tiers (aidant, médecin, urgence) sans consentement explicite préalable, sauf SOS (consentement = geste SOS) et `regle_auto` opt-in configurée par le patient.

## Offline-first (rappel)

- Critique (rappels, confirmations de prise) : **côté app** + sync (`POST /prises/sync-offline` — **déjà** côté API).
- Auth (inscription, OTP, login, refresh) : **online**. Session locale via JWT sécurisés après login.

## Instructions pour l’agent

- Avant de coder : lire `project-overview`, puis les skills du module touché
- Avant une table / migration : `data-model` + `database-neon`
- Avant une route API ou un appel Flutter : `api-contract`
- Avant une notification / alerte : `engagement-principle`
- Ne jamais inventer un endpoint, une entité ou un type d’alerte absents des contrats — les documenter d’abord dans le skill concerné
- Ne jamais réintroduire un choix de rôle exclusif `patient|aidant` dans l’UI ou l’API

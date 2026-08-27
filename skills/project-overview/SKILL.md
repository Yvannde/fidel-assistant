---
name: project-overview
description: Vision, principes directeurs, stack technique et architecture générale de la plateforme d'accompagnement patient (nom de code à définir). À LIRE EN PREMIER par tout agent IA avant toute tâche de code sur ce projet, quel que soit le sujet (backend, mobile, base de données). Utiliser aussi cette skill dès qu'une décision technique ou produit semble ambiguë, pour vérifier qu'elle respecte la philosophie du projet.
---

# Vue d'ensemble du projet

## Mission

Une plateforme mobile 100% gratuite et open source qui accompagne les patients (en particulier sur des traitements chroniques : tuberculose, diabète, hypertension, VIH, etc.) dans la prise de leurs médicaments et le suivi de leur santé, avec un focus sur le contexte camerounais/africain (connectivité faible, téléphones basiques, réseau familial/communautaire fort).

Ce n'est **jamais** un outil de diagnostic ni un substitut au médecin. C'est un **compagnon d'accompagnement**.

## Règle produit absolue (s'applique à TOUTE fonctionnalité de notification/alerte)

```
OBSERVER → ENCOURAGER / INFORMER → PROPOSER → ATTENDRE LE CONSENTEMENT EXPLICITE
```

- Le système ne contacte jamais un tiers (médecin, aidant, urgence) automatiquement, **sauf** si le patient a explicitement pré-autorisé cette règle précise à l'avance (ex : "préviens mon aidant si je ne fais pas mon check-in pendant 48h").
- Le ton est toujours bienveillant. On valorise le progrès avant de signaler une anomalie.
- Toute décision de code qui ferait qu'une alerte parte vers un tiers sans passer par un consentement explicite (bouton "Oui, préviens") est un bug produit, même si le code fonctionne techniquement. En cas de doute, un agent IA doit poser la question plutôt que de supposer.

> Si tu (agent IA) codes une fonctionnalité liée aux notifications, aux alertes de santé, ou au partage de données entre rôles, et que tu ne vois pas clairement l'étape de consentement dans la spec qu'on t'a donnée, arrête-toi et demande — ne comble pas le vide toi-même.

## Rôles utilisateurs

**V1 (à construire maintenant)**
- `patient` — utilise l'app pour son propre suivi
- `aidant` (garde-malade) — accompagne un ou plusieurs patients, synchronisé avec eux

**V2 (hors scope actuel, mais le modèle de données doit rester extensible pour les accueillir sans tout refondre)**
- `agent_sante_communautaire`
- `medecin`
- `pharmacien`

Relation patient ↔ aidant : **many-to-many**. Un patient peut avoir plusieurs aidants, un aidant peut suivre plusieurs patients. Chaque relation a son propre niveau de permission (voir skill `auth-onboarding`).

## Hébergement (production)

| Élément | Valeur |
|---|---|
| Domaine backend | **`educampro.edu.cm`** |
| Base URL API | `https://educampro.edu.cm` (routes sous `/api/v1/...`) |
| Docs Swagger (prod) | `https://educampro.edu.cm/docs` |

Le backend sera déployé sur ce domaine le moment venu. En développement local, continuer d’utiliser `localhost` / émulateur. CORS, cookies (si un jour web), et redirect URIs Google OAuth doivent inclure `https://educampro.edu.cm`.

## Stack technique

| Composant | Techno | Notes |
|---|---|---|
| Backend | Python + FastAPI | Documentation interactive auto-générée sur `/docs` (Swagger UI) et `/redoc` — à utiliser systématiquement pour tester les endpoints pendant le dev, avant d'écrire des tests automatisés |
| Base de données | Neon (Postgres serverless) | Administrée via le **MCP Neon** — les agents IA doivent utiliser les outils MCP pour créer/inspecter/migrer le schéma, jamais de modification manuelle en prod |
| Migrations | Alembic (ou équivalent versionné) | Toute évolution de schéma passe par une migration versionnée, committée dans le repo |
| Mobile | Flutter | Un seul codebase Android/iOS |
| Auth | Maison (JWT + OTP) + **Google OAuth** | Pas de Firebase Auth / Auth0 / Supabase Auth comme fournisseur de session. Session = JWT maison. Google sert uniquement d’**IdP** (vérification du `id_token` Google côté FastAPI, puis émission de nos access/refresh tokens). Email+OTP reste disponible. |
| Hébergement API | `educampro.edu.cm` | Domaine de production du backend |
| Communication agents ↔ DB | MCP | Les agents IA interrogent/modifient Neon via le serveur MCP configuré pour ce projet, pas via des credentials en dur dans le code |

## Conventions générales pour les agents IA

1. Toujours lire cette skill avant de commencer une tâche, quel que soit le module concerné.
2. Toute nouvelle route API doit être immédiatement testable via `/docs` : utiliser des `response_model` Pydantic stricts, documenter les codes d'erreur possibles.
3. Aucune modification de schéma de base de données sans migration versionnée passant par le MCP Neon.
4. Respecter strictement la règle "Observer → Proposer → Consentement" (voir plus haut) pour tout ce qui touche notifications, alertes, partage de données entre rôles.
5. Ne jamais coder de conseil médical automatisé (posologie, diagnostic, interaction) sans que ce soit explicitement une donnée validée en amont par un professionnel de santé et fournie comme contenu statique/révisé — jamais généré à la volée sans garde-fou.
6. Le mode hors-ligne est un prérequis, pas une option : toute fonctionnalité critique (rappels de médicaments notamment) doit fonctionner sans connexion et se synchroniser au retour du réseau.

## Autres fichiers skills du projet

- `auth-onboarding/SKILL.md` — flux complet d'inscription, vérification OTP, onboarding patient et aidant, synchronisation patient-aidant
- `backend-fastapi/SKILL.md` — conventions API, structure de dossiers, gestion des erreurs
- `database-neon/SKILL.md` — conventions de nommage, de migration, usage du MCP Neon
- `data-model/SKILL.md` — modèle de données formel complet (toutes les entités, champs, relations) — contrat à respecter à la lettre
- `api-contract/SKILL.md` — contrat formel de tous les endpoints API (méthode, entrée, sortie, erreurs) — contrat à respecter à la lettre
- `mobile-flutter/SKILL.md` — architecture de l'app, gestion d'état, mode offline-first, notifications locales
- `engagement-principle/SKILL.md` — moteur de notification centralisé qui implémente la règle "Observer → Proposer → Consentement" (Volet 7), registre de tous les types d'alerte

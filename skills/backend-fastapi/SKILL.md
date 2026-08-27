---
name: backend-fastapi
description: Conventions de structure, de code, de gestion des erreurs et de sécurité pour le backend Python FastAPI de la plateforme. À consulter par tout agent IA avant d'écrire ou modifier une route API, un service, un modèle Pydantic, ou toute logique métier backend. Lire project-overview/SKILL.md et auth-onboarding/SKILL.md avant de commencer si la tâche touche à l'authentification.
---

# Backend — FastAPI

## Principe de base

Toute route doit être **immédiatement testable via `/docs`** (Swagger UI, généré automatiquement par FastAPI) et via `/redoc`. Ça veut dire concrètement :
- `response_model` Pydantic strict sur chaque route (jamais de `dict` brut en sortie)
- Exemples (`Config.json_schema_extra` ou `Field(examples=...)`) sur les schémas d'entrée pour que Swagger propose des payloads pré-remplis pendant le dev
- Codes d'erreur HTTP documentés explicitement (`responses={...}` sur le décorateur de route) pour chaque cas d'échec prévisible

## Structure de dossiers

```
app/
├── main.py                  # instanciation FastAPI, montage des routers, middlewares
├── core/
│   ├── config.py             # Settings (pydantic-settings), lecture des variables d'env
│   ├── security.py           # hashing mot de passe, création/validation JWT
│   └── exceptions.py         # exceptions custom + handlers globaux
├── db/
│   ├── session.py            # engine + session SQLAlchemy async, connexion Neon
│   └── base.py                # déclaration des modèles ORM de base
├── models/                   # modèles SQLAlchemy (un fichier par domaine : user.py, patient.py, traitement.py...)
├── schemas/                  # schémas Pydantic (input/output), séparés des modèles ORM
├── routers/                  # un fichier par domaine : auth.py, onboarding.py, patients.py, aidants.py...
├── services/                 # logique métier réutilisable (ex: otp_service.py, notification_service.py, sync_service.py)
├── deps.py                   # dépendances FastAPI communes (get_current_user, get_db, pagination...)
└── tests/                    # pytest, un dossier miroir de la structure app/
alembic/                      # migrations versionnées
```

Règle : **les routers ne contiennent pas de logique métier**. Un router appelle un service, le service fait le travail (accès DB, règles métier), le router se contente de valider l'entrée/sortie et de gérer les codes HTTP.

## Authentification (implémentation)

Voir `auth-onboarding/SKILL.md` pour le flux complet. Côté implémentation FastAPI :
- `core/security.py` : fonctions `hash_password`, `verify_password` (argon2 via `passlib` ou `argon2-cffi`), `create_access_token`, `create_refresh_token`, `decode_token`
- Dépendance `get_current_user` dans `deps.py` : décode le JWT depuis le header `Authorization: Bearer ...`, lève une `HTTPException(401)` si invalide/expiré
- Dépendance additionnelle `require_role(role)` pour restreindre certaines routes par rôle (ex: routes aidant vs patient)
- OTP : stocker un **hash** du code (pas le code en clair) en base, comme un mot de passe, avec expiration et compteur de tentatives
- Ne jamais renvoyer d'information sensible (hash, token complet d'un autre user, etc.) dans une réponse d'erreur

## Gestion des erreurs

- Toutes les exceptions métier héritent d'une classe custom (`AppException`) avec un `code` machine-readable (ex: `OTP_EXPIRED`, `SYNC_CODE_INVALID`) et un `message` humain
- Un handler global (`core/exceptions.py`) transforme ça en réponse JSON cohérente :
```json
{
  "error": {
    "code": "OTP_EXPIRED",
    "message": "Le code a expiré, demande-en un nouveau."
  }
}
```
- Jamais de stack trace ou de détail d'implémentation renvoyé au client en production
- Logger l'erreur complète côté serveur (avec contexte : user_id si dispo, route, timestamp), mais **jamais** de mot de passe, OTP en clair, ou token dans les logs

## Versioning

- Toutes les routes sous préfixe `/api/v1/...` dès le départ, même si une seule version existe pour l'instant — évite une migration douloureuse plus tard.

## Config et secrets

- `pydantic-settings` pour charger la config depuis les variables d'environnement (`.env` en dev, variables d'environnement réelles en prod — jamais de `.env` commité)
- Chaîne de connexion Neon, clé de signature JWT, credentials SMTP/email : toujours via `Settings`, jamais en dur dans le code

## Notifications et le moteur "Observer → Proposer → Consentement"

- Toute la logique de notification (rappels médicaments, alertes constantes, SOS, check-in) doit passer par un **service centralisé unique** (`services/notification_service.py`), pas de code de notification dispersé dans chaque router. Voir le Volet 7 des specs fonctionnelles pour le détail du principe.
- Ce service doit s'appuyer sur une table de préférences de consentement par utilisateur et par type d'alerte (cf. `database-neon/SKILL.md`), et journaliser chaque notification envoyée (destinataire, contenu, déclencheur) dans un journal d'audit.

## Tâches asynchrones

- Les envois d'email (OTP, notifications) doivent être **non-bloquants** : utiliser `BackgroundTasks` de FastAPI pour les cas simples, ou une file de tâches dédiée (ex: Celery/RQ/Arq) si le volume le justifie plus tard. Ne jamais faire attendre une requête HTTP le temps qu'un email parte.

## Tests

- `pytest` + `httpx.AsyncClient` pour tester les routes bout en bout
- Priorité de couverture : flux d'authentification complet (inscription, OTP, login, refresh, logout), synchronisation patient-aidant, moteur de notification (cas consentement accepté/refusé)
- Base de données de test : utiliser une branche Neon dédiée aux tests si possible (voir `database-neon/SKILL.md`), jamais la base de dev/prod

## CORS et sécurité HTTP

- CORS restreint aux origines connues (app mobile via son domaine d'API, pas de wildcard `*` en prod)
- Rate limiting sur les routes sensibles (login, OTP, mot de passe oublié) pour limiter le brute-force — même basique au départ (ex: `slowapi`), c'est un prérequis, pas un "nice to have"

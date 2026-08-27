# Specs & contrats (`skills/`)

Ces fichiers sont la **référence produit/technique** du projet.  
Tout contributeur (humain ou agent IA) les lit **avant** de coder le module concerné.

> Si un champ, une route ou un type d’alerte manque : **mettre à jour le skill d’abord**, puis le code.

## Ordre recommandé

1. [`project-overview/SKILL.md`](project-overview/SKILL.md) — toujours en premier  
2. Le skill du module touché (tableau ci-dessous)  
3. Les **contrats** si tu touches au schéma ou à l’API : `data-model`, `api-contract`

## Index

| Skill | Quand le lire |
|---|---|
| [project-overview](project-overview/SKILL.md) | Mission, stack, règle de consentement |
| [auth-onboarding](auth-onboarding/SKILL.md) | Inscription, OTP, Google, JWT, onboarding patient/aidant |
| [backend-fastapi](backend-fastapi/SKILL.md) | Structure API, erreurs, sécurité |
| [database-neon](database-neon/SKILL.md) | Migrations, conventions Neon |
| [data-model](data-model/SKILL.md) | **Contrat** — entités et champs |
| [api-contract](api-contract/SKILL.md) | **Contrat** — endpoints |
| [mobile-flutter](mobile-flutter/SKILL.md) | Offline-first, rappels, UI |
| [engagement-principle](engagement-principle/SKILL.md) | Notifications & consentement |

Voir aussi [`.cursor/architecture.md`](../.cursor/architecture.md) et [`docs/`](../docs/).

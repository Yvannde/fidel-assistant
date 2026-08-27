# Guide de contribution

Merci de contribuer à **Fidel Assistant**. Ce projet aide des patients (souvent en contexte de connectivité faible) : la fiabilité, le consentement et l’accessibilité passent avant les fancy features.

## Avant de coder

1. Lire [README.md](README.md) et la règle produit (Observer → Proposer → Consentement).
2. Lire les specs dans [`skills/`](skills/) — en particulier `project-overview`, puis le skill du module touché.
3. Les fichiers `skills/data-model/SKILL.md` et `skills/api-contract/SKILL.md` sont des **contrats** : si un champ ou une route manque, **mettre à jour le skill d’abord**, puis le code.

## Workflow Git

1. Fork (ou branche sur le dépôt si tu as les droits)
2. Branche descriptive : `feat/auth-otp`, `fix/prise-offline-sync`, `docs/...`
3. Commits clairs, en français ou anglais, style présent : `add OTP verification endpoint`
4. Ouvre une Pull Request vers `main` avec le template

## Standards techniques

### Backend (`backend/`)

- Routes sous `/api/v1/...`, testables via `/docs`
- `response_model` Pydantic strict ; erreurs au format `{ "error": { "code", "message" } }`
- Pas de logique métier dans les routers — passer par `services/`
- Migrations Alembic obligatoires pour tout changement de schéma
- Secrets uniquement via variables d’environnement (jamais commités)

### Mobile (`mobile/`)

- Offline-first pour les actions critiques (prises, constantes)
- Tokens dans `flutter_secure_storage` uniquement
- Fiabilité des rappels = priorité absolue
- Accessibilité par défaut (contraste, tailles système, gros boutons)

### Notifications

Toute alerte / proposition vers un tiers passe par le moteur décrit dans `skills/engagement-principle/SKILL.md`. **Pas d’envoi direct** depuis un router ou un écran.

## Tests

```bash
# Backend
cd backend && pytest

# Mobile
cd mobile && flutter test
```

Couvrir en priorité : auth (inscription → OTP → login), sync patient–aidant, consentement notifications.

## Signalement de bugs / idées

Utiliser les templates GitHub Issues. Pour une faille de sécurité : voir [SECURITY.md](SECURITY.md) — **ne pas** ouvrir d’issue publique.

## Code de conduite

En participant, tu acceptes le [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Licence des contributions

En soumettant une contribution, tu acceptes qu’elle soit publiée sous la **Apache License 2.0**.

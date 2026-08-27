# Guide de contribution

Merci de contribuer à **Fidel Assistant**. Ce projet aide des patients (souvent en contexte de connectivité faible) : la fiabilité, le consentement et l’accessibilité passent avant les fancy features.

## Parcours en 5 minutes

1. Lire [README.md](README.md) (mission + **état du projet**).
2. Lire [`skills/project-overview/SKILL.md`](skills/project-overview/SKILL.md).
3. Consulter [`skills/README.md`](skills/README.md) puis le skill du module que tu touches.
4. Si tu changes un champ / une route : mettre à jour **d’abord** `data-model` ou `api-contract`, puis le code.
5. Ouvrir une PR vers `main` avec le template GitHub.

Guides pratiques (setup Google, Resend, tests) : [`docs/`](docs/).

## Avant de coder

1. La règle produit (Observer → Proposer → Consentement) s’applique à **toute** alerte / partage.
2. Les fichiers `skills/data-model/SKILL.md` et `skills/api-contract/SKILL.md` sont des **contrats**.
3. Ne jamais committer `.env`, clés API, dumps DB.

## Workflow Git

1. Fork (ou branche sur le dépôt si tu as les droits)
2. Branche descriptive : `feat/...`, `fix/...`, `docs/...`, `test/...`
3. Commits clairs, français ou anglais, style présent : `add OTP verification endpoint`
4. Pull Request vers `main`
5. Après merge, la branche source est **supprimée automatiquement** — voulu

## Standards techniques

### Backend (`backend/`)

- Routes sous `/api/v1/...`, testables via `/docs`
- `response_model` Pydantic strict ; erreurs `{ "error": { "code", "message" } }`
- Pas de logique métier dans les routers — passer par `services/`
- Migrations Alembic obligatoires pour tout changement de schéma
- Secrets uniquement via variables d’environnement

### Mobile (`mobile/`)

- Offline-first pour les actions critiques (prises, constantes)
- Tokens dans `flutter_secure_storage` uniquement
- Fiabilité des rappels = priorité absolue
- Accessibilité par défaut (contraste, tailles système, gros boutons)

### Notifications

Toute alerte / proposition vers un tiers passe par `skills/engagement-principle/SKILL.md`. **Pas d’envoi direct** depuis un router ou un écran.

## Tests

```bash
# Backend (depuis backend/, venv activé)
pip install -e ".[dev]"
pytest -q
ruff check app

# Mobile
cd mobile && flutter test
```

Couvrir en priorité : auth, sync patient–aidant, consentement notifications.

## Signalement de bugs / idées

Utiliser les templates GitHub Issues. Pour une faille de sécurité : [SECURITY.md](SECURITY.md) — **ne pas** ouvrir d’issue publique.

## Code de conduite

En participant, tu acceptes le [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Licence des contributions

En soumettant une contribution, tu acceptes qu’elle soit publiée sous la **Apache License 2.0**.

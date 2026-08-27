# Backend FastAPI — Fidel Assistant

Démarrage rapide : [README racine](../README.md).

## Ce qui est en place

- Health : `GET /api/v1/health`
- Auth complète sous `/api/v1/auth/*` (contrat : [`skills/api-contract`](../skills/api-contract/SKILL.md))
- Emails OTP via Resend — [docs/email-resend.md](../docs/email-resend.md)
- Google Sign-In (IdP) — [docs/google-auth-setup.md](../docs/google-auth-setup.md)
- Batterie de tests — [docs/auth-test-battery.md](../docs/auth-test-battery.md)

## Configuration

```bash
cp .env.example .env
```

Variables minimales :

| Variable | Rôle |
|---|---|
| `DATABASE_URL` | Neon (connection **poolée**, `ssl=require`) |
| `JWT_SECRET` | Secret long et aléatoire |
| `RESEND_API_KEY` | Optionnel en local (sinon OTP loggé) |
| `EMAIL_FROM` | Ex. `Fidel Assistant <noreply@educampro.edu.cm>` |
| `GOOGLE_CLIENT_ID_*` | Android / iOS / Web |

## Base de données

```bash
alembic upgrade head
```

Tables auth : `users`, `otp_codes`, `cgu_acceptances`, `consentements_sante`, `sessions`.

## Lancer / tester

```bash
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
pytest -q
ruff check app
```

Docs interactives : http://127.0.0.1:8000/docs

## Structure

Conforme à `skills/backend-fastapi/SKILL.md` :

```
app/
├── main.py
├── core/          # config, security, exceptions
├── db/            # session SQLAlchemy async, base ORM
├── models/
├── schemas/
├── routers/
├── services/
├── deps.py
└── tests/
alembic/
```

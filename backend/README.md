# Backend FastAPI — Fidel Assistant

Voir le [README racine](../README.md) pour le démarrage rapide.

## Base de données (Neon)

- Projet Neon : `fidel-assistant` (`holy-morning-61098712`)
- Copier `.env.example` → `.env` et renseigner `DATABASE_URL` (connection **poolée**)
- Migrations : `alembic upgrade head`

Tables auth actuelles : `users`, `otp_codes`, `cgu_acceptances`, `consentements_sante`, `sessions`.

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

## Docs interactives

Une fois l’API lancée : `/docs` (Swagger) et `/redoc`.

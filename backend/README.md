# Backend FastAPI — Fidel Assistant

Voir le [README racine](../README.md) pour le démarrage rapide.

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

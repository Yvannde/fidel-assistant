# Raccourcis locaux — Fidel Assistant

.PHONY: backend-install backend-run backend-test mobile-get mobile-run mobile-test

backend-install:
	cd backend && python -m venv .venv && .venv/Scripts/pip install -e ".[dev]"

backend-run:
	cd backend && .venv/Scripts/uvicorn app.main:app --reload --port 8000

backend-test:
	cd backend && .venv/Scripts/pytest -q && .venv/Scripts/ruff check app

mobile-get:
	cd mobile && flutter pub get

mobile-run:
	cd mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

mobile-test:
	cd mobile && flutter test

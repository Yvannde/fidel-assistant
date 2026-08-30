# Application Flutter — Fidel Assistant

Structure conforme à `skills/mobile-flutter/SKILL.md` (feature-first, offline-first).

## Prérequis

- Flutter SDK 3.5+
- Backend local : `make backend-run` (port 8000)

## Config API

| Contexte | `API_BASE_URL` |
|---|---|
| Émulateur Android | `http://10.0.2.2:8000` (défaut) |
| Simulateur iOS / desktop | `http://127.0.0.1:8000` |
| Appareil physique (même Wi‑Fi) | `http://<IP-LAN-PC>:8000` |
| Production | `https://educampro.edu.cm` |

```bash
flutter pub get

# Android émulateur
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# iOS / Chrome
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Google Sign-In (plus tard) :

```bash
flutter run \
  --dart-define=API_BASE_URL=... \
  --dart-define=GOOGLE_CLIENT_ID_ANDROID=... \
  --dart-define=GOOGLE_CLIENT_ID_IOS=... \
  --dart-define=GOOGLE_CLIENT_ID_WEB=...
```

## Socle en place

- `core/config` — `AppConfig` + dart-defines
- `core/storage` — JWT dans `flutter_secure_storage`
- `core/network` — Dio + refresh Bearer automatique
- Features dossiers : auth, onboarding, medicaments, constantes, reseau, home
- Permissions Android : Internet, notifs, alarmes exactes, boot

## Prochaine étape

Écrans **auth + onboarding** branchés sur `/api/v1/auth` et `/api/v1/onboarding`.

# Batterie de tests auth

Branche : `test/auth-battery`  
Commande : `cd backend && .venv/Scripts/pytest -q`

## Couverture

| Zone | Fichier |
|---|---|
| Hash / JWT / OTP | `app/tests/test_security_auth.py` |
| Flux API email + Google mock | `app/tests/test_auth_api.py` |
| Health | `app/tests/test_health.py` |

Les tests API tournent sur **SQLite en mémoire** (OTP mocké, pas d’appel Resend/Neon).

## Clôture étape Auth V1 (backend)

Validé côté API FastAPI :

- Inscription email → OTP → mot de passe → CGU → consentement santé
- Login / refresh / logout / sessions
- Forgot / reset / change password
- Changement d’email
- Soft delete compte
- Google Sign-In (IdP mocké)

Prochaine étape produit : onboarding rôle (patient / aidant) + app Flutter auth.

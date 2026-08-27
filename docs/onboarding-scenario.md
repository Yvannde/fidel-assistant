# Scénario onboarding V1 (capacités)

Référence contrats : `skills/auth-onboarding`, `skills/api-contract`, `skills/data-model`.

## Principe

Pas de choix exclusif patient/aidant. Même compte = infos communes + capacités optionnelles cumulables.

## Flux initial

1. Auth (email OTP ou Google) + CGU + consentement santé  
2. Infos communes → `POST /onboarding/infos`  
3. « Tu veux un suivi pour toi ? »  
   - **Non** → `complete` → Home  
   - **Oui** → profil `Patient` → traitement → permissions device → `complete` → Home  

## Depuis la Home

- **Accompagner quelqu’un** → code/QR → `POST /aidants/me/sync`  
- **Activer mon suivi** (si pas encore patient) → `POST /patients/me/activate` puis modules traitement/permissions  
- Checklist soft : téléphone, urgence, voix…

## Exemples

| Personne | Parcours |
|---|---|
| Amina (TB) | Oui au suivi → home patient ; génère sync-code pour Paul |
| Paul (aidant only) | Non au suivi → home ; sync code Amina → devient aidant |
| Paul plus tard malade | Depuis home → activer mon suivi (sans tout recommencer) |
| Amina aide un cousin | Depuis home → sync autre patient (cumul patient + aidant) |

---
name: api-contract
description: Contrat formel de tous les endpoints API de la plateforme — méthode, chemin, entrée, sortie, erreurs possibles. C'est la référence commune obligatoire entre les agents backend (FastAPI) et mobile (Flutter) pour qu'ils avancent en parallèle sans désynchronisation. À consulter avant d'écrire une route backend ou un appel API côté app. Lire project-overview/SKILL.md, auth-onboarding/SKILL.md et data-model/SKILL.md en complément — ce fichier ne redéfinit pas les entités, il définit comment on y accède.
---

# Contrat des endpoints API

## Statut de ce document

Comme `data-model/SKILL.md`, ce fichier est un **contrat**. Toute route listée ici doit exister avec la signature décrite. Si un agent a besoin d'une route non listée, il **ajoute d'abord la route à ce fichier**, puis l'implémente — jamais l'inverse. Ça évite qu'un agent backend et un agent mobile divergent silencieusement sur un contrat non documenté.

Toutes les routes sont préfixées `/api/v1`. Toutes les routes marquées 🔒 nécessitent un `Authorization: Bearer <access_token>` valide. Les erreurs suivent le format défini dans `backend-fastapi/SKILL.md` : `{"error": {"code": "...", "message": "..."}}`.

---

## 1. Authentification

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| POST | `/auth/register` | `email`, `langue` | `{message}` — envoie l'OTP | `EMAIL_ALREADY_VERIFIED` |
| POST | `/auth/resend-otp` | `email`, `type` (`inscription`\|`reset_password`) | `{message}` | `RESEND_LIMIT_REACHED` |
| POST | `/auth/verify-otp` | `email`, `code` | `{temp_token}` — jeton temporaire pour finaliser l'inscription | `OTP_INVALID`, `OTP_EXPIRED`, `OTP_MAX_ATTEMPTS` |
| POST | `/auth/set-password` | `temp_token`, `password` | `{message}` | `TEMP_TOKEN_INVALID`, `PASSWORD_TOO_WEAK` |
| POST | `/auth/accept-cgu` | `temp_token` ou 🔒, `version` | `{message}` | `CGU_VERSION_OUTDATED` |
| POST | `/auth/accept-consentement-sante` | `temp_token` ou 🔒 | `{message}` | — |
| POST | `/auth/login` | `email`, `password` | `{access_token, refresh_token, expires_in, session_id, onboarding_step, has_patient_profile, is_aidant}` | `INVALID_CREDENTIALS`, `EMAIL_NOT_VERIFIED`, `LOGIN_RATE_LIMITED` |
| POST | `/auth/google` | `id_token`, `langue`, `fuseau_horaire?` | `{access_token, refresh_token, expires_in, session_id, onboarding_step, has_patient_profile, is_aidant, is_new_user, needs_cgu, needs_consentement_sante}` | `GOOGLE_TOKEN_INVALID`, `GOOGLE_EMAIL_NOT_VERIFIED`, `GOOGLE_AUD_MISMATCH` |
| POST | `/auth/refresh` | `refresh_token` | `{access_token, expires_in}` | `REFRESH_TOKEN_INVALID_OR_EXPIRED` |
| POST | `/auth/logout` | 🔒 `refresh_token` | `{message}` | — |
| POST | `/auth/forgot-password` | `email` | `{message}` — envoie OTP type `reset_password` | — |
| POST | `/auth/reset-password` | `email`, `code`, `nouveau_password` | `{message}` | `OTP_INVALID`, `OTP_EXPIRED` |
| GET | `/auth/me` | 🔒 | `{id, email, phone, nom_complet, date_naissance, sexe, localisation, onboarding_step, has_patient_profile, is_aidant, langue, fuseau_horaire, auth_providers, email_verified_at, has_password, needs_cgu, needs_consentement_sante}` | — |
| PATCH | `/auth/me` | 🔒 `langue?`, `fuseau_horaire?`, `phone?` | objet `/auth/me` mis à jour | — |
| POST | `/auth/change-password` | 🔒 `current_password?`, `nouveau_password` | `{message}` — `current_password` requis si un mot de passe existe déjà (compte email) ; optionnel si Google-only | `INVALID_CREDENTIALS`, `PASSWORD_TOO_WEAK` |
| POST | `/auth/link-google` | 🔒 `id_token` | `{message, auth_providers}` | `GOOGLE_TOKEN_INVALID`, `GOOGLE_AUD_MISMATCH`, `GOOGLE_ALREADY_LINKED` |
| POST | `/auth/request-email-change` | 🔒 `nouvel_email` | `{message}` — OTP envoyé au **nouvel** email | `EMAIL_ALREADY_VERIFIED` |
| POST | `/auth/confirm-email-change` | 🔒 `nouvel_email`, `code` | `{message, email}` | `OTP_INVALID`, `OTP_EXPIRED` |
| GET | `/auth/sessions` | 🔒 `current_session_id?` | `[{id, device_info, created_at, revoked_at, is_current}]` | — |
| POST | `/auth/logout-all` | 🔒 | `{message}` — révoque toutes les sessions | — |
| DELETE | `/auth/sessions/{session_id}` | 🔒 | `{message}` | `SESSION_NOT_FOUND` |
| DELETE | `/auth/me` | 🔒 `password?` | `{message}` — soft delete (`deleted_at`) ; `password` requis si le compte en a un | `INVALID_CREDENTIALS` |

> Le `temp_token` (courte durée, ex: 15 min) sert uniquement à enchaîner OTP → mot de passe → CGU → consentement santé sans exposer un access_token complet avant que le compte soit finalisé.

> **Google** : le backend vérifie l'`id_token` Google puis émet nos JWT. Si `needs_cgu` / `needs_consentement_sante` sont `true`, le client appelle les endpoints d'acceptation avec le Bearer token avant de poursuivre l'onboarding. En production, l'API est servie sur `https://educampro.edu.cm`.

> **Changement d'email** : OTP de type `change_email` (voir `otp_codes.type`). Le nouvel email ne remplace l'ancien qu'après validation du code.

---

## 2. Onboarding (initial — capacités, pas de rôle exclusif)

Pas de `POST /onboarding/role`. Voir `auth-onboarding/SKILL.md`.

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/onboarding/status` | 🔒 | `{onboarding_step, has_patient_profile, is_aidant}` | — |
| POST | `/onboarding/infos` | 🔒 `nom_complet, date_naissance, sexe, localisation, phone?` | `{onboarding_step}` | — |
| POST | `/onboarding/besoin-suivi` | 🔒 `actif: bool` | `{onboarding_step, has_patient_profile}` — si `actif=true`, crée le profil `Patient` | — |
| GET | `/onboarding/maladies` | — | `[{id, nom, description}]` | — |
| POST | `/onboarding/patient/traitement` | 🔒 `en_traitement: bool, traitements?: [{maladie_id, phase, date_debut?}]` | `{onboarding_step}` | `NOT_A_PATIENT` |
| POST | `/onboarding/patient/permissions` | 🔒 `notifications_accordees: bool, batterie_exemptee: bool` | `{onboarding_step}` | `NOT_A_PATIENT` |
| POST | `/onboarding/complete` | 🔒 | `{onboarding_step: "termine"}` | `ONBOARDING_INCOMPLETE` |

> Si `besoin-suivi.actif = false` : on peut appeler `complete` immédiatement (parcours court).  
> Si `true` : enchaîner `patient/traitement` puis `patient/permissions` avant `complete`.

---

## 2bis. Accueil — activer des capacités plus tard

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| POST | `/patients/me/activate` | 🔒 | `{has_patient_profile: true, onboarding_hint: "patient_traitement"}` — crée `Patient` si absent (copie infos depuis `User`) | `PATIENT_ALREADY_ACTIVE` |
| POST | `/aidants/me/sync` | 🔒 `code` | `{patient_id, patient_prenom, is_aidant, message}` — crée `PatientAidant` + journal `NotificationLog` (transparence patient) | `SYNC_CODE_INVALID`, `SYNC_CODE_EXPIRED`, `SYNC_SELF_NOT_ALLOWED` |

> Anciennes routes `POST /onboarding/role`, `/onboarding/patient/infos`, `/onboarding/aidant/infos`, `/onboarding/aidant/sync` : **retirées** du contrat (remplacées ci-dessus).

---

## 3. Profil patient

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/patients/me` | 🔒 | objet `Patient` complet | `NOT_A_PATIENT` |
| PATCH | `/patients/me` | 🔒 champs modifiables du `Patient` | objet `Patient` mis à jour | — |
| POST | `/patients/me/sync-code` | 🔒 | `{code, qr_payload, expires_at}` | — |
| GET | `/patients/me/aidants` | 🔒 | `[{aidant_id, nom, statut, niveau_permission}]` | — |
| PATCH | `/patients/me/aidants/{aidant_id}/permissions` | 🔒 `niveau_permission` | objet mis à jour | `AIDANT_NOT_FOUND` |
| DELETE | `/patients/me/aidants/{aidant_id}` | 🔒 | `{message}` — révoque la relation | `AIDANT_NOT_FOUND` |
| GET | `/patients/me/contacts-urgence` | 🔒 | `[ContactUrgence]` | — |
| POST | `/patients/me/contacts-urgence` | 🔒 `nom, telephone, relation` | `ContactUrgence` créé | — |
| DELETE | `/patients/me/contacts-urgence/{id}` | 🔒 | `{message}` | `CONTACT_NOT_FOUND` |
| GET | `/patients/me/voix-rappel` | 🔒 | `VoixRappel` actuelle | — |
| PUT | `/patients/me/voix-rappel` | 🔒 `type` (`systeme`\|`personnalisee`), fichier audio si personnalisée | `VoixRappel` | `FICHIER_AUDIO_INVALIDE` |

---

## 4. Traitements et médicaments

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/patients/me/traitements` | 🔒 | `[PatientTraitement]` | — |
| POST | `/patients/me/traitements` | 🔒 `maladie_id, phase, date_debut?` | `PatientTraitement` créé | — |
| POST | `/traitements/{id}/medicaments` | 🔒 `nom, dosage, forme, horaires: [{heure, jours}]` | `Medicament` créé (avec ses `MedicamentHoraire`) | `TRAITEMENT_NOT_FOUND` |
| GET | `/patients/me/medicaments` | 🔒 | `[Medicament]` avec horaires imbriqués | — |
| PATCH | `/medicaments/{id}` | 🔒 champs modifiables | `Medicament` mis à jour | `MEDICAMENT_NOT_FOUND` |
| PATCH | `/medicaments/{id}/stock` | 🔒 `stock_restant` | `{stock_restant, alerte_declenchee: bool}` | `MEDICAMENT_NOT_FOUND` |
| POST | `/medicaments/{id}/horaires` | 🔒 `heure, jours` | `MedicamentHoraire` créé | `MEDICAMENT_NOT_FOUND` |
| DELETE | `/horaires/{id}` | 🔒 | `{message}` (désactive, ne supprime pas) | `HORAIRE_NOT_FOUND` |

---

## 5. Prises (rappels de médicaments)

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/patients/me/prises` | 🔒 `date?` (défaut: aujourd'hui) | `[Prise]` | — |
| POST | `/prises/{id}/confirmer` | 🔒 `canal` (`app`\|`sms`) | `Prise` mise à jour (`statut: confirmee`) | `PRISE_NOT_FOUND`, `PRISE_DEJA_CONFIRMEE` |
| POST | `/prises/{id}/reporter` | 🔒 `nouvelle_heure` | `Prise` mise à jour | `PRISE_NOT_FOUND` |
| POST | `/prises/sync-offline` | 🔒 `[{id, statut, confirmee_at}]` | `{synced: [...], conflicts: [...]}` — synchronisation en lot des confirmations faites hors-ligne | — |

> `/prises/sync-offline` est essentiel pour le mode offline-first de `mobile-flutter/SKILL.md` : l'app envoie en une fois toutes les confirmations faites sans réseau.

---

## 6. Constantes de santé

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/patients/me/constantes` | 🔒 `type?, depuis?, jusqu_a?` | `[Constante]` | — |
| POST | `/patients/me/constantes` | 🔒 `type, valeur, unite, mesure_at, source` | `Constante` créée + `{tendance, message}` (résultat de l'analyse comparative du Volet 2) | `TYPE_INVALIDE` |

---

## 7. Check-in et SOS

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| POST | `/patients/me/check-in` | 🔒 `statut` (`ca_va`\|`pas_top`) | `CheckIn` créé | `CHECK_IN_DEJA_FAIT_AUJOURDHUI` |
| GET | `/patients/me/check-in` | 🔒 `depuis?` | `[CheckIn]` | — |
| POST | `/patients/me/sos` | 🔒 | `{sos_id, annulable_jusqu_a}` — déclenche l'alerte silencieuse après la fenêtre de 30s | `AUCUN_CONTACT_URGENCE` |
| POST | `/sos/{id}/annuler` | 🔒 | `{message}` | `SOS_TROP_TARD`, `SOS_NOT_FOUND` |

---

## 8. Vue aidant

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/aidants/me/patients` | 🔒 | `[{patient_id, prenom, niveau_permission}]` | `NOT_AN_AIDANT` |
| GET | `/aidants/me/patients/{patient_id}/observance` | 🔒 | résumé de prises (selon `niveau_permission`) | `PERMISSION_REFUSEE`, `PATIENT_NOT_FOUND` |
| GET | `/aidants/me/patients/{patient_id}/constantes` | 🔒 | `[Constante]` (selon `niveau_permission`) | `PERMISSION_REFUSEE` |
| POST | `/aidants/me/patients/{patient_id}/voix-rappel` | 🔒 fichier audio | `VoixRappel` créée pour ce patient | `PERMISSION_REFUSEE` |

---

## 9. Moteur de notification / consentement (Volet 7)

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/users/me/preferences-consentement` | 🔒 | `[PreferenceConsentement]` | — |
| PATCH | `/users/me/preferences-consentement/{type_alerte}` | 🔒 `toujours_demander, regle_auto?` | `PreferenceConsentement` mise à jour | — |
| GET | `/users/me/notifications` | 🔒 `depuis?` | `[NotificationLog]` — historique, pour transparence | — |
| POST | `/notifications/{id}/reponse` | 🔒 `reponse` (`oui`\|`non`\|`reporter`) | `{message, action_declenchee: bool}` — réponse à une proposition (ex: "veux-tu qu'on prévienne ton aidant ?") | `NOTIFICATION_NOT_FOUND`, `DEJA_REPONDU` |

---

## Conventions transverses

1. Toute route qui déclenche potentiellement une notification vers un tiers doit passer par le moteur centralisé décrit dans `backend-fastapi/SKILL.md` — jamais d'envoi direct depuis un router métier.
2. Toute route liste (`GET` collection) supporte la pagination (`page`, `page_size`) même si non détaillé ligne par ligne ci-dessus, pour rester cohérent dès le départ.
3. Les erreurs de permission entre aidant et patient (`PERMISSION_REFUSEE`) doivent toujours vérifier `PatientAidant.niveau_permission` et `statut = actif` avant de renvoyer une donnée — jamais de contrôle uniquement côté client.
4. Toute nouvelle route doit être ajoutée à ce fichier avant d'être codée (voir "Statut de ce document" en tête).

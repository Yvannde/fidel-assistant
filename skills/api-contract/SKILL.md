---
name: api-contract
description: Contrat formel de tous les endpoints API de la plateforme — méthode, chemin, entrée, sortie, erreurs possibles. C'est la référence commune obligatoire entre les agents backend (FastAPI) et mobile (Flutter) pour qu'ils avancent en parallèle sans désynchronisation. À consulter avant d'écrire une route backend ou un appel API côté app. Inclut Sync V2 (push/pull, client_mutation_id). Lire project-overview/SKILL.md, auth-onboarding/SKILL.md, data-model/SKILL.md et offline-sync/SKILL.md en complément.
---

# Contrat des endpoints API

## Statut de ce document

Comme `data-model/SKILL.md`, ce fichier est un **contrat**. Toute route listée ici doit exister avec la signature décrite. Si un agent a besoin d'une route non listée, il **ajoute d'abord la route à ce fichier**, puis l'implémente — jamais l'inverse. Ça évite qu'un agent backend et un agent mobile divergent silencieusement sur un contrat non documenté.

Toutes les routes sont préfixées `/api/v1`. Toutes les routes marquées 🔒 nécessitent un `Authorization: Bearer <access_token>` valide. Les erreurs suivent le format défini dans `backend-fastapi/SKILL.md` : `{"error": {"code": "...", "message": "..."}}`.

---

## 1. Authentification

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
Toutes les routes `/auth/*` : plafond IP global (`RATE_LIMITED`, HTTP 429). Actions sensibles (register, OTP, login, Google, refresh, forgot/reset/change password, link-google, email-change, delete) : plafond IP supplémentaire (`RATE_LIMITED`). Login : aussi `LOGIN_RATE_LIMITED` par email (service).

| POST | `/auth/register` | `email`, `langue` | `{message}` — envoie l'OTP | `EMAIL_ALREADY_VERIFIED`, `RATE_LIMITED` |
| POST | `/auth/resend-otp` | `email`, `type` (`inscription`\|`reset_password`) | `{message}` | `RESEND_LIMIT_REACHED`, `RATE_LIMITED` |
| POST | `/auth/verify-otp` | `email`, `code`, `type?` (`inscription`\|`reset_password`, défaut `inscription`) | `{temp_token}` — inscription : vérifie email ; reset : jeton pour `reset-password` | `OTP_INVALID`, `OTP_EXPIRED`, `OTP_MAX_ATTEMPTS`, `RATE_LIMITED` |
| POST | `/auth/set-password` | `temp_token`, `password` | `{message}` | `TEMP_TOKEN_INVALID`, `PASSWORD_TOO_WEAK`, `RATE_LIMITED` |
| POST | `/auth/accept-cgu` | `temp_token` ou 🔒, `version` | `{message}` | `CGU_VERSION_OUTDATED`, `RATE_LIMITED` |
| POST | `/auth/accept-consentement-sante` | `temp_token` ou 🔒 | `{message}` | `RATE_LIMITED` |
| POST | `/auth/login` | `email`, `password` | `{access_token, refresh_token, expires_in, session_id, onboarding_step, has_patient_profile, is_aidant}` | `INVALID_CREDENTIALS`, `EMAIL_NOT_VERIFIED`, `LOGIN_RATE_LIMITED`, `RATE_LIMITED` |
| POST | `/auth/google` | `id_token`, `langue`, `fuseau_horaire?` | `{access_token, refresh_token, expires_in, session_id, onboarding_step, has_patient_profile, is_aidant, is_new_user, needs_cgu, needs_consentement_sante}` | `GOOGLE_TOKEN_INVALID`, `GOOGLE_EMAIL_NOT_VERIFIED`, `GOOGLE_AUD_MISMATCH`, `RATE_LIMITED` |
| POST | `/auth/refresh` | `refresh_token` | `{access_token, expires_in}` | `REFRESH_TOKEN_INVALID_OR_EXPIRED`, `RATE_LIMITED` |
| POST | `/auth/logout` | 🔒 `refresh_token` | `{message}` | `RATE_LIMITED` |
| POST | `/auth/forgot-password` | `email` | `{message}` — envoie OTP type `reset_password` | `RATE_LIMITED` |
| POST | `/auth/reset-password` | `nouveau_password` + (`temp_token` **ou** `email`+`code`) | `{message}` | `OTP_INVALID`, `OTP_EXPIRED`, `TEMP_TOKEN_INVALID`, `RATE_LIMITED` |
| GET | `/auth/me` | 🔒 | `{id, email, phone, nom_complet, date_naissance, sexe, localisation, onboarding_step, has_patient_profile, is_aidant, langue, fuseau_horaire, auth_providers, email_verified_at, has_password, needs_cgu, needs_consentement_sante}` | `RATE_LIMITED` |
| PATCH | `/auth/me` | 🔒 `langue?`, `fuseau_horaire?`, `phone?` | objet `/auth/me` mis à jour | `RATE_LIMITED` |
| POST | `/auth/change-password` | 🔒 `current_password?`, `nouveau_password` | `{message}` — `current_password` requis si un mot de passe existe déjà (compte email) ; optionnel si Google-only | `INVALID_CREDENTIALS`, `PASSWORD_TOO_WEAK`, `RATE_LIMITED` |
| POST | `/auth/link-google` | 🔒 `id_token` | `{message, auth_providers}` | `GOOGLE_TOKEN_INVALID`, `GOOGLE_AUD_MISMATCH`, `GOOGLE_ALREADY_LINKED`, `RATE_LIMITED` |
| POST | `/auth/request-email-change` | 🔒 `nouvel_email` | `{message}` — OTP envoyé au **nouvel** email | `EMAIL_ALREADY_VERIFIED`, `RATE_LIMITED` |
| POST | `/auth/confirm-email-change` | 🔒 `nouvel_email`, `code` | `{message, email}` | `OTP_INVALID`, `OTP_EXPIRED`, `RATE_LIMITED` |
| GET | `/auth/sessions` | 🔒 `current_session_id?` | `[{id, device_info, created_at, revoked_at, is_current}]` | `RATE_LIMITED` |
| POST | `/auth/logout-all` | 🔒 | `{message}` — révoque toutes les sessions | `RATE_LIMITED` |
| DELETE | `/auth/sessions/{session_id}` | 🔒 | `{message}` | `SESSION_NOT_FOUND`, `RATE_LIMITED` |
| DELETE | `/auth/me` | 🔒 `password?` | `{message}` — soft delete (`deleted_at`) ; `password` requis si le compte en a un | `INVALID_CREDENTIALS`, `RATE_LIMITED` |

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
| GET | `/onboarding/maladies` | — | `[{id, code, nom, description, constantes_prioritaires, questions_onboarding}]` | — |
| POST | `/onboarding/patient/traitement` | 🔒 `en_traitement: bool, traitements?: [{maladie_id, phase, date_debut?, date_fin_prevue?, protocole_id?, maladie_libelle?, lieu_suivi?, attributs?}]` | `{onboarding_step}` | `NOT_A_PATIENT` |
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
| GET | `/patients/me/dashboard` | 🔒 | `{prochaine_action, medicaments_configures, notifications_accordees, traitements[], prises_aujourdhui[]}` — `prochaine_action` : `activer_notifications` \| `configurer_medicaments` \| `aucune` | `NOT_A_PATIENT` |
| GET | `/patients/me` | 🔒 | objet `Patient` complet | `NOT_A_PATIENT` |
| PATCH | `/patients/me` | 🔒 `localisation?`, `nom_complet?`, `photo_url?`, `notifications_accordees?`, `batterie_exemptee?`, `notifications_discretes?` | objet `Patient` mis à jour | `NOT_A_PATIENT` |
| POST | `/patients/me/sync-code` | 🔒 | `{code, qr_payload, expires_at}` | — |
| GET | `/patients/me/aidants` | 🔒 | `[{aidant_id, nom, statut, niveau_permission}]` | — |
| PATCH | `/patients/me/aidants/{aidant_id}/permissions` | 🔒 `niveau_permission` | objet mis à jour | `AIDANT_NOT_FOUND` |
| DELETE | `/patients/me/aidants/{aidant_id}` | 🔒 | `{message}` — révoque la relation | `AIDANT_NOT_FOUND` |
| GET | `/patients/me/contacts-urgence` | 🔒 | `[ContactUrgence]` | — |
| POST | `/patients/me/contacts-urgence` | 🔒 `nom, telephone, relation` | `ContactUrgence` créé | — |
| DELETE | `/patients/me/contacts-urgence/{id}` | 🔒 | `{message}` | `CONTACT_NOT_FOUND` |
| GET | `/patients/me/voix-rappel` | 🔒 | `VoixRappel` actuelle (défaut `systeme` si aucune) | `NOT_A_PATIENT` |
| PUT | `/patients/me/voix-rappel` | 🔒 multipart : `type` (`systeme`\|`personnalisee`), `fichier` (obligatoire si `personnalisee`) — **mp3 / m4a / aac / ogg / opus**, max **2 Mo** | `VoixRappel` | `FICHIER_AUDIO_INVALIDE`, `FICHIER_AUDIO_TROP_LOURD`, `NOT_A_PATIENT` |
| GET | `/patients/me/voix-rappel/fichier` | 🔒 | flux audio binaire | `VOIX_NOT_FOUND`, `NOT_A_PATIENT` |

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
| GET | `/patients/me/prises` | 🔒 `date?` (défaut: aujourd'hui) | `[Prise]` — inclut `traitement_id`, `maladie_id`, `maladie_nom` (groupement DoseSlot mobile) | — |
| POST | `/prises/{id}/confirmer` | 🔒 `canal` (`app`\|`sms`), `client_mutation_id?` (UUID — **requis** dès Phase 1 mobile) | `Prise` mise à jour (`statut: confirmee`) ; si `client_mutation_id` déjà appliqué → même `Prise` (idempotent, pas d’erreur) | `PRISE_NOT_FOUND`, `PRISE_DEJA_CONFIRMEE` |
| POST | `/prises/{id}/reporter` | 🔒 `nouvelle_heure`, `client_mutation_id?` (UUID — **requis** dès Phase 1 mobile) | `Prise` mise à jour ; idempotent si `client_mutation_id` déjà vu | `PRISE_NOT_FOUND` |
| POST | `/prises/sync-offline` | 🔒 `[{id, statut, confirmee_at, client_mutation_id?}]` | `{synced: [...], conflicts: [...], duplicates?: [...]}` — lot hors-ligne ; `duplicates` = mutations déjà appliquées | — |

> `/prises/sync-offline` est essentiel pour le mode offline-first (`mobile-flutter` + `offline-sync`) : l’app envoie en une fois les confirmations faites sans réseau. **Phase 1** : persister `client_mutation_id` côté serveur (table `client_mutations`, voir `data-model`).

---

## 5bis. Sync V2 (Phases 4–5 — implémentée)

> **Contrat figé en Phase 0.** Implémentation : `POST /sync/push`, `GET /sync/pull` ; ops prise + `create_constante` / `create_check_in` ; cursor `"{ts}|{type}|{id}"` (legacy 2 segments = prise) ; prefs `sync_pull_cursor_v1`. Pull : prises **30 j** + constantes + check-ins. Détail : `offline-sync/SKILL.md`.

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| POST | `/sync/push` | 🔒 `{mutations: [{mutation_id, entity, entity_id?, op, payload, client_ts}]}` — ops : `confirm`\|`report`\|`create_constante`\|`create_check_in` | `{results: [{mutation_id, status: applied\|duplicate\|rejected, reason?}]}` — traitement ordonné ; une mutation `rejected` n’annule pas les autres | `MUTATION_REJECTED`, `SYNC_CONFLICT`, `CHECK_IN_DEJA_FAIT_AUJOURDHUI` |
| GET | `/sync/pull` | 🔒 `since?` (cursor opaque `{ts}\|{type}\|{id}`) | `{entities: [...], next_cursor, server_time}` — `type: prise\|traitement\|constante\|check_in` + `id`, `server_version`, `updated_at` | — |

Notes :

- `status: duplicate` = succès idempotent (même effet que `applied` pour le client : retirer de l’outbox).
- `MUTATION_DUPLICATE` comme code d’erreur HTTP **n’est pas** requis si le batch renvoie `duplicate` dans `results` (préférer 200 + `results`).
- `SYNC_CONFLICT` : conflit métier non auto-résolu (ex. downgrade `confirmee` → `en_attente`) ; le client suit `offline-sync` § conflits.
- Après un push réussi (ou partiel), le client enchaîne un pull avec son cursor.

---

## 6. Constantes de santé

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/patients/me/constantes` | 🔒 `type?, depuis?, jusqu_a?` | `[Constante]` | — |
| POST | `/patients/me/constantes` | 🔒 `type, valeur, unite, mesure_at, source, client_mutation_id?` | `Constante` créée + `{tendance, message}` (résultat de l'analyse comparative du Volet 2) | `TYPE_INVALIDE` |

---

## 7. Check-in et SOS

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| POST | `/patients/me/check-in` | 🔒 `statut` (`tres_mal`\|`pas_top`\|`ca_va`\|`super`), `client_mutation_id?` | `CheckIn` créé | `CHECK_IN_DEJA_FAIT_AUJOURDHUI` |
| GET | `/patients/me/check-in` | 🔒 `depuis?` | `[CheckIn]` | — |
| POST | `/patients/me/sos` | 🔒 | `{sos_id, annulable_jusqu_a}` — déclenche l'alerte silencieuse après la fenêtre de 30s | `AUCUN_CONTACT_URGENCE` |
| POST | `/sos/{id}/annuler` | 🔒 | `{message}` | `SOS_TROP_TARD`, `SOS_NOT_FOUND` |

---

## 8. Vue aidant

| Méthode | Chemin | Entrée | Sortie | Erreurs possibles |
|---|---|---|---|---|
| GET | `/aidants/me/patients` | 🔒 | `[{patient_id, prenom, niveau_permission}]` | `NOT_AN_AIDANT` |
| GET | `/aidants/me/patients/{patient_id}/observance` | 🔒 `depuis?`, `jusqu_a?` (défaut: 7 derniers jours) | `{patient_id, patient_prenom, depuis, jusqu_a, total, confirmees, manquees, en_attente, taux_observance}` — selon `niveau_permission.observance` | `PERMISSION_REFUSEE`, `PATIENT_NOT_FOUND` |
| GET | `/aidants/me/patients/{patient_id}/constantes` | 🔒 | `[Constante]` (selon `niveau_permission`) | `PERMISSION_REFUSEE` |
| POST | `/aidants/me/patients/{patient_id}/voix-rappel` | 🔒 multipart `fichier` — mêmes règles audio (mp3/m4a/aac/ogg/opus, ≤ 2 Mo) | `VoixRappel` créée/mise à jour pour ce patient | `PERMISSION_REFUSEE`, `FICHIER_AUDIO_INVALIDE`, `FICHIER_AUDIO_TROP_LOURD` |

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

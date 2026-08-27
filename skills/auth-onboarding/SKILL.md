---
name: auth-onboarding
description: Flux complet et détaillé d'inscription, de vérification par OTP, d'authentification (JWT), et d'onboarding fondé sur des capacités (profil patient optionnel + liens aidant optionnels), sans choix de rôle exclusif. À consulter par tout agent IA qui code une route, un écran ou une logique liée à la création de compte, la connexion, la session, les CGU, ou les étapes d'onboarding — backend FastAPI ou Flutter. Lire aussi project-overview/SKILL.md avant de commencer.
---

# Authentification & Onboarding

## Principe général

La **session applicative** est construite en interne (pas de Firebase Auth, Auth0, Supabase Auth comme fournisseur de session). Le backend FastAPI gère : hashing des mots de passe, génération/validation d'OTP, **vérification des `id_token` Google**, émission et rotation des JWT maison, gestion des sessions/appareils.

Deux chemins d’entrée équivalents (au choix de l’utilisateur) :

1. **Email + OTP + mot de passe** (flux historique)
2. **Continuer avec Google** — l’app Flutter obtient un `id_token` Google (`google_sign_in`) ; le backend le vérifie auprès de Google, crée ou retrouve le compte, puis émet nos `access_token` / `refresh_token`

Dans les deux cas : les infos de profil et l’activation éventuelle d’un suivi personnel se font **après** la création du compte. Les CGU + consentement santé restent **obligatoires**.

### Capacités, pas un rôle exclusif (règle produit V1)

Un compte **User** n’est **jamais** forcé à choisir « patient **ou** aidant » à l’inscription / onboarding.

| Capacité | Comment elle s’obtient |
|---|---|
| **Profil patient** | L’utilisateur active un suivi **pour lui-même** (pendant l’onboarding ou plus tard depuis l’accueil) → ligne `Patient` liée au `User` |
| **Aidant** | L’utilisateur synchronise un code/QR d’un patient → ligne(s) `PatientAidant` où il est `aidant_id` |

**Les deux capacités sont cumulables** sur le même compte (cas fréquent : proche aidant qui est aussi en traitement). Pas de second compte, pas de recommencer tout l’onboarding : on active seulement le **module manquant**.

L’API expose des booléens dérivés (`has_patient_profile`, `is_aidant`) — **pas** un `role` exclusif bloquant. Le champ legacy `role` sur `User` est **déprécié** (nullable, non utilisé pour le routage produit).

L'onboarding **initial** est repris via `onboarding_step` serveur. Les modules post-accueil (activer mon suivi, accompagner quelqu’un) ont leurs propres endpoints et ne réinitialisent pas `onboarding_step` à zéro.

---

## 1. Inscription (commune)

### Étape 1 — Saisie de l'email
- L'utilisateur entre son email (le téléphone n'est **pas** demandé ici).
- Format + unicité compte actif.
- Compte existant **non vérifié** : renvoi OTP autorisé.
- Compte **vérifié** : inviter à se connecter / mot de passe oublié (formulation neutre).

### Étape 2 — OTP
- Code 6 chiffres, courte durée, anti brute-force / anti-spam (voir config).
- Validation → email vérifié, OTP invalidé.

### Étape 3 — Mot de passe
- Règles via config ; hash argon2 ; jamais en clair ni dans les logs.

### Étape 4 — CGU + consentement santé
- Obligatoires pour **tout** compte.
- Traces distinctes : `CguAcceptance` (versionnée) + `ConsentementSante`.

→ Compte prêt → **onboarding initial** (`onboarding_step = infos`).

---

## 2. Connexion (login)

- Email + mot de passe → access + refresh tokens (`flutter_secure_storage`).
- Refresh / logout / multi-appareils (`sessions`).
- Mot de passe oublié : email → OTP → nouveau mot de passe.
- Réponse login / `/auth/me` : `onboarding_step`, `has_patient_profile`, `is_aidant` — le client redirige (reprise onboarding ou home).

---

## 2bis. Auth Google

Même principe IdP qu’avant : vérification `id_token` → nos JWT. CGU / consentement manquants → acceptation puis onboarding. Pas de Firebase Auth / Auth0.

Erreurs : `GOOGLE_TOKEN_INVALID`, `GOOGLE_EMAIL_NOT_VERIFIED`, `GOOGLE_AUD_MISMATCH`.

---

## 3. Onboarding initial (tous les comptes)

**Pas d’écran « Je suis patient / aidant ».**

### Étape A — Informations communes (`infos`)
Collecte pour **tout le monde** (peu bloquant ; téléphone optionnel) :
- Nom complet
- Date de naissance
- Sexe
- Localisation (ville/quartier)
- Téléphone (optionnel — re-proposable plus tard sur la home)

→ `POST /onboarding/infos` → `onboarding_step = besoin_suivi`

### Étape B — Besoin de suivi personnel (`besoin_suivi`)
Question (formulation recommandée) : **« Tu veux un suivi pour toi ? »** (plutôt que « es-tu malade ? »).

| Réponse | Suite |
|---|---|
| **Non** | `POST /onboarding/besoin-suivi` `{ actif: false }` puis `POST /onboarding/complete` → `termine` → **Home** |
| **Oui** | `POST /onboarding/besoin-suivi` `{ actif: true }` → crée/assure le profil `Patient` → enchaîne les étapes patient (C, D) |

Permissions notifications / batterie : **uniquement** si branche Oui (option A) — demandées au moment où elles ont un sens. Si Non, elles seront demandées plus tard à l’activation du suivi ou à la première action aidant qui en a besoin.

### Étape C — Traitement (`patient_traitement`) — si suivi pour soi
- « Es-tu actuellement en traitement ? » Oui / Non
- Si Oui : maladies via `GET /onboarding/maladies` + phase (`debut` / `en_cours` / `maintenance` / `ne_sais_pas`) ; date de début optionnelle
- Si Non : continuer sans bloquer

→ `POST /onboarding/patient/traitement` → `patient_permissions`

### Étape D — Permissions device (`patient_permissions`) — si suivi pour soi
- Notifications + exemption optimisation batterie (Android)
- Écran explicatif **avant** la popup système

→ `POST /onboarding/patient/permissions` → `POST /onboarding/complete` → `termine` → **Home**

### Reprise
Si l’utilisateur coupe en cours de route : à la prochaine connexion, `onboarding_step` indique où reprendre. Cache local Flutter possible, **source de vérité = serveur**.

---

## 4. Accueil — activer des capacités plus tard

Une fois `onboarding_step = termine`, l’accueil propose (non bloquant) :

### 4.1 Accompagner quelqu’un (devenir aidant)
1. Patient (celui qui a un profil `Patient`) génère un code : `POST /patients/me/sync-code` (courte durée, usage unique, aussi en QR).
2. L’autre utilisateur (depuis l’accueil) : `POST /aidants/me/sync` avec le code.
3. Relation `PatientAidant` créée.
4. Message côté aidant + **notification de transparence** au patient (*« [Prénom] est connecté à ton suivi »*). Jamais de sync invisible.
5. Many-to-many : plusieurs aidants / plusieurs patients suivis ; permissions par relation.

Un user **déjà patient** peut aussi devenir aidant sans nouvel onboarding.

### 4.2 Activer mon suivi (devenir patient plus tard)
Si `has_patient_profile = false` :
- Même parcours modules patient que les étapes C–D (traitement + permissions), via les endpoints patient / onboarding documentés, **sans** repasser par infos communes déjà saisies.
- Crée la ligne `Patient` et bascule `has_patient_profile = true`.

### 4.3 Compléments soft (checklist home)
Téléphone manquant, contact d’urgence, voix de rappel, photo — **jamais** bloquants pour accéder à la home.

### 4.4 Post-sync aidant (optionnel V1)
Enregistrement voix pour le patient, préférences de notification aidant — configurables après sync, pas obligatoires pour finaliser la relation.

---

## 5. Éléments transverses

- **Suppression de compte / droit à l’oubli** : soft delete prévu dès le modèle.
- **Changement d’email** : OTP sur la nouvelle adresse.
- **Verrouillage local** (PIN/biométrie) : réglages, pas onboarding.
- **Langue** : dès le premier écran ; **fuseau** : appareil à l’inscription.
- **Réseau coupé pendant onboarding** : reprise serveur + file locale.
- **Révocation d’un aidant** : patient, effet immédiat.
- **Audit** sync / consentements.
- **Comptes OTP abandonnés** : nettoyage / statut clair.

---

## 6. Valeurs `onboarding_step` (initial)

| Valeur | Signification |
|---|---|
| `infos` | Infos communes à saisir |
| `besoin_suivi` | Question « suivi pour toi ? » |
| `patient_traitement` | Branche patient — traitements |
| `patient_permissions` | Branche patient — permissions device |
| `termine` | Onboarding initial fini → home |

---

## 7. Résumé modèle (voir `data-model` pour le détail)

- `users` — compte + infos communes ; **pas** de rôle exclusif obligatoire
- `patients` — profil de suivi personnel (1-1 User), **optionnel**
- `patient_aidant` — liens aidant (many-to-many)
- `sync_codes`, `maladies`, `patient_traitements`, …
- `otp_codes`, `cgu_acceptances`, `consentements_sante`, `sessions`

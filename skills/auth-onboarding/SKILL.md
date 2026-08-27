---
name: auth-onboarding
description: Flux complet et détaillé d'inscription, de vérification par OTP, d'authentification (JWT), et d'onboarding pour les rôles patient et aidant (garde-malade) de la plateforme. À consulter par tout agent IA qui code une route, un écran ou une logique liée à la création de compte, la connexion, la session, les CGU, ou les étapes d'onboarding — que ce soit côté backend FastAPI ou côté app Flutter. Lire aussi project-overview/SKILL.md avant de commencer.
---

# Authentification & Onboarding

## Principe général

L'authentification est **entièrement construite en interne**, aucun service tiers (pas de Firebase Auth, Auth0, Supabase Auth). Le backend FastAPI gère : hashing des mots de passe, génération/validation d'OTP, émission et rotation des tokens JWT, gestion des sessions/appareils.

Le point d'entrée (email + mot de passe) est **identique pour tous les rôles** (patient, aidant, et les rôles V2 : médecin, agent de santé communautaire). Le choix du rôle et la collecte d'infos spécifiques se font **après** la création du compte, pendant l'onboarding — pas avant.

L'onboarding est **repris automatiquement à la prochaine connexion** si l'utilisateur s'arrête en cours de route : l'état d'avancement est persisté côté serveur (champ `onboarding_step` ou équivalent sur l'utilisateur), jamais uniquement côté client.

---

## 1. Inscription (commune à tous les rôles)

### Étape 1 — Saisie de l'email
- L'utilisateur entre son email (le numéro de téléphone n'est **pas** demandé ici, il sera demandé plus tard dans l'onboarding — voir section 3).
- Vérification de format + vérification qu'aucun compte actif n'existe déjà avec cet email.
- Si un compte existe déjà mais **non vérifié** (OTP jamais validé) : on autorise à renvoyer un nouvel OTP plutôt que de bloquer.
- Si un compte existe déjà et **vérifié** : message clair invitant à se connecter ou à utiliser "mot de passe oublié" (formulation neutre recommandée pour limiter l'énumération de comptes).

### Étape 2 — Envoi et validation de l'OTP
- Génération d'un code OTP (6 chiffres), durée de validité courte (ex : 10 minutes), envoyé par email.
- Limitation du nombre de tentatives de validation (ex : 5 tentatives) puis blocage temporaire + possibilité de renvoyer un nouveau code après un délai (anti brute-force).
- Limitation du nombre de renvois d'OTP par période (anti-spam / anti-abus).
- Une fois validé : l'email est marqué comme vérifié, l'OTP est invalidé (usage unique).

### Étape 3 — Définition du mot de passe
- Règles de robustesse minimales à définir (longueur, complexité) — prévoir un champ de config plutôt qu'une règle codée en dur.
- Hashing avec un algorithme adapté (argon2 recommandé, bcrypt acceptable).
- **Jamais** de mot de passe en clair stocké ou loggé, à aucun moment, y compris dans les logs de debug.

### Étape 4 — Acceptation des CGU
- **Obligatoire pour tous les rôles sans exception** (patient, aidant, médecin, agent de santé — quand ces derniers seront ouverts).
- On enregistre en base une **trace explicite** : `user_id`, `version_cgu_acceptee` (les CGU sont versionnées dès le départ, ex: `v1.0`), `date_acceptation`, `ip_acceptation` si disponible.
- Si les CGU sont mises à jour plus tard, prévoir une re-demande d'acceptation à la connexion suivante pour les utilisateurs existants (mécanisme à garder dans le modèle de données même si non implémenté immédiatement).
- Pour les données de santé, prévoir un **consentement distinct** des CGU générales (case à cocher séparée : "J'accepte que mes données de santé soient traitées dans le cadre de mon suivi") — tracé de la même façon, car c'est une catégorie de donnée sensible.

→ À ce stade, le compte existe, est vérifié, sécurisé, et les consentements légaux sont tracés. L'utilisateur entre en **onboarding**.

---

## 2. Connexion (login)

- Email + mot de passe → émission d'un **access token** (courte durée, ex: 15-30 min) et d'un **refresh token** (longue durée, ex: 30 jours), stockés côté Flutter dans un stockage sécurisé (`flutter_secure_storage`, jamais en `SharedPreferences` en clair).
- Endpoint de refresh dédié pour renouveler l'access token sans repasser par le mot de passe.
- Endpoint de logout qui invalide le refresh token côté serveur (table de tokens révoqués ou liste blanche par appareil).
- **Gestion multi-appareils** : un utilisateur peut être connecté sur plusieurs appareils → prévoir une table `sessions`/`devices` liée à l'utilisateur plutôt qu'un seul refresh token global.
- **Mot de passe oublié** : email → OTP → nouveau mot de passe, même logique anti brute-force que l'inscription.
- À la connexion, le backend renvoie l'état d'onboarding de l'utilisateur (terminé, ou étape à reprendre) pour que le client Flutter sache directement où rediriger l'utilisateur — pas de logique de reprise côté client seul.

---

## 3. Onboarding — Patient

### Étape 1 — Choix du rôle
Écran de choix : **"Je suis..."** → `Patient` / `Aidant (garde-malade)`.

### Étape 2 — Informations personnelles de base
Collecte minimale pour ne pas créer de friction, en une seule étape simple :
- Nom complet
- Date de naissance (permet de calculer l'âge, plus fiable qu'un champ âge saisi manuellement)
- Sexe
- Localisation (ville/quartier — utile pour le Volet 4 : pharmacies, centres de santé proches)
- Numéro de téléphone — demandé **ici** (pas à l'inscription), optionnel à ce stade pour ne pas bloquer l'onboarding ; re-proposable plus tard sur la home si non renseigné

### Étape 3 — Statut de traitement
- Question : **"Es-tu actuellement en traitement ?"** → Oui / Non
- Si Oui :
  - Sélection de la/les maladie(s) dans une **liste gérée côté backend** (pas codée en dur côté app, pour pouvoir l'enrichir sans nouvelle version de l'app)
  - Pour chaque maladie sélectionnée : phase du traitement — choix simple type `Début de traitement` / `En cours` / `Phase de maintenance` / `Je ne sais pas` (plutôt qu'une date exacte obligatoire) ; la date de début précise peut être demandée en option
  - Si "Je ne sais pas" est choisi, ne pas bloquer — un aidant pourra compléter l'info plus tard via son propre accès
- Si Non : l'utilisateur peut continuer quand même (cas des utilisateurs "bien-être" du futur Volet 5)

### Étape 4 — Permissions système (critique, à ne pas sauter)
- Demande d'autorisation des **notifications**
- Demande d'exemption d'**optimisation de batterie** côté Android (sinon les alarmes de rappel de médicament peuvent être tuées par le système — point critique pour la fiabilité du Volet 1, souvent oublié dans ce genre d'app)
- Écran explicatif ("on a besoin de ça pour te rappeler tes médicaments à l'heure") **avant** de déclencher la popup système native, pour maximiser le taux d'acceptation

### Étape 5 — Arrivée sur la page d'accueil
- L'onboarding "obligatoire" est terminé, l'utilisateur accède à l'app.
- Un **onboarding complémentaire non bloquant** reste disponible (bannière/checklist sur la home) pour compléter : numéro de téléphone si pas fait, contact d'urgence, voix personnalisée pour les rappels, photo de profil.
- Configuration de la **voix de rappel personnalisée** (liée au Volet 1) : voix système par défaut, ou voix enregistrée par un proche. Si un aidant est déjà synchronisé, il peut être invité à enregistrer un message vocal directement depuis son propre compte.

---

## 4. Onboarding — Aidant (garde-malade)

### Étape 1 — Choix du rôle
Même écran que le patient → choix `Aidant (garde-malade)`.

### Étape 2 — Informations de base
- Nom complet, numéro de téléphone (même logique que patient : optionnel à ce stade, re-proposable plus tard)
- Pas de données médicales pour l'aidant lui-même

### Étape 3 — Synchronisation avec un patient
Deux méthodes équivalentes, au choix :
1. **Code de synchronisation** : généré côté app du patient (dans ses paramètres), durée de vie courte (ex : 10 minutes), **usage unique**, régénérable à volonté. L'aidant saisit ce code.
2. **QR code** : même code, encodé en QR, scanné directement par l'aidant.

- Une fois la synchronisation réussie : message de bienvenue à l'aidant (*"Vous accompagnez désormais [Prénom]. Configurons quelques étapes importantes."*)
- Le patient reçoit une notification de confirmation (*"[Prénom aidant] est maintenant connecté à ton suivi."*) — transparence totale, jamais de synchronisation invisible pour le patient.
- Relation **many-to-many** dès le modèle de données : table de liaison `patient_aidant` avec un statut (`actif`, `révoqué`) et un **niveau de permission** par relation (voir section 6 de `project-overview` si étendue plus tard).

### Étape 4 — Configuration post-synchronisation
- Enregistrement d'un message vocal personnalisé pour les rappels du patient
- Configuration de son propre niveau de notification (notifié à chaque prise, ou seulement en cas d'oubli prolongé ?)

---

## 5. Éléments supplémentaires à ne pas oublier

- **Suppression de compte / droit à l'oubli** : prévoir dès le modèle de données un mécanisme de suppression ou d'anonymisation des données patient — important pour la confiance sur un projet de santé communautaire.
- **Changement d'email** : doit repasser par une vérification OTP sur la nouvelle adresse avant de basculer.
- **Verrouillage applicatif local** (PIN/biométrie) : en plus du login classique, utile pour un patient qui partage parfois son téléphone — option dans les réglages, pas obligatoire à l'onboarding.
- **Langue de l'app** : à choisir dès le tout début (avant même l'email), car elle conditionne tous les textes/voix/SMS envoyés ensuite.
- **Fuseau horaire** : à capturer automatiquement via l'appareil dès l'inscription — tous les rappels de médicaments en dépendent, un oubli classique qui casse les rappels si l'utilisateur change de téléphone.
- **États d'erreur réseau pendant l'onboarding** : chaque étape doit pouvoir être sauvegardée localement et resynchronisée si la connexion coupe en cours de route (cohérent avec le principe offline-first du projet).
- **Révocation d'un aidant par le patient** : accessible facilement dans les réglages du patient à tout moment, effet immédiat côté aidant, sans justification requise.
- **Audit trail des consentements et synchronisations** : logguer qui a été synchronisé à qui, quand, et qui a révoqué quoi.
- **Comptes non vérifiés abandonnés** : prévoir un nettoyage périodique (ou au minimum un statut clair) pour les comptes créés mais jamais vérifiés par OTP.

---

## Résumé du modèle de données backend (non exhaustif, à affiner dans `database-neon/SKILL.md`)

- `users` (id, email, phone nullable, password_hash, email_verified_at, role, onboarding_step, langue, fuseau_horaire, created_at)
- `otp_codes` (user_id, code_hash, type [inscription/reset], expires_at, used_at, tentatives)
- `cgu_acceptances` (user_id, version, accepted_at, ip)
- `consentements_sante` (user_id, accepted_at) — distinct des CGU générales
- `sessions`/`devices` (user_id, refresh_token_hash, device_info, created_at, revoked_at)
- `patients` (extension du user si role=patient : localisation ; infos de traitement liées via `patient_traitements`)
- `patient_aidant` (patient_id, aidant_id, statut, niveau_permission, created_at, revoked_at)
- `sync_codes` (patient_id, code, expires_at, used_at)

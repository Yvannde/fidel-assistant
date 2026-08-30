---
name: database-neon
description: Schéma de données, conventions de nommage, gestion des migrations, et usage du MCP Neon pour la base de données Postgres serverless du projet. À consulter par tout agent IA avant de créer/modifier une table, écrire une migration, ou interroger la base pendant le développement. Lire project-overview/SKILL.md et auth-onboarding/SKILL.md en complément.
---

> ⚠️ Pour la liste complète et détaillée des entités, champs et relations (le contrat formel à respecter), voir **`data-model/SKILL.md`**. Ce fichier-ci (`database-neon`) donne les conventions de nommage, de migration et l'usage du MCP — `data-model` est la source de vérité du schéma lui-même.

# Base de données — Neon (Postgres)

## Principe de base

- Neon est un Postgres serverless : la connexion "normale" applicative (runtime du backend FastAPI) se fait via une **chaîne de connexion classique** (driver `asyncpg` + SQLAlchemy async, ou équivalent), configurée dans `Settings` — utiliser la **connexion poolée** de Neon (pas la connexion directe) pour l'usage applicatif, car les connexions serverless peuvent être nombreuses et courtes.
- Le **MCP Neon** est un outil réservé aux **agents IA en phase de développement** : inspecter le schéma existant, tester des requêtes, créer des branches de base de données pour expérimenter, générer/valider des migrations. Ce n'est **pas** une dépendance du code applicatif en production.
- **Aucune modification de schéma manuelle** en base de prod, que ce soit via MCP ou autrement. Toute évolution de schéma passe par une migration Alembic versionnée et committée dans le repo.

## Branches Neon — usage recommandé pour les agents

Neon permet de créer des branches de base de données (comme des branches Git) :
- Un agent qui doit tester une migration risquée ou une requête destructrice doit le faire sur une **branche de dev/test dédiée**, jamais directement sur `main`/prod.
- Les tests automatisés (pytest) peuvent tourner contre une branche éphémère créée pour l'occasion, puis supprimée.

## Conventions de nommage et de structure

- Tables en `snake_case`, au pluriel (`users`, `patients`, `medicaments`)
- Clé primaire : `id` de type `UUID` (via `gen_random_uuid()`), pas d'auto-increment entier — plus sûr pour un usage mobile/offline où des ids peuvent être générés côté client avant sync
- Chaque table porte `created_at` (obligatoire) et `updated_at` (obligatoire, mis à jour via trigger ou au niveau applicatif)
- **Pas de suppression physique** des données patient sensibles par défaut : privilégier un champ `deleted_at` (soft delete) sauf demande explicite de suppression définitive (droit à l'oubli, cf. `auth-onboarding`)
- Clés étrangères toujours indexées
- Toute donnée de santé sensible doit pouvoir être identifiée facilement (préfixer les tables concernées ou documenter clairement) en vue d'un futur chiffrement au niveau colonne si besoin

## Schéma cœur (V1) — vue d'ensemble

### Utilisateurs & auth (détail complet dans `auth-onboarding/SKILL.md`)
- `users` — id, email, phone (nullable), password_hash (nullable si Google-only), google_sub (nullable unique), auth_providers, email_verified_at, nom_complet / date_naissance / sexe / localisation (nullable jusqu’à onboarding infos), role (**déprécié**, nullable), onboarding_step (`infos`\|`besoin_suivi`\|`patient_traitement`\|`patient_permissions`\|`termine`), langue, fuseau_horaire, created_at, updated_at, deleted_at
- `otp_codes` — user_id (FK), code_hash, type (`inscription` / `reset_password`), expires_at, used_at, tentatives
- `cgu_acceptances` — user_id (FK), version, accepted_at, ip
- `consentements_sante` — user_id (FK), accepted_at
- `sessions` — user_id (FK), refresh_token_hash, device_info, created_at, revoked_at

### Patients & traitements
- `patients` — profil de suivi personnel **optionnel** (1-1 User) : permissions device, `notifications_discretes`, photo_url
- **Catalogue (lecture)** : `maladies` (code slug) → `maladie_configs` → `protocoles_traitement` → `protocole_medicaments_suggeres`
- **Contexte patient** : `patient_traitements` (maladie, phase, dates, protocole_id, lieu_suivi) + `patient_traitement_attributs` (réponses EAV par maladie)
- **Exécution** : `medicaments` → `medicament_horaires` → `prises`

### Suivi (Volet 1 et 2)
- `constantes` — patient_id (FK), type, valeur (JSONB), unite, mesure_at, source (`manuel` / `objet_connecte`)
- `prises` — medicament_horaire_id (FK), heure_prevue, statut (`confirmee` / `manquee` / `en_attente`), confirmee_at, canal (`app` / `sms`)

### Réseau d'accompagnement (Volet 3)
- `patient_aidant` — patient_id (FK), aidant_id (FK), statut (`actif` / `revoque`), niveau_permission (structure à définir : ex. accès observance oui/non, accès constantes oui/non), created_at, revoked_at
- `sync_codes` — patient_id (FK), code, expires_at, used_at
- `contacts_urgence` — patient_id (FK), nom, telephone, relation
- `check_ins` — patient_id (FK), date, statut (`ca_va` / `pas_top` / `sans_reponse`), created_at — unique (patient_id, date)
- `sos_alertes` — patient_id (FK), statut (`en_attente` / `envoye` / `annule`), annulable_jusqu_a, envoye_at, annule_at

### Moteur de notification centralisé (Volet 7)
- `preferences_consentement` — user_id (FK), type_alerte (ex: `contact_medecin_tension`, `alerte_checkin_absence`), toujours_demander (bool), regle_auto (nullable, ex: "absence 48h")
- `notifications_log` — destinataire_id (FK), type, contenu, declencheur, envoye_at — journal d'audit complet, ne jamais l'omettre pour une fonctionnalité d'alerte

## Migrations (Alembic)

- Une migration par changement logique de schéma, jamais de migration fourre-tout
- Nom de fichier de migration explicite (`alembic revision --autogenerate -m "add_prises_table"`)
- Toujours relire la migration auto-générée avant de l'appliquer : `autogenerate` rate parfois les changements de type ou les renommages (il génère un drop+create au lieu d'un rename)
- Les migrations sont testées sur une branche Neon de dev avant d'être appliquées sur la branche principale

## Ce qu'un agent IA ne doit jamais faire

- Exécuter une commande destructrice (`DROP TABLE`, `TRUNCATE`, `DELETE` sans `WHERE`) via le MCP sur une branche de prod
- Modifier le schéma directement en base sans migration correspondante dans le repo
- Stocker des données de santé sans que la table soit couverte par le principe de consentement du Volet 7 si elle alimente une notification

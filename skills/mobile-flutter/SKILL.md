---
name: mobile-flutter
description: Architecture de l'application mobile Flutter, gestion d'état, mode offline-first, notifications locales/rappels fiables, sécurité du stockage des tokens, et conventions UI/accessibilité. À consulter par tout agent IA avant d'écrire ou modifier un écran, un provider/state, une intégration API, ou toute logique de notification côté app. Lire project-overview/SKILL.md et auth-onboarding/SKILL.md en complément, surtout pour les écrans d'auth/onboarding.
---

# Mobile — Flutter

## Principes non négociables

1. **Offline-first** : toute fonctionnalité critique (rappels de médicaments, confirmation de prise) doit fonctionner sans connexion internet, avec synchronisation automatique au retour du réseau. Ce n'est pas une optimisation ajoutée après coup, c'est une contrainte d'architecture dès le départ.
2. **Fiabilité des rappels avant tout** : un rappel de médicament qui ne se déclenche pas est le pire bug possible sur ce projet. Toute décision technique douteuse doit être tranchée en faveur de la fiabilité du rappel plutôt que de l'esthétique ou de la simplicité de code.
3. **Accessibilité par défaut** : gros boutons, contraste suffisant, tailles de police ajustables, compatibilité lecteur d'écran — le public cible inclut des personnes âgées ou peu à l'aise avec la technologie.

## Structure de dossiers (feature-first)

```
lib/
├── main.dart
├── core/
│   ├── config/                # variables d'environnement, endpoints API
│   ├── network/                # client Dio + intercepteurs (auth, refresh, retry offline)
│   ├── storage/                 # flutter_secure_storage (tokens), base locale (sync/cache)
│   └── theme/                   # thème, typographie, tokens de design
├── features/
│   ├── auth/                    # inscription, OTP, login, Google Sign-In, mot de passe oublié
│   ├── onboarding/               # choix de rôle, infos patient, sync aidant, permissions
│   ├── medicaments/               # ajout traitement, rappels, confirmation de prise
│   ├── constantes/                 # saisie et suivi poids/tension/etc.
│   ├── reseau/                     # aidants, contacts d'urgence, check-in, SOS
│   └── home/
├── shared/
│   ├── widgets/                    # composants réutilisables
│   └── l10n/                        # fichiers de traduction (intl)
└── services/
    ├── notification_service.dart     # planification des rappels locaux
    └── sync_service.dart               # file de synchronisation offline → serveur
```

Chaque feature suit le même découpage interne : `presentation/` (écrans, widgets), `application/` (state/providers), `domain/` (modèles), `data/` (repository, appels API).

## Gestion d'état

- **Riverpod** recommandé (testable, pas de `BuildContext` requis pour la logique métier, bon support offline/async)
- Un provider par responsabilité claire (ex : `authStateProvider`, `onboardingStateProvider`, `medicamentsProvider`) plutôt que des providers fourre-tout
- Toute donnée qui doit survivre à un redémarrage de l'app (état d'onboarding en cours, file de sync en attente) passe par le stockage local, pas seulement par le state en mémoire

## Réseau et authentification

- Client HTTP : `dio`, avec un intercepteur dédié qui :
  - ajoute l'access token sur chaque requête authentifiée
  - détecte un 401, tente un refresh automatique via le refresh token, rejoue la requête originale, et déconnecte l'utilisateur seulement si le refresh échoue aussi
  - met les requêtes en échec réseau (pas d'auth) en **file d'attente locale** plutôt que de simplement afficher une erreur, quand l'action concernée doit être synchronisée plus tard (ex : confirmation de prise faite hors-ligne)
- **Stockage des tokens** : `flutter_secure_storage` uniquement (Keychain iOS / Keystore Android). Jamais dans `SharedPreferences` en clair, jamais en variable statique persistée sur disque non chiffré.

## Mode offline-first et synchronisation

- Base locale légère (ex : `drift` ou `sqflite`) qui sert de **source de vérité locale** pour les données critiques (traitements, horaires, historique de prises récent), synchronisée avec le backend.
- Toute action utilisateur critique (confirmer une prise, saisir une constante) s'écrit **d'abord en local**, avec un statut `à_synchroniser`, puis tente l'envoi au serveur. L'UI ne doit jamais bloquer en attendant le réseau pour ce type d'action.
- Résolution de conflit simple par défaut : dernière valeur écrite gagne (`last-write-wins`), avec horodatage fiable — suffisant pour ce cas d'usage tant qu'on garde un log côté serveur pour audit (cf. `database-neon/SKILL.md`).

## Notifications et alarmes locales — le cœur du produit

C'est la partie la plus critique techniquement :
- `flutter_local_notifications` pour la planification, avec le mode **alarme exacte** (`AndroidScheduleMode.exactAllowWhileIdle` ou équivalent) — les rappels de médicaments ne doivent pas être soumis au Doze mode standard d'Android
- Demander explicitement l'exemption d'**optimisation de batterie** pendant l'onboarding (voir `auth-onboarding/SKILL.md`, étape 4) — sans ça, certains constructeurs Android (Xiaomi, Huawei, Samsung en mode agressif) tuent les alarmes en arrière-plan
- Les notifications de rappel doivent inclure des **actions rapides** ("J'ai pris" / "Pas encore") directement sur la notification (Android `NotificationCompat.Action`, iOS `UNNotificationAction`) pour permettre la confirmation sans ouvrir l'app
- Support de la **voix personnalisée** : lecture d'un fichier audio (enregistré par un proche) au moment du rappel plutôt qu'un simple son système, via un lecteur audio léger déclenché par la notification
- Toute planification de rappel doit être **reprogrammée localement** après un redémarrage du téléphone (écouter l'event `BOOT_COMPLETED` sur Android) — sinon les rappels disparaissent après un reboot

## Onboarding et auth (référence)

Suivre exactement le flux décrit dans `auth-onboarding/SKILL.md` — écran par écran, y compris :
- bouton **Continuer avec Google** (`google_sign_in`) → envoi de l'`id_token` à `POST /api/v1/auth/google` → stockage des JWT maison dans `flutter_secure_storage`
- reprise automatique de l'onboarding à l'étape sauvegardée côté serveur (ne pas recalculer cette logique côté client, se fier à ce que retourne l'API au login)
- écran explicatif avant chaque demande de permission système
- synchronisation patient-aidant par code ou QR code (utiliser `mobile_scanner` ou équivalent pour le scan QR)

En production, `AppConfig.apiBaseUrl` pointe vers `https://educampro.edu.cm`.

## Internationalisation et accessibilité

- `flutter_localizations` + `intl`, langue choisie dès le tout premier écran (avant même l'email, cf. `auth-onboarding/SKILL.md`)
- Respecter les tailles de police système (pas de tailles fixes qui ignorent les réglages d'accessibilité du téléphone)
- Contrastes suffisants (WCAG AA minimum) même pour les thèmes personnalisés

## Tests

- Tests unitaires sur les providers/state (Riverpod se prête bien aux tests sans UI)
- Tests de widget sur les écrans critiques (confirmation de prise, onboarding)
- Test manuel obligatoire sur un appareil Android réel avec optimisation batterie activée avant toute mise en production d'une fonctionnalité touchant aux rappels — un simulateur ne reproduit pas fidèlement le comportement de Doze mode

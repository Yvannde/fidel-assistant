# Politique de sécurité

## Versions supportées

| Version | Supportée |
|---|---|
| `main` (développement) | Oui |
| Releases marquées | Oui (dernière release) |

## Signalement d’une vulnérabilité

**Ne créez pas d’issue GitHub publique** pour une faille de sécurité.

1. Utilisez [GitHub Security Advisories](https://docs.github.com/en/code-security/security-advisories) sur ce dépôt (onglet *Security* → *Report a vulnerability*), **ou**
2. Contactez les mainteneurs en privé (email à définir dans le README une fois le remote créé).

Inclure si possible :

- Description de la vulnérabilité
- Étapes de reproduction
- Impact (ex. fuite de données de santé, contournement d’auth, envoi d’alerte sans consentement)
- Versions / commits concernés

Nous accusons réception sous **72 heures** et proposons un correctif ou un plan dès que possible.

## Périmètre sensible

Priorité maximale pour :

- Contournement d’authentification / OTP / JWT
- Accès non autorisé aux données d’un autre patient
- Alerte ou contact d’un tiers **sans** consentement explicite
- Fuite de secrets (clés JWT, chaînes Neon, SMTP)
- Soft-delete contourné exposant des données après « droit à l’oubli »

## Pratiques attendues des contributeurs

- Ne jamais committer `.env`, clés, dumps de base
- Ne jamais logger mots de passe, OTP en clair, ou tokens
- Tester les changements d’auth et de permissions aidant/patient

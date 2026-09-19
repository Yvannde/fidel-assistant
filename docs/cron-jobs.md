# Jobs cron internes (Railway)

Jobs authentifiés par le header `X-Cron-Secret` (= env `CRON_SECRET`). Base URL prod : `https://educampro.edu.cm/api/v1`.

## Cadence recommandée

Même rythme pour les deux jobs : **toutes les 15–30 minutes**.

| Job | Méthode | Effet |
|---|---|---|
| `scan-prises-non-confirmees` | `POST /internal/jobs/scan-prises-non-confirmees` | Notif FCM aidants si opt-in `prise_non_confirmee_aidant` et `heure_prevue + delai_heures` (défaut 2 h) dépassé. **Ne change pas** le statut de la prise. |
| `mark-prises-manquees` | `POST /internal/jobs/mark-prises-manquees` | `en_attente` → `manquee` si `heure_prevue + PRISE_MANQUEE_GRACE_HOURS` (défaut **12 h**) dépassé. Pas de FCM. |

Ordre produit attendu : H0 → (opt-in) notif aidant à ≈H0+2 h → `manquee` à H0+12 h → confirmation tardive patient possible.

## Exemple curl

```bash
curl -X POST "$API/api/v1/internal/jobs/scan-prises-non-confirmees" \
  -H "X-Cron-Secret: $CRON_SECRET"

curl -X POST "$API/api/v1/internal/jobs/mark-prises-manquees" \
  -H "X-Cron-Secret: $CRON_SECRET"
```

## Variables d’environnement

| Variable | Rôle |
|---|---|
| `CRON_SECRET` | Secret partagé Railway cron ↔ API |
| `PRISE_MANQUEE_GRACE_HOURS` | Grâce avant `manquee` (défaut `12`) |

Voir aussi `skills/api-contract/SKILL.md` § 9bis et `skills/engagement-principle/SKILL.md`.

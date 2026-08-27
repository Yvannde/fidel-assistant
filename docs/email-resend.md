# Emails (Resend)

Les OTP et emails transactionnels partent via [Resend](https://resend.com).

## Config

Dans `backend/.env` :

```env
RESEND_API_KEY=re_xxxxxxxx
EMAIL_FROM=Fidel Assistant <noreply@educampro.edu.cm>
```

Le domaine **`educampro.edu.cm`** doit être **vérifié** dans Resend (sending enabled).  
L’expéditeur (`EMAIL_FROM`) doit utiliser une adresse `@educampro.edu.cm`.

## Comportement

- Si `RESEND_API_KEY` est vide → l’OTP est **loggé en console** (dev only)
- Si la clé est présente → envoi réel via l’API Resend

# Configurer Google Sign-In (app mobile)

Checklist pour les mainteneurs / toi — à faire **une fois** dans [Google Cloud Console](https://console.cloud.google.com/).

## 1. Projet Google Cloud

1. Créer (ou choisir) un projet, ex. `fidel-assistant`
2. Aller dans **APIs & Services → OAuth consent screen**
3. Type : **External** (ou Internal si Workspace)
4. Remplir nom d’app, email support, domaines autorisés (prod : `educampro.edu.cm`)
5. Scopes par défaut suffisent (`openid`, `email`, `profile`)

## 2. Créer 3 Client IDs (OAuth 2.0)

**APIs & Services → Credentials → Create credentials → OAuth client ID**

| Type | À renseigner | Variable `.env` |
|---|---|---|
| **Web application** | Origines JS : `http://localhost:8000`, `https://educampro.edu.cm` | `GOOGLE_CLIENT_ID_WEB` |
| **Android** | Package : `cm.fidel.fidel_assistant` + empreinte **SHA-1** (voir ci-dessous) | `GOOGLE_CLIENT_ID_ANDROID` |
| **iOS** | Bundle ID : `cm.fidel.fidelAssistant` (vérifier dans Xcode / `Info.plist`) | `GOOGLE_CLIENT_ID_IOS` |

> Le client **Web** est obligatoire pour Flutter : on le passe en `serverClientId` pour obtenir un `id_token` vérifiable par le backend.

## 3. Récupérer le SHA-1 Android (debug)

Windows (PowerShell) :

```powershell
keytool -list -v -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android
```

Copier la ligne **SHA1** dans le client OAuth Android.

Pour la release plus tard : SHA-1 du keystore de production (Play Store / App Signing).

## 4. Coller dans `backend/.env`

```env
GOOGLE_CLIENT_ID_WEB=xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_ID_IOS=xxxxx.apps.googleusercontent.com
```

Même valeurs côté Flutter via `--dart-define` ou un fichier de config non commité (surtout le Web client ID pour `serverClientId`).

## 5. Ce que tu me renvoies

Quand c’est prêt, envoie-moi (en privé / dans le chat) :

1. Les **3 Client IDs** (ce ne sont pas des secrets ultra-sensibles, mais ne les mets pas dans une issue publique inutilement)
2. Confirmation du **SHA-1** ajouté
3. Si iOS : Bundle ID exact si différent

Ensuite on branche `google_sign_in` + `POST /api/v1/auth/google`.

## Flux technique (rappel)

```
App Flutter (google_sign_in)
  → id_token Google
  → POST /api/v1/auth/google
  → Backend vérifie le token (google-auth)
  → émet nos JWT (access + refresh)
```

Pas de Firebase Auth.

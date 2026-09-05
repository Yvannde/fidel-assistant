// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Fidel Assistant';

  @override
  String get languageTitle => 'Choisis ta langue';

  @override
  String get languageSubtitle =>
      'Tu pourras la changer plus tard dans les réglages.';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageContinue => 'Continuer';

  @override
  String get loginTitle => 'Connecte-toi à ton compte';

  @override
  String get loginSubtitle =>
      'Entre ton email et ton mot de passe pour te connecter';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get orLoginWith => 'Ou connecte-toi avec';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'nom@email.com';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordHint => '••••••••';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get logIn => 'Se connecter';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get haveAccount => 'Tu as déjà un compte ?';

  @override
  String get loginFailed => 'Connexion impossible. Vérifie tes identifiants.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire';

  @override
  String get invalidEmail => 'Entre un email valide';

  @override
  String passwordTooShort(int min) {
    return 'Au moins $min caractères';
  }

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get registerTitle => 'Crée ton compte';

  @override
  String get registerSubtitle => 'Entre ton email pour commencer';

  @override
  String get registerContinue => 'Continuer';

  @override
  String get otpTitle => 'Vérifie ton email';

  @override
  String otpSubtitle(String email) {
    return 'On t\'a envoyé un code à 6 chiffres à $email';
  }

  @override
  String get otpLabel => 'Code de vérification';

  @override
  String get otpHint => '123456';

  @override
  String get otpInvalid => 'Entre le code à 6 chiffres';

  @override
  String get otpVerify => 'Vérifier';

  @override
  String get otpResend => 'Renvoyer le code';

  @override
  String get otpResent => 'Un nouveau code a été envoyé';

  @override
  String get passwordTitle => 'Choisis un mot de passe';

  @override
  String get passwordSubtitle => 'Au moins 8 caractères';

  @override
  String get passwordContinue => 'Continuer';

  @override
  String get legalTitle => 'Dernière étape';

  @override
  String get legalSubtitle => 'Accepte pour finaliser ton inscription';

  @override
  String legalCgu(String version) {
    return 'J\'accepte les Conditions d\'utilisation (version $version)';
  }

  @override
  String get legalConsent =>
      'Je consens au traitement de mes données de santé pour l\'accompagnement (pas de diagnostic médical)';

  @override
  String get legalRequired => 'Accepte les deux cases pour continuer';

  @override
  String get legalFinish => 'Créer mon compte';

  @override
  String get emailAlreadyVerified =>
      'Cet email est déjà inscrit. Essaie de te connecter.';

  @override
  String get genericError => 'Une erreur est survenue. Réessaie.';

  @override
  String get successEmailTitle => 'Email vérifié !';

  @override
  String get successEmailSubtitle =>
      'Ton email est confirmé. Choisis maintenant un mot de passe sécurisé.';

  @override
  String get successEmailCta => 'Continuer';

  @override
  String get successAccountTitle => 'C\'est réussi !';

  @override
  String get successAccountSubtitle =>
      'Ton compte est créé et prêt. Bienvenue sur Fidel Assistant.';

  @override
  String get successAccountCta => 'Continuer la configuration';

  @override
  String get forgotTitle => 'Mot de passe oublié ?';

  @override
  String get forgotSubtitle =>
      'Entre ton email, on t’envoie un code de réinitialisation';

  @override
  String get forgotContinue => 'Envoyer le code';

  @override
  String get forgotOtpSent => 'Code de réinitialisation envoyé';

  @override
  String get forgotResetTitle => 'Nouveau mot de passe';

  @override
  String get forgotResetSubtitle => 'Choisis un nouveau mot de passe sécurisé';

  @override
  String get forgotResetCta => 'Mettre à jour';

  @override
  String get forgotResetSuccess =>
      'Mot de passe mis à jour. Tu peux te connecter.';

  @override
  String get googleFailed => 'Échec de la connexion Google';

  @override
  String get googleCancelled => 'Connexion Google annulée';

  @override
  String get googleNotConfigured =>
      'Google Sign-In n’est pas configuré sur ce build';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingInfosTitle => 'Parle-nous de toi';

  @override
  String get onboardingInfosSubtitle =>
      'Ces infos nous aident à personnaliser ton accompagnement. Tu pourras les modifier plus tard.';

  @override
  String get onboardingNameLabel => 'Nom complet';

  @override
  String get onboardingBirthHint => 'Date de naissance';

  @override
  String get onboardingBirthRequired => 'Indique ta date de naissance';

  @override
  String get onboardingSexLabel => 'Sexe';

  @override
  String get onboardingSexF => 'F';

  @override
  String get onboardingSexM => 'M';

  @override
  String get onboardingSexOther => 'Autre';

  @override
  String get onboardingLocationLabel => 'Localisation';

  @override
  String get onboardingLocationHint => 'Ville / quartier';

  @override
  String get onboardingPhoneLabel => 'Téléphone (optionnel)';

  @override
  String get onboardingPhoneHint => '+237…';

  @override
  String get onboardingBesoinTitle => 'Tu veux un suivi pour toi ?';

  @override
  String get onboardingBesoinSubtitle =>
      'Tu pourras aussi accompagner un proche plus tard depuis l’accueil. Les deux sont possibles.';

  @override
  String get onboardingBesoinYesTitle => 'Oui, un suivi pour moi';

  @override
  String get onboardingBesoinYesSubtitle =>
      'Rappels, constantes et accompagnement personnel';

  @override
  String get onboardingBesoinNoTitle => 'Pas pour l’instant';

  @override
  String get onboardingBesoinNoSubtitle =>
      'Je veux surtout accompagner quelqu’un plus tard';

  @override
  String get onboardingChoiceRequired => 'Choisis une option pour continuer';

  @override
  String get onboardingTraitementTitle => 'Es-tu en traitement ?';

  @override
  String get onboardingTraitementSubtitle =>
      'Si oui, sélectionne les maladies suivies. Tu pourras compléter ensuite.';

  @override
  String get onboardingTraitementYes => 'Oui';

  @override
  String get onboardingTraitementNo => 'Non';

  @override
  String get onboardingTraitementNoHint =>
      'Pas de souci — tu pourras activer un suivi plus tard.';

  @override
  String get onboardingMaladiesLabel => 'Maladies suivies';

  @override
  String get onboardingMaladieRequired => 'Sélectionne au moins une maladie';

  @override
  String get onboardingPhaseLabel => 'Phase du traitement';

  @override
  String get onboardingPhaseDebut => 'Début';

  @override
  String get onboardingPhaseEnCours => 'En cours';

  @override
  String get onboardingPhaseMaintenance => 'Maintenance';

  @override
  String get onboardingPhaseInconnu => 'Je ne sais pas';

  @override
  String get onboardingPermsTitle => 'Active les rappels fiables';

  @override
  String get onboardingPermsSubtitle =>
      'On t’explique pourquoi avant la demande système. Tu peux aussi continuer sans.';

  @override
  String get onboardingPermsNotifTitle => 'Notifications';

  @override
  String get onboardingPermsNotifBody =>
      'Pour te rappeler de prendre tes médicaments au bon moment, même si l’app est fermée.';

  @override
  String get onboardingPermsBatteryTitle => 'Batterie (Android)';

  @override
  String get onboardingPermsBatteryBody =>
      'Sans exemption, certains téléphones coupent les rappels en arrière-plan.';

  @override
  String get onboardingPermsAllow => 'Autoriser';

  @override
  String get onboardingPermsLater => 'Plus tard';

  @override
  String get onboardingDoneToast => 'C’est bon — bienvenue sur Fidel';
}

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
  String get loginFailed => 'Connexion impossible. Vérifie tes identifiants.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire';

  @override
  String get invalidEmail => 'Entre un email valide';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get logout => 'Se déconnecter';
}

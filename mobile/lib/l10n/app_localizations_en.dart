// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Fidel Assistant';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this later in settings.';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageContinue => 'Continue';

  @override
  String get loginTitle => 'Sign in to your Account';

  @override
  String get loginSubtitle => 'Enter your email and password to log in';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orLoginWith => 'Or login with';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'name@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot Password ?';

  @override
  String get logIn => 'Log In';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get loginFailed => 'Unable to sign in. Check your credentials.';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String passwordTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get homeTitle => 'Home';

  @override
  String get logout => 'Log out';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Enter your email to get started';

  @override
  String get registerContinue => 'Continue';

  @override
  String get otpTitle => 'Check your email';

  @override
  String otpSubtitle(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get otpLabel => 'Verification code';

  @override
  String get otpHint => '123456';

  @override
  String get otpInvalid => 'Enter the 6-digit code';

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpResent => 'A new code was sent';

  @override
  String get passwordTitle => 'Choose a password';

  @override
  String get passwordSubtitle => 'At least 8 characters';

  @override
  String get passwordContinue => 'Continue';

  @override
  String get legalTitle => 'Almost done';

  @override
  String get legalSubtitle => 'Review and accept to finish signup';

  @override
  String legalCgu(String version) {
    return 'I accept the Terms of Use (version $version)';
  }

  @override
  String get legalConsent =>
      'I consent to the processing of my health data for accompaniment (not medical diagnosis)';

  @override
  String get legalRequired => 'Please accept both to continue';

  @override
  String get legalFinish => 'Create account';

  @override
  String get emailAlreadyVerified =>
      'This email is already registered. Try signing in.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get successEmailTitle => 'Email verified!';

  @override
  String get successEmailSubtitle =>
      'Your email is confirmed. Next, choose a secure password.';

  @override
  String get successEmailCta => 'Continue';

  @override
  String get successAccountTitle => 'Successful!';

  @override
  String get successAccountSubtitle =>
      'Your account is created and ready. Welcome to Fidel Assistant.';

  @override
  String get successAccountCta => 'Continue setup';

  @override
  String get forgotTitle => 'Forgot password?';

  @override
  String get forgotSubtitle => 'Enter your email and we’ll send a reset code';

  @override
  String get forgotContinue => 'Send code';

  @override
  String get forgotOtpSent => 'Reset code sent';

  @override
  String get forgotResetTitle => 'New password';

  @override
  String get forgotResetSubtitle => 'Choose a new secure password';

  @override
  String get forgotResetCta => 'Update password';

  @override
  String get forgotResetSuccess => 'Password updated. You can sign in now.';

  @override
  String get googleFailed => 'Google sign-in failed';

  @override
  String get googleCancelled => 'Google sign-in cancelled';

  @override
  String get googleNotConfigured =>
      'Google Sign-In is not configured on this build';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingInfosTitle => 'Tell us about you';

  @override
  String get onboardingInfosSubtitle =>
      'This helps us personalize your accompaniment. You can change it later.';

  @override
  String get onboardingNameLabel => 'Full name';

  @override
  String get onboardingBirthHint => 'Date of birth';

  @override
  String get onboardingBirthRequired => 'Please enter your date of birth';

  @override
  String get onboardingSexLabel => 'Sex';

  @override
  String get onboardingSexF => 'F';

  @override
  String get onboardingSexM => 'M';

  @override
  String get onboardingSexOther => 'Other';

  @override
  String get onboardingLocationLabel => 'Location';

  @override
  String get onboardingLocationHint => 'City / neighborhood';

  @override
  String get onboardingPhoneLabel => 'Phone (optional)';

  @override
  String get onboardingPhoneHint => '+237…';

  @override
  String get onboardingBesoinTitle => 'Do you want personal follow-up?';

  @override
  String get onboardingBesoinSubtitle =>
      'You can also support someone later from home. Both are possible.';

  @override
  String get onboardingBesoinYesTitle => 'Yes, follow-up for me';

  @override
  String get onboardingBesoinYesSubtitle =>
      'Reminders, vitals, and personal accompaniment';

  @override
  String get onboardingBesoinNoTitle => 'Not for now';

  @override
  String get onboardingBesoinNoSubtitle =>
      'I mostly want to support someone later';

  @override
  String get onboardingChoiceRequired => 'Choose an option to continue';

  @override
  String get onboardingTraitementTitle => 'Are you in treatment?';

  @override
  String get onboardingTraitementSubtitle =>
      'If yes, select the conditions you follow. You can complete details later.';

  @override
  String get onboardingTraitementYes => 'Yes';

  @override
  String get onboardingTraitementNo => 'No';

  @override
  String get onboardingTraitementNoHint =>
      'No problem — you can activate follow-up later.';

  @override
  String get onboardingMaladiesLabel => 'Conditions';

  @override
  String get onboardingMaladieRequired => 'Select at least one condition';

  @override
  String get onboardingPhaseLabel => 'Treatment phase';

  @override
  String get onboardingPhaseDebut => 'Starting';

  @override
  String get onboardingPhaseEnCours => 'Ongoing';

  @override
  String get onboardingPhaseMaintenance => 'Maintenance';

  @override
  String get onboardingPhaseInconnu => 'Not sure';

  @override
  String get onboardingPermsTitle => 'Enable reliable reminders';

  @override
  String get onboardingPermsSubtitle =>
      'We explain why before the system prompt. You can also continue without.';

  @override
  String get onboardingPermsNotifTitle => 'Notifications';

  @override
  String get onboardingPermsNotifBody =>
      'So we can remind you to take your medication on time, even when the app is closed.';

  @override
  String get onboardingPermsBatteryTitle => 'Battery (Android)';

  @override
  String get onboardingPermsBatteryBody =>
      'Without an exemption, some phones kill reminders in the background.';

  @override
  String get onboardingPermsAllow => 'Allow';

  @override
  String get onboardingPermsLater => 'Later';

  @override
  String get onboardingDoneToast => 'You’re all set — welcome to Fidel';
}

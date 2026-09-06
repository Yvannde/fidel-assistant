import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Fidel Assistant'**
  String get appName;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings.'**
  String get languageSubtitle;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageContinue;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Account'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password to log in'**
  String get loginSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orLoginWith.
  ///
  /// In en, this message translates to:
  /// **'Or login with'**
  String get orLoginWith;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@email.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password ?'**
  String get forgotPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Check your credentials.'**
  String get loginFailed;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters'**
  String passwordTooShort(int min);

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to get started'**
  String get registerSubtitle;

  /// No description provided for @registerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get registerContinue;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String otpSubtitle(String email);

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpLabel;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get otpHint;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get otpInvalid;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code was sent'**
  String get otpResent;

  /// No description provided for @passwordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get passwordTitle;

  /// No description provided for @passwordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordSubtitle;

  /// No description provided for @passwordContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get passwordContinue;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost done'**
  String get legalTitle;

  /// No description provided for @legalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and accept to finish signup'**
  String get legalSubtitle;

  /// No description provided for @legalCgu.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Use (version {version})'**
  String legalCgu(String version);

  /// No description provided for @legalConsent.
  ///
  /// In en, this message translates to:
  /// **'I consent to the processing of my health data for accompaniment (not medical diagnosis)'**
  String get legalConsent;

  /// No description provided for @legalRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept both to continue'**
  String get legalRequired;

  /// No description provided for @legalFinish.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get legalFinish;

  /// No description provided for @emailAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in.'**
  String get emailAlreadyVerified;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @successEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verified!'**
  String get successEmailTitle;

  /// No description provided for @successEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your email is confirmed. Next, choose a secure password.'**
  String get successEmailSubtitle;

  /// No description provided for @successEmailCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get successEmailCta;

  /// No description provided for @successAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Successful!'**
  String get successAccountTitle;

  /// No description provided for @successAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is created and ready. Welcome to Fidel Assistant.'**
  String get successAccountSubtitle;

  /// No description provided for @successAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Continue setup'**
  String get successAccountCta;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we’ll send a reset code'**
  String get forgotSubtitle;

  /// No description provided for @forgotContinue.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotContinue;

  /// No description provided for @forgotOtpSent.
  ///
  /// In en, this message translates to:
  /// **'Reset code sent'**
  String get forgotOtpSent;

  /// No description provided for @forgotResetTitle.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get forgotResetTitle;

  /// No description provided for @forgotResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new secure password'**
  String get forgotResetSubtitle;

  /// No description provided for @forgotResetCta.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get forgotResetCta;

  /// No description provided for @forgotResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated. You can sign in now.'**
  String get forgotResetSuccess;

  /// No description provided for @googleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleFailed;

  /// No description provided for @googleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in cancelled'**
  String get googleCancelled;

  /// No description provided for @googleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not configured on this build'**
  String get googleNotConfigured;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @onboardingStepProfil.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get onboardingStepProfil;

  /// No description provided for @onboardingStepSuivi.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get onboardingStepSuivi;

  /// No description provided for @onboardingStepTraitement.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get onboardingStepTraitement;

  /// No description provided for @onboardingStepRappels.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get onboardingStepRappels;

  /// No description provided for @onboardingGateLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing your space…'**
  String get onboardingGateLoading;

  /// No description provided for @onboardingRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get onboardingRetry;

  /// No description provided for @onboardingInfosTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get onboardingInfosTitle;

  /// No description provided for @onboardingInfosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few details to personalize Fidel. Nothing is locked in.'**
  String get onboardingInfosSubtitle;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get onboardingBirthLabel;

  /// No description provided for @onboardingBirthHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get onboardingBirthHint;

  /// No description provided for @onboardingBirthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your date of birth'**
  String get onboardingBirthRequired;

  /// No description provided for @onboardingSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get onboardingSexLabel;

  /// No description provided for @onboardingSexF.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get onboardingSexF;

  /// No description provided for @onboardingSexM.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get onboardingSexM;

  /// No description provided for @onboardingSexOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get onboardingSexOther;

  /// No description provided for @onboardingLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'City / neighborhood'**
  String get onboardingLocationLabel;

  /// No description provided for @onboardingLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Douala, Akwa'**
  String get onboardingLocationHint;

  /// No description provided for @onboardingPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get onboardingPhoneLabel;

  /// No description provided for @onboardingPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+237 6…'**
  String get onboardingPhoneHint;

  /// No description provided for @onboardingPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional — you can add it later'**
  String get onboardingPhoneOptional;

  /// No description provided for @onboardingBesoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you want follow-up for yourself?'**
  String get onboardingBesoinTitle;

  /// No description provided for @onboardingBesoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can also support someone from home. Both are possible, without a second account.'**
  String get onboardingBesoinSubtitle;

  /// No description provided for @onboardingBesoinYesTitle.
  ///
  /// In en, this message translates to:
  /// **'Yes, follow-up for me'**
  String get onboardingBesoinYesTitle;

  /// No description provided for @onboardingBesoinYesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Medication reminders, vitals, and personal accompaniment'**
  String get onboardingBesoinYesSubtitle;

  /// No description provided for @onboardingBesoinNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Not for now'**
  String get onboardingBesoinNoTitle;

  /// No description provided for @onboardingBesoinNoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I mostly want to support someone later'**
  String get onboardingBesoinNoSubtitle;

  /// No description provided for @onboardingChoiceRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose an option to continue'**
  String get onboardingChoiceRequired;

  /// No description provided for @onboardingTraitementTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you in treatment?'**
  String get onboardingTraitementTitle;

  /// No description provided for @onboardingTraitementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If yes, tick what you follow. Medicines and schedules come later — no pressure.'**
  String get onboardingTraitementSubtitle;

  /// No description provided for @onboardingTraitementYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I’m in treatment'**
  String get onboardingTraitementYes;

  /// No description provided for @onboardingTraitementYesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We only note the condition and phase for now'**
  String get onboardingTraitementYesSubtitle;

  /// No description provided for @onboardingTraitementNo.
  ///
  /// In en, this message translates to:
  /// **'Not right now'**
  String get onboardingTraitementNo;

  /// No description provided for @onboardingTraitementNoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can add this later from home'**
  String get onboardingTraitementNoSubtitle;

  /// No description provided for @onboardingTraitementNoHint.
  ///
  /// In en, this message translates to:
  /// **'No problem — you can activate follow-up later.'**
  String get onboardingTraitementNoHint;

  /// No description provided for @onboardingMaladiesLabel.
  ///
  /// In en, this message translates to:
  /// **'What are you following?'**
  String get onboardingMaladiesLabel;

  /// No description provided for @onboardingMaladieRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one condition'**
  String get onboardingMaladieRequired;

  /// No description provided for @onboardingMaladiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the catalog. Check your connection.'**
  String get onboardingMaladiesEmpty;

  /// No description provided for @onboardingPhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Where are you in it?'**
  String get onboardingPhaseLabel;

  /// No description provided for @onboardingPhaseDebut.
  ///
  /// In en, this message translates to:
  /// **'Just starting'**
  String get onboardingPhaseDebut;

  /// No description provided for @onboardingPhaseEnCours.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get onboardingPhaseEnCours;

  /// No description provided for @onboardingPhaseMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get onboardingPhaseMaintenance;

  /// No description provided for @onboardingPhaseInconnu.
  ///
  /// In en, this message translates to:
  /// **'I’m not sure'**
  String get onboardingPhaseInconnu;

  /// No description provided for @onboardingPermsTitle.
  ///
  /// In en, this message translates to:
  /// **'So reminders actually ring'**
  String get onboardingPermsTitle;

  /// No description provided for @onboardingPermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We explain before the phone asks. You can skip — reminders may then be unreliable.'**
  String get onboardingPermsSubtitle;

  /// No description provided for @onboardingPermsNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get onboardingPermsNotifTitle;

  /// No description provided for @onboardingPermsNotifBody.
  ///
  /// In en, this message translates to:
  /// **'So we can remind you to take your medication on time, even when the app is closed.'**
  String get onboardingPermsNotifBody;

  /// No description provided for @onboardingPermsBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery (Android)'**
  String get onboardingPermsBatteryTitle;

  /// No description provided for @onboardingPermsBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Without an exemption, some phones kill reminders overnight.'**
  String get onboardingPermsBatteryBody;

  /// No description provided for @onboardingPermsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow reminders'**
  String get onboardingPermsAllow;

  /// No description provided for @onboardingPermsLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get onboardingPermsLater;

  /// No description provided for @onboardingDoneToast.
  ///
  /// In en, this message translates to:
  /// **'You’re all set — welcome to Fidel'**
  String get onboardingDoneToast;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get navCare;

  /// No description provided for @navPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get navPeople;

  /// No description provided for @navYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navYou;

  /// No description provided for @homeHelloMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning {name}'**
  String homeHelloMorning(String name);

  /// No description provided for @homeHelloAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon {name}'**
  String homeHelloAfternoon(String name);

  /// No description provided for @homeHelloEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening {name}'**
  String homeHelloEvening(String name);

  /// No description provided for @homeHelloMorningAnon.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get homeHelloMorningAnon;

  /// No description provided for @homeHelloAfternoonAnon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get homeHelloAfternoonAnon;

  /// No description provided for @homeHelloEveningAnon.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get homeHelloEveningAnon;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Fidel watches your doses — never judges.'**
  String get homeTagline;

  /// No description provided for @homeNotifA11y.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get homeNotifA11y;

  /// No description provided for @homeSettingsA11y.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsA11y;

  /// No description provided for @homeNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get homeNotifTitle;

  /// No description provided for @homeNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders ring on this phone, even offline. Nothing is sent to a relative without your say-so.'**
  String get homeNotifBody;

  /// No description provided for @homeNotifReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders are ready'**
  String get homeNotifReadyTitle;

  /// No description provided for @homeNotifReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Fidel will ping you here, on this device — no score, no judgment.'**
  String get homeNotifReadyBody;

  /// No description provided for @homeTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTodayTitle;

  /// No description provided for @homeNextDoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Next dose'**
  String get homeNextDoseLabel;

  /// No description provided for @homeAllClearTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re up to date'**
  String get homeAllClearTitle;

  /// No description provided for @homeAllClearBody.
  ///
  /// In en, this message translates to:
  /// **'No pending doses right now. Rest a little.'**
  String get homeAllClearBody;

  /// No description provided for @homeStatPending.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get homeStatPending;

  /// No description provided for @homeStatTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get homeStatTaken;

  /// No description provided for @homeStatLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get homeStatLate;

  /// No description provided for @homeNoDoses.
  ///
  /// In en, this message translates to:
  /// **'No schedule yet today. Add a medication to start.'**
  String get homeNoDoses;

  /// No description provided for @homeTakeCta.
  ///
  /// In en, this message translates to:
  /// **'I took it'**
  String get homeTakeCta;

  /// No description provided for @homeTakenBadge.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get homeTakenBadge;

  /// No description provided for @homeTakenToast.
  ///
  /// In en, this message translates to:
  /// **'Noted — well done.'**
  String get homeTakenToast;

  /// No description provided for @homeActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Start my follow-up'**
  String get homeActivateTitle;

  /// No description provided for @homeActivateBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders, treatments and doses for you, on this account.'**
  String get homeActivateBody;

  /// No description provided for @homeAccompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Support someone'**
  String get homeAccompanyTitle;

  /// No description provided for @homeAccompanyBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a relative’s code to follow them, with their consent.'**
  String get homeAccompanyBody;

  /// No description provided for @homeShareCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a caregiver'**
  String get homeShareCodeTitle;

  /// No description provided for @homeShareCodeBody.
  ///
  /// In en, this message translates to:
  /// **'This code expires quickly. Share it only with someone you choose.'**
  String get homeShareCodeBody;

  /// No description provided for @homeActionNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow reminders'**
  String get homeActionNotifTitle;

  /// No description provided for @homeActionNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Without this, the phone may kill alarms overnight.'**
  String get homeActionNotifBody;

  /// No description provided for @homeActionMedsTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your medicines'**
  String get homeActionMedsTitle;

  /// No description provided for @homeActionMedsBody.
  ///
  /// In en, this message translates to:
  /// **'Name, dose and times — that’s what makes reminders ring.'**
  String get homeActionMedsBody;

  /// No description provided for @homeActionMedsFor.
  ///
  /// In en, this message translates to:
  /// **'For {maladie}'**
  String homeActionMedsFor(String maladie);

  /// No description provided for @homeActionTraitementTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a treatment'**
  String get homeActionTraitementTitle;

  /// No description provided for @homeActionTraitementBody.
  ///
  /// In en, this message translates to:
  /// **'We note the condition first; medicines come right after.'**
  String get homeActionTraitementBody;

  /// No description provided for @homeCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your treatments and schedules, in one place.'**
  String get homeCareSubtitle;

  /// No description provided for @homeNetworkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support a relative, or invite someone to help you — always with a clear yes.'**
  String get homeNetworkSubtitle;

  /// No description provided for @homeCareMedsReady.
  ///
  /// In en, this message translates to:
  /// **'Medicines saved'**
  String get homeCareMedsReady;

  /// No description provided for @homeThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get homeThemeLabel;

  /// No description provided for @homeThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get homeThemeLight;

  /// No description provided for @homeThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get homeThemeDark;

  /// No description provided for @homeThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get homeThemeSystem;

  /// No description provided for @homeSyncHint.
  ///
  /// In en, this message translates to:
  /// **'The 6-digit code they generated in Fidel.'**
  String get homeSyncHint;

  /// No description provided for @homeSyncCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get homeSyncCodeLabel;

  /// No description provided for @homeSyncCta.
  ///
  /// In en, this message translates to:
  /// **'Connect to their follow-up'**
  String get homeSyncCta;

  /// No description provided for @homeSyncOk.
  ///
  /// In en, this message translates to:
  /// **'You’re now connected to their follow-up.'**
  String get homeSyncOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @homeSnoozeCta.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get homeSnoozeCta;

  /// No description provided for @homeSnoozeTitle.
  ///
  /// In en, this message translates to:
  /// **'Push this dose back'**
  String get homeSnoozeTitle;

  /// No description provided for @homeSnoozeBody.
  ///
  /// In en, this message translates to:
  /// **'We move the reminder, nothing is erased.'**
  String get homeSnoozeBody;

  /// No description provided for @homeSnoozeDone.
  ///
  /// In en, this message translates to:
  /// **'Moved to {heure}'**
  String homeSnoozeDone(String heure);

  /// No description provided for @homeCountdownIn.
  ///
  /// In en, this message translates to:
  /// **'in {value}'**
  String homeCountdownIn(String value);

  /// No description provided for @homeCountdownLate.
  ///
  /// In en, this message translates to:
  /// **'{value} late'**
  String homeCountdownLate(String value);

  /// No description provided for @homeCountdownNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get homeCountdownNow;

  /// No description provided for @homeDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}'**
  String homeDurationHm(String h, String m);

  /// No description provided for @homeDurationH.
  ///
  /// In en, this message translates to:
  /// **'{h}h'**
  String homeDurationH(int h);

  /// No description provided for @homeDurationM.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String homeDurationM(int m);

  /// No description provided for @homeDayProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Today’s doses'**
  String get homeDayProgressLabel;

  /// No description provided for @homeDayProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Today’s progress'**
  String get homeDayProgressTitle;

  /// No description provided for @homeDayProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Doses confirmed out of those scheduled today. This is not a health score.'**
  String get homeDayProgressHint;

  /// No description provided for @homeDayProgressDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get homeDayProgressDone;

  /// No description provided for @homeDayProgressOngoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get homeDayProgressOngoing;

  /// No description provided for @homeDayProgressUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get homeDayProgressUpcoming;

  /// No description provided for @homeDayProgressLate.
  ///
  /// In en, this message translates to:
  /// **'Some doses are waiting'**
  String get homeDayProgressLate;

  /// No description provided for @homeDayProgressPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} upcoming'**
  String homeDayProgressPendingCount(int count);

  /// No description provided for @homeDayProgressLateCount.
  ///
  /// In en, this message translates to:
  /// **'{count} late'**
  String homeDayProgressLateCount(int count);

  /// No description provided for @homeTodaySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Today’s summary'**
  String get homeTodaySummaryTitle;

  /// No description provided for @homeTodaySummaryViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeTodaySummaryViewAll;

  /// No description provided for @homeTodaySummaryBody.
  ///
  /// In en, this message translates to:
  /// **'Your latest recorded measurements.'**
  String get homeTodaySummaryBody;

  /// No description provided for @homeTodaySummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet. Add one whenever you like.'**
  String get homeTodaySummaryEmpty;

  /// No description provided for @homeDayDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Day complete'**
  String get homeDayDoneTitle;

  /// No description provided for @homeDayDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Every dose is confirmed. Nicely done.'**
  String get homeDayDoneBody;

  /// No description provided for @homeWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get homeWeekTitle;

  /// No description provided for @homeWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} doses confirmed out of {total}'**
  String homeWeekSummary(int confirmed, int total);

  /// No description provided for @homeWeekEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your doses for the week will show up here.'**
  String get homeWeekEmpty;

  /// No description provided for @homeWeekPerfect.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} full day} other{{count} full days}}'**
  String homeWeekPerfect(int count);

  /// No description provided for @homeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} left} other{{count} left}}'**
  String homeRemaining(int count);

  /// No description provided for @homeCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get homeCheckInTitle;

  /// No description provided for @homeCheckInBody.
  ///
  /// In en, this message translates to:
  /// **'One tap a day, just to keep track.'**
  String get homeCheckInBody;

  /// No description provided for @homeCheckInOk.
  ///
  /// In en, this message translates to:
  /// **'I’m okay'**
  String get homeCheckInOk;

  /// No description provided for @homeCheckInBad.
  ///
  /// In en, this message translates to:
  /// **'Not great'**
  String get homeCheckInBad;

  /// No description provided for @homeCheckInDoneOk.
  ///
  /// In en, this message translates to:
  /// **'Today: okay'**
  String get homeCheckInDoneOk;

  /// No description provided for @homeCheckInDoneBad.
  ///
  /// In en, this message translates to:
  /// **'Today: not great'**
  String get homeCheckInDoneBad;

  /// No description provided for @homeCheckInThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, noted.'**
  String get homeCheckInThanks;

  /// No description provided for @homeTreatmentDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String homeTreatmentDay(int day);

  /// No description provided for @homeTreatmentDayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String homeTreatmentDayOf(int day, int total);

  /// No description provided for @homeTreatmentDayUnit.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get homeTreatmentDayUnit;

  /// No description provided for @homeTreatmentOngoing.
  ///
  /// In en, this message translates to:
  /// **'Treatment in progress'**
  String get homeTreatmentOngoing;

  /// No description provided for @homePhaseDebut.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homePhaseDebut;

  /// No description provided for @homePhaseEnCours.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get homePhaseEnCours;

  /// No description provided for @homePhaseMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get homePhaseMaintenance;

  /// No description provided for @homeMomentMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get homeMomentMorning;

  /// No description provided for @homeMomentAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get homeMomentAfternoon;

  /// No description provided for @homeMomentEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get homeMomentEvening;

  /// No description provided for @homeVitalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your tracking'**
  String get homeVitalsTitle;

  /// No description provided for @homeVitalsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get homeVitalsAdd;

  /// No description provided for @homeVitalsFirst.
  ///
  /// In en, this message translates to:
  /// **'First measurement saved. The curve shows up from the next one.'**
  String get homeVitalsFirst;

  /// No description provided for @homeVitalsSystolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get homeVitalsSystolic;

  /// No description provided for @homeVitalsDiastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get homeVitalsDiastolic;

  /// No description provided for @homeVitalsSaved.
  ///
  /// In en, this message translates to:
  /// **'Measurement saved.'**
  String get homeVitalsSaved;

  /// No description provided for @homeVitalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Track a measurement'**
  String get homeVitalsEmptyTitle;

  /// No description provided for @homeVitalsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Weight, blood pressure, blood sugar… now and then is enough.'**
  String get homeVitalsEmptyBody;

  /// No description provided for @constantePoids.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get constantePoids;

  /// No description provided for @constanteTension.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get constanteTension;

  /// No description provided for @constanteGlycemie.
  ///
  /// In en, this message translates to:
  /// **'Blood sugar'**
  String get constanteGlycemie;

  /// No description provided for @constanteTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get constanteTemperature;

  /// No description provided for @constanteSommeil.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get constanteSommeil;

  /// No description provided for @constanteHumeur.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get constanteHumeur;

  /// No description provided for @addVitalTitle.
  ///
  /// In en, this message translates to:
  /// **'New measurement'**
  String get addVitalTitle;

  /// No description provided for @addVitalValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get addVitalValue;

  /// No description provided for @addVitalSystolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get addVitalSystolic;

  /// No description provided for @addVitalDiastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get addVitalDiastolic;

  /// No description provided for @addVitalDate.
  ///
  /// In en, this message translates to:
  /// **'Measured on'**
  String get addVitalDate;

  /// No description provided for @addVitalSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get addVitalSave;

  /// No description provided for @addVitalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get addVitalInvalid;

  /// No description provided for @medsWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your medicines'**
  String get medsWizardTitle;

  /// No description provided for @medsWizardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One line is enough to start. You can add more later.'**
  String get medsWizardSubtitle;

  /// No description provided for @medsSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get medsSuggestions;

  /// No description provided for @medsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medsNameLabel;

  /// No description provided for @medsDoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get medsDoseLabel;

  /// No description provided for @medsDoseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500 mg'**
  String get medsDoseHint;

  /// No description provided for @medsTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose times'**
  String get medsTimesLabel;

  /// No description provided for @medsAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get medsAddTime;

  /// No description provided for @medsNeedTime.
  ///
  /// In en, this message translates to:
  /// **'Add at least one time'**
  String get medsNeedTime;

  /// No description provided for @medsSaveCta.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get medsSaveCta;

  /// No description provided for @medsSaved.
  ///
  /// In en, this message translates to:
  /// **'Medicine saved. Today’s doses are ready.'**
  String get medsSaved;
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

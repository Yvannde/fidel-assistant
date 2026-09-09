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
  /// **'Profile'**
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

  /// No description provided for @homeMoreA11y.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get homeMoreA11y;

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

  /// No description provided for @homeAidantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your caregivers'**
  String get homeAidantsTitle;

  /// No description provided for @homeAidantsIntro.
  ///
  /// In en, this message translates to:
  /// **'You can invite someone to support you on Fidel — always with your consent.'**
  String get homeAidantsIntro;

  /// No description provided for @homeAidantsSection.
  ///
  /// In en, this message translates to:
  /// **'Caregiver status'**
  String get homeAidantsSection;

  /// No description provided for @homeAidantsSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a caregiver to manage access or remove them.'**
  String get homeAidantsSectionHint;

  /// No description provided for @homeAidantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No caregivers yet.'**
  String get homeAidantsEmpty;

  /// No description provided for @homeAidantsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No caregivers yet'**
  String get homeAidantsEmptyTitle;

  /// No description provided for @homeAidantsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Invite someone you trust to support your doses — you stay in control of what they can see.'**
  String get homeAidantsEmptyBody;

  /// No description provided for @homeAidantsInviteCta.
  ///
  /// In en, this message translates to:
  /// **'Invite a caregiver'**
  String get homeAidantsInviteCta;

  /// No description provided for @homeAidantsTrust.
  ///
  /// In en, this message translates to:
  /// **'Access is limited to what you allow. You can revoke anytime —'**
  String get homeAidantsTrust;

  /// No description provided for @homeAidantsTrustHighlight.
  ///
  /// In en, this message translates to:
  /// **'always with your consent.'**
  String get homeAidantsTrustHighlight;

  /// No description provided for @homeAidantsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage access'**
  String get homeAidantsManageTitle;

  /// No description provided for @homeAidantsPermObservance.
  ///
  /// In en, this message translates to:
  /// **'See doses'**
  String get homeAidantsPermObservance;

  /// No description provided for @homeAidantsPermConstantes.
  ///
  /// In en, this message translates to:
  /// **'See vitals'**
  String get homeAidantsPermConstantes;

  /// No description provided for @homeAidantsRevoke.
  ///
  /// In en, this message translates to:
  /// **'Remove access'**
  String get homeAidantsRevoke;

  /// No description provided for @homeAidantsRevoked.
  ///
  /// In en, this message translates to:
  /// **'This caregiver no longer has access to your follow-up.'**
  String get homeAidantsRevoked;

  /// No description provided for @homeAidantsPermObservanceOnly.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get homeAidantsPermObservanceOnly;

  /// No description provided for @homeAidantsPermBoth.
  ///
  /// In en, this message translates to:
  /// **'Adherence and vitals'**
  String get homeAidantsPermBoth;

  /// No description provided for @homeAidantsPermNone.
  ///
  /// In en, this message translates to:
  /// **'Limited access'**
  String get homeAidantsPermNone;

  /// No description provided for @homeInviteCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get homeInviteCopy;

  /// No description provided for @homeInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get homeInviteCopied;

  /// No description provided for @homeInviteAltLink.
  ///
  /// In en, this message translates to:
  /// **'Have a code? Support someone'**
  String get homeInviteAltLink;

  /// No description provided for @homeInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Share this code with the person you invite. They enter it in Fidel to join your follow-up.'**
  String get homeInviteHint;

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
  /// **'Vitals, doses and log — the detail of your follow-up.'**
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

  /// No description provided for @homeCareTreatments.
  ///
  /// In en, this message translates to:
  /// **'Your treatments'**
  String get homeCareTreatments;

  /// No description provided for @homeCareWeek.
  ///
  /// In en, this message translates to:
  /// **'This week’s adherence'**
  String get homeCareWeek;

  /// No description provided for @homeCareAddMed.
  ///
  /// In en, this message translates to:
  /// **'Add a medicine'**
  String get homeCareAddMed;

  /// No description provided for @homeCareConfigureMeds.
  ///
  /// In en, this message translates to:
  /// **'Set up medicines'**
  String get homeCareConfigureMeds;

  /// No description provided for @homeCareEmptyPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate your follow-up'**
  String get homeCareEmptyPatientTitle;

  /// No description provided for @homeCareActionTraitement.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get homeCareActionTraitement;

  /// No description provided for @homeCareActionMeds.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get homeCareActionMeds;

  /// No description provided for @homeCareActionMedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get homeCareActionMedsSetup;

  /// No description provided for @homeCareActionVital.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get homeCareActionVital;

  /// No description provided for @homeCareJournal.
  ///
  /// In en, this message translates to:
  /// **'Follow-up log'**
  String get homeCareJournal;

  /// No description provided for @homeCareJournalEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Confirm a dose or add a measurement.'**
  String get homeCareJournalEmpty;

  /// No description provided for @homeCareProgressPrises.
  ///
  /// In en, this message translates to:
  /// **'Doses'**
  String get homeCareProgressPrises;

  /// No description provided for @homeCareProgressLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get homeCareProgressLate;

  /// No description provided for @homeCareProgressCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get homeCareProgressCheckIn;

  /// No description provided for @homeCareProgressCheckInTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get homeCareProgressCheckInTodo;

  /// No description provided for @homeCareProgressCheckInOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get homeCareProgressCheckInOk;

  /// No description provided for @homeCareProgressCheckInBad.
  ///
  /// In en, this message translates to:
  /// **'Not great'**
  String get homeCareProgressCheckInBad;

  /// No description provided for @homeCareHeroDosesLabel.
  ///
  /// In en, this message translates to:
  /// **'Today’s doses'**
  String get homeCareHeroDosesLabel;

  /// No description provided for @homeCareHeroDosesValue.
  ///
  /// In en, this message translates to:
  /// **'{taken} / {total}'**
  String homeCareHeroDosesValue(int taken, int total);

  /// No description provided for @homeCareHeroNoVital.
  ///
  /// In en, this message translates to:
  /// **'Add a measurement to see your curve here.'**
  String get homeCareHeroNoVital;

  /// No description provided for @homeCareFeedPriseTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get homeCareFeedPriseTaken;

  /// No description provided for @homeCareFeedPriseMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get homeCareFeedPriseMissed;

  /// No description provided for @homeCareFeedPrisePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get homeCareFeedPrisePending;

  /// No description provided for @homeCareOfValue.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String homeCareOfValue(int current, int total);

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

  /// No description provided for @medsNeedDays.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day'**
  String get medsNeedDays;

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

  /// No description provided for @medsAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another medicine'**
  String get medsAddAnother;

  /// No description provided for @medsSaveAndAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Save and add another'**
  String get medsSaveAndAddAnother;

  /// No description provided for @medsFinishCta.
  ///
  /// In en, this message translates to:
  /// **'Done — go home'**
  String get medsFinishCta;

  /// No description provided for @medsConfiguredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} medicine already on this treatment} other{{count} medicines already on this treatment}}'**
  String medsConfiguredCount(int count);

  /// No description provided for @medsMultiHint.
  ///
  /// In en, this message translates to:
  /// **'Add as many as you need for this treatment, one at a time.'**
  String get medsMultiHint;

  /// No description provided for @configStepMaladie.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get configStepMaladie;

  /// No description provided for @configStepContexte.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get configStepContexte;

  /// No description provided for @configStepIdentite.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get configStepIdentite;

  /// No description provided for @configStepHoraires.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get configStepHoraires;

  /// No description provided for @configStepRecap.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get configStepRecap;

  /// No description provided for @configTraitementTitle.
  ///
  /// In en, this message translates to:
  /// **'Which treatment are you on?'**
  String get configTraitementTitle;

  /// No description provided for @configTraitementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the condition you follow. Medicines come right after.'**
  String get configTraitementSubtitle;

  /// No description provided for @configPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you in it?'**
  String get configPhaseTitle;

  /// No description provided for @configPhaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Phase and start date help Fidel contextualize your follow-up.'**
  String get configPhaseSubtitle;

  /// No description provided for @configTraitementCreate.
  ///
  /// In en, this message translates to:
  /// **'Set up medicines'**
  String get configTraitementCreate;

  /// No description provided for @configDateDebutLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get configDateDebutLabel;

  /// No description provided for @configDateDebutHint.
  ///
  /// In en, this message translates to:
  /// **'If you’re unsure, leave today’s date.'**
  String get configDateDebutHint;

  /// No description provided for @medsStepIdentiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your medicine'**
  String get medsStepIdentiteTitle;

  /// No description provided for @medsStepIdentiteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A protocol suggestion, or free entry — you’re in control.'**
  String get medsStepIdentiteSubtitle;

  /// No description provided for @medsStepHorairesTitle.
  ///
  /// In en, this message translates to:
  /// **'When to take it?'**
  String get medsStepHorairesTitle;

  /// No description provided for @medsStepHorairesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Times and days drive your reminders.'**
  String get medsStepHorairesSubtitle;

  /// No description provided for @medsStepRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Looking good?'**
  String get medsStepRecapTitle;

  /// No description provided for @medsStepRecapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save then add the next one, or finish if this is the last.'**
  String get medsStepRecapSubtitle;

  /// No description provided for @medsFormeLabel.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get medsFormeLabel;

  /// No description provided for @medsFormeComprime.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get medsFormeComprime;

  /// No description provided for @medsFormeSirop.
  ///
  /// In en, this message translates to:
  /// **'Syrup'**
  String get medsFormeSirop;

  /// No description provided for @medsFormeInjection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get medsFormeInjection;

  /// No description provided for @medsFormeAutre.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get medsFormeAutre;

  /// No description provided for @medsDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get medsDaysLabel;

  /// No description provided for @medsDaysEvery.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get medsDaysEvery;

  /// No description provided for @medsDaysCustom.
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get medsDaysCustom;

  /// No description provided for @medsDayMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get medsDayMon;

  /// No description provided for @medsDayTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get medsDayTue;

  /// No description provided for @medsDayWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get medsDayWed;

  /// No description provided for @medsDayThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get medsDayThu;

  /// No description provided for @medsDayFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get medsDayFri;

  /// No description provided for @medsDaySat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get medsDaySat;

  /// No description provided for @medsDaySun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get medsDaySun;

  /// No description provided for @medsRepasLabel.
  ///
  /// In en, this message translates to:
  /// **'With meals'**
  String get medsRepasLabel;

  /// No description provided for @medsRepasNone.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get medsRepasNone;

  /// No description provided for @medsRepasAvant.
  ///
  /// In en, this message translates to:
  /// **'Before meals'**
  String get medsRepasAvant;

  /// No description provided for @medsRepasApres.
  ///
  /// In en, this message translates to:
  /// **'After meals'**
  String get medsRepasApres;

  /// No description provided for @medsRepasIndifferent.
  ///
  /// In en, this message translates to:
  /// **'Doesn’t matter'**
  String get medsRepasIndifferent;

  /// No description provided for @medsRecapTraitementHint.
  ///
  /// In en, this message translates to:
  /// **'Linked to this treatment'**
  String get medsRecapTraitementHint;

  /// No description provided for @medsRecapTrust.
  ///
  /// In en, this message translates to:
  /// **'You can adjust later. Fidel doesn’t give medical advice — only reminders based on what you set.'**
  String get medsRecapTrust;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account, preferences and follow-up — all in one place.'**
  String get profileSubtitle;

  /// No description provided for @profileFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Fidel account'**
  String get profileFallbackName;

  /// No description provided for @profileChipPatient.
  ///
  /// In en, this message translates to:
  /// **'Follow-up on'**
  String get profileChipPatient;

  /// No description provided for @profileChipAidant.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get profileChipAidant;

  /// No description provided for @profileChipAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileChipAccount;

  /// No description provided for @profileSectionPrefs.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPrefs;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileSectionFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up & alerts'**
  String get profileSectionFollowUp;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders and alerts'**
  String get profileNotificationsHint;

  /// No description provided for @profileAidantsHint.
  ///
  /// In en, this message translates to:
  /// **'Manage people who help you'**
  String get profileAidantsHint;

  /// No description provided for @profileAidantsLocked.
  ///
  /// In en, this message translates to:
  /// **'Activate your patient follow-up first'**
  String get profileAidantsLocked;

  /// No description provided for @profileActivateOk.
  ///
  /// In en, this message translates to:
  /// **'Follow-up activated'**
  String get profileActivateOk;

  /// No description provided for @profileSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get profileSectionLegal;

  /// No description provided for @profileCgu.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get profileCgu;

  /// No description provided for @profileCguVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileCguVersion(String version);

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'You’ll sign out on this device. Your data stays safe.'**
  String get profileLogoutConfirm;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get profileAccountTitle;

  /// No description provided for @profileAccountTileHint.
  ///
  /// In en, this message translates to:
  /// **'Phone, time zone'**
  String get profileAccountTileHint;

  /// No description provided for @profileAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Details linked to your Fidel account — no medical advice here.'**
  String get profileAccountHint;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get profileTimezone;

  /// No description provided for @profilePatientSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow-up settings'**
  String get profilePatientSettingsTitle;

  /// No description provided for @profilePatientSettingsTileHint.
  ///
  /// In en, this message translates to:
  /// **'Notifications, battery, discreet mode'**
  String get profilePatientSettingsTileHint;

  /// No description provided for @profilePatientSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'These options only apply to your patient follow-up on this device and account.'**
  String get profilePatientSettingsHint;

  /// No description provided for @profileNotifGranted.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get profileNotifGranted;

  /// No description provided for @profileNotifGrantedHint.
  ///
  /// In en, this message translates to:
  /// **'Whether Fidel may remind you about doses'**
  String get profileNotifGrantedHint;

  /// No description provided for @profileBatteryExempt.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted battery'**
  String get profileBatteryExempt;

  /// No description provided for @profileBatteryExemptHint.
  ///
  /// In en, this message translates to:
  /// **'Helps keep reminders working overnight'**
  String get profileBatteryExemptHint;

  /// No description provided for @profileDiscreteNotif.
  ///
  /// In en, this message translates to:
  /// **'Discreet notifications'**
  String get profileDiscreteNotif;

  /// No description provided for @profileDiscreteNotifHint.
  ///
  /// In en, this message translates to:
  /// **'Sobriety-friendly wording without sensitive detail'**
  String get profileDiscreteNotifHint;

  /// No description provided for @profileContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get profileContactsTitle;

  /// No description provided for @profileContactsTileHint.
  ///
  /// In en, this message translates to:
  /// **'For SOS and escalation'**
  String get profileContactsTileHint;

  /// No description provided for @profileContactsHint.
  ///
  /// In en, this message translates to:
  /// **'These people may be reached if you trigger SOS. You stay in control of that gesture.'**
  String get profileContactsHint;

  /// No description provided for @profileContactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet.'**
  String get profileContactsEmpty;

  /// No description provided for @profileContactAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a contact'**
  String get profileContactAdd;

  /// No description provided for @profileContactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileContactName;

  /// No description provided for @profileContactRelation.
  ///
  /// In en, this message translates to:
  /// **'Relation (e.g. son, neighbour)'**
  String get profileContactRelation;

  /// No description provided for @profileContactDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove contact'**
  String get profileContactDelete;

  /// No description provided for @profileContactDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your emergency contacts?'**
  String profileContactDeleteConfirm(String name);

  /// No description provided for @profileVoixTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder voice'**
  String get profileVoixTitle;

  /// No description provided for @profileVoixTileHint.
  ///
  /// In en, this message translates to:
  /// **'System or custom message'**
  String get profileVoixTileHint;

  /// No description provided for @profileVoixHint.
  ///
  /// In en, this message translates to:
  /// **'Sound for the local reminder. Short audio (mp3, m4a…), max 2 MB.'**
  String get profileVoixHint;

  /// No description provided for @profileVoixSystem.
  ///
  /// In en, this message translates to:
  /// **'System voice'**
  String get profileVoixSystem;

  /// No description provided for @profileVoixSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Standard phone notification'**
  String get profileVoixSystemHint;

  /// No description provided for @profileVoixCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom voice'**
  String get profileVoixCustom;

  /// No description provided for @profileVoixCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an audio file'**
  String get profileVoixCustomHint;

  /// No description provided for @profileVoixCustomActive.
  ///
  /// In en, this message translates to:
  /// **'Custom file active'**
  String get profileVoixCustomActive;

  /// No description provided for @profileVoixPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read that file. Try again with mp3 or m4a.'**
  String get profileVoixPickFailed;

  /// No description provided for @profileVoixTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large — 2 MB max.'**
  String get profileVoixTooLarge;

  /// No description provided for @profileContactsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add at least one trusted person for SOS.'**
  String get profileContactsEmptyHint;

  /// No description provided for @profileContactAddHint.
  ///
  /// In en, this message translates to:
  /// **'Name, number and relation — used only if you trigger SOS.'**
  String get profileContactAddHint;

  /// No description provided for @profileSectionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts & consent'**
  String get profileSectionAlerts;

  /// No description provided for @profileConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert preferences'**
  String get profileConsentTitle;

  /// No description provided for @profileConsentTileHint.
  ///
  /// In en, this message translates to:
  /// **'Always ask before alerting a third party'**
  String get profileConsentTileHint;

  /// No description provided for @profileConsentHint.
  ///
  /// In en, this message translates to:
  /// **'By default, Fidel always asks before notifying someone. Turning off “always ask” enables an opt-in auto rule (e.g. 48h) — never pre-checked.'**
  String get profileConsentHint;

  /// No description provided for @profileConsentAlwaysAsk.
  ///
  /// In en, this message translates to:
  /// **'Always ask me'**
  String get profileConsentAlwaysAsk;

  /// No description provided for @profileConsentAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Opt-in auto rule (48h delay)'**
  String get profileConsentAutoHint;

  /// No description provided for @profileAlertRappelMed.
  ///
  /// In en, this message translates to:
  /// **'Medication reminder'**
  String get profileAlertRappelMed;

  /// No description provided for @profileAlertStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get profileAlertStock;

  /// No description provided for @profileAlertConstanteUp.
  ///
  /// In en, this message translates to:
  /// **'Improving vitals'**
  String get profileAlertConstanteUp;

  /// No description provided for @profileAlertConstanteDown.
  ///
  /// In en, this message translates to:
  /// **'Vitals to watch'**
  String get profileAlertConstanteDown;

  /// No description provided for @profileAlertCheckin.
  ///
  /// In en, this message translates to:
  /// **'Missed check-in'**
  String get profileAlertCheckin;

  /// No description provided for @profileAlertDepistage.
  ///
  /// In en, this message translates to:
  /// **'Screening recommended'**
  String get profileAlertDepistage;

  /// No description provided for @profileSectionCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Support someone'**
  String get profileSectionCaregiver;

  /// No description provided for @profileSyncTileHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a code to become a caregiver'**
  String get profileSyncTileHint;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteTileHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently disable access'**
  String get profileDeleteTileHint;

  /// No description provided for @profileDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deactivated (soft delete). You can only sign back in if support reactivates you.'**
  String get profileDeleteHint;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm deleting your Fidel account?'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAction;
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

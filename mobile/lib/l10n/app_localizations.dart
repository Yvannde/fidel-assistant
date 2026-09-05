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
  /// **'Go to home'**
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

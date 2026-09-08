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
  String onboardingStepOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingStepProfil => 'You';

  @override
  String get onboardingStepSuivi => 'Care';

  @override
  String get onboardingStepTraitement => 'Treatment';

  @override
  String get onboardingStepRappels => 'Reminders';

  @override
  String get onboardingGateLoading => 'Preparing your space…';

  @override
  String get onboardingRetry => 'Try again';

  @override
  String get onboardingInfosTitle => 'What should we call you?';

  @override
  String get onboardingInfosSubtitle =>
      'A few details to personalize Fidel. Nothing is locked in.';

  @override
  String get onboardingNameLabel => 'Full name';

  @override
  String get onboardingBirthLabel => 'Date of birth';

  @override
  String get onboardingBirthHint => 'Pick a date';

  @override
  String get onboardingBirthRequired => 'Please enter your date of birth';

  @override
  String get onboardingSexLabel => 'Sex';

  @override
  String get onboardingSexF => 'Woman';

  @override
  String get onboardingSexM => 'Man';

  @override
  String get onboardingSexOther => 'Other';

  @override
  String get onboardingLocationLabel => 'City / neighborhood';

  @override
  String get onboardingLocationHint => 'e.g. Douala, Akwa';

  @override
  String get onboardingPhoneLabel => 'Phone';

  @override
  String get onboardingPhoneHint => '+237 6…';

  @override
  String get onboardingPhoneOptional => 'Optional — you can add it later';

  @override
  String get onboardingBesoinTitle => 'Do you want follow-up for yourself?';

  @override
  String get onboardingBesoinSubtitle =>
      'You can also support someone from home. Both are possible, without a second account.';

  @override
  String get onboardingBesoinYesTitle => 'Yes, follow-up for me';

  @override
  String get onboardingBesoinYesSubtitle =>
      'Medication reminders, vitals, and personal accompaniment';

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
      'If yes, tick what you follow. Medicines and schedules come later — no pressure.';

  @override
  String get onboardingTraitementYes => 'Yes, I’m in treatment';

  @override
  String get onboardingTraitementYesSubtitle =>
      'We only note the condition and phase for now';

  @override
  String get onboardingTraitementNo => 'Not right now';

  @override
  String get onboardingTraitementNoSubtitle =>
      'You can add this later from home';

  @override
  String get onboardingTraitementNoHint =>
      'No problem — you can activate follow-up later.';

  @override
  String get onboardingMaladiesLabel => 'What are you following?';

  @override
  String get onboardingMaladieRequired => 'Select at least one condition';

  @override
  String get onboardingMaladiesEmpty =>
      'Couldn’t load the catalog. Check your connection.';

  @override
  String get onboardingPhaseLabel => 'Where are you in it?';

  @override
  String get onboardingPhaseDebut => 'Just starting';

  @override
  String get onboardingPhaseEnCours => 'Ongoing';

  @override
  String get onboardingPhaseMaintenance => 'Maintenance';

  @override
  String get onboardingPhaseInconnu => 'I’m not sure';

  @override
  String get onboardingPermsTitle => 'So reminders actually ring';

  @override
  String get onboardingPermsSubtitle =>
      'We explain before the phone asks. You can skip — reminders may then be unreliable.';

  @override
  String get onboardingPermsNotifTitle => 'Notifications';

  @override
  String get onboardingPermsNotifBody =>
      'So we can remind you to take your medication on time, even when the app is closed.';

  @override
  String get onboardingPermsBatteryTitle => 'Battery (Android)';

  @override
  String get onboardingPermsBatteryBody =>
      'Without an exemption, some phones kill reminders overnight.';

  @override
  String get onboardingPermsAllow => 'Allow reminders';

  @override
  String get onboardingPermsLater => 'Later';

  @override
  String get onboardingDoneToast => 'You’re all set — welcome to Fidel';

  @override
  String get navHome => 'Home';

  @override
  String get navCare => 'Care';

  @override
  String get navPeople => 'People';

  @override
  String get navYou => 'You';

  @override
  String homeHelloMorning(String name) {
    return 'Good morning $name';
  }

  @override
  String homeHelloAfternoon(String name) {
    return 'Good afternoon $name';
  }

  @override
  String homeHelloEvening(String name) {
    return 'Good evening $name';
  }

  @override
  String get homeHelloMorningAnon => 'Good morning!';

  @override
  String get homeHelloAfternoonAnon => 'Good afternoon!';

  @override
  String get homeHelloEveningAnon => 'Good evening!';

  @override
  String get homeTagline => 'Fidel watches your doses — never judges.';

  @override
  String get homeNotifA11y => 'Reminders';

  @override
  String get homeSettingsA11y => 'Settings';

  @override
  String get homeMoreA11y => 'More options';

  @override
  String get homeNotifTitle => 'Reminders';

  @override
  String get homeNotifBody =>
      'Reminders ring on this phone, even offline. Nothing is sent to a relative without your say-so.';

  @override
  String get homeNotifReadyTitle => 'Reminders are ready';

  @override
  String get homeNotifReadyBody =>
      'Fidel will ping you here, on this device — no score, no judgment.';

  @override
  String get homeTodayTitle => 'Today';

  @override
  String get homeNextDoseLabel => 'Next dose';

  @override
  String get homeAllClearTitle => 'You’re up to date';

  @override
  String get homeAllClearBody => 'No pending doses right now. Rest a little.';

  @override
  String get homeStatPending => 'Due';

  @override
  String get homeStatTaken => 'Taken';

  @override
  String get homeStatLate => 'Late';

  @override
  String get homeNoDoses => 'No schedule yet today. Add a medication to start.';

  @override
  String get homeTakeCta => 'I took it';

  @override
  String get homeTakenBadge => 'Taken';

  @override
  String get homeTakenToast => 'Noted — well done.';

  @override
  String get homeActivateTitle => 'Start my follow-up';

  @override
  String get homeActivateBody =>
      'Reminders, treatments and doses for you, on this account.';

  @override
  String get homeAccompanyTitle => 'Support someone';

  @override
  String get homeAccompanyBody =>
      'Enter a relative’s code to follow them, with their consent.';

  @override
  String get homeShareCodeTitle => 'Invite a caregiver';

  @override
  String get homeShareCodeBody =>
      'This code expires quickly. Share it only with someone you choose.';

  @override
  String get homeActionNotifTitle => 'Allow reminders';

  @override
  String get homeActionNotifBody =>
      'Without this, the phone may kill alarms overnight.';

  @override
  String get homeActionMedsTitle => 'Set up your medicines';

  @override
  String get homeActionMedsBody =>
      'Name, dose and times — that’s what makes reminders ring.';

  @override
  String homeActionMedsFor(String maladie) {
    return 'For $maladie';
  }

  @override
  String get homeActionTraitementTitle => 'Add a treatment';

  @override
  String get homeActionTraitementBody =>
      'We note the condition first; medicines come right after.';

  @override
  String get homeCareSubtitle => 'Your treatments and schedules, in one place.';

  @override
  String get homeNetworkSubtitle =>
      'Support a relative, or invite someone to help you — always with a clear yes.';

  @override
  String get homeCareMedsReady => 'Medicines saved';

  @override
  String get homeThemeLabel => 'Appearance';

  @override
  String get homeThemeLight => 'Light';

  @override
  String get homeThemeDark => 'Dark';

  @override
  String get homeThemeSystem => 'System';

  @override
  String get homeSyncHint => 'The 6-digit code they generated in Fidel.';

  @override
  String get homeSyncCodeLabel => 'Code';

  @override
  String get homeSyncCta => 'Connect to their follow-up';

  @override
  String get homeSyncOk => 'You’re now connected to their follow-up.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get homeSnoozeCta => 'Later';

  @override
  String get homeSnoozeTitle => 'Push this dose back';

  @override
  String get homeSnoozeBody => 'We move the reminder, nothing is erased.';

  @override
  String homeSnoozeDone(String heure) {
    return 'Moved to $heure';
  }

  @override
  String homeCountdownIn(String value) {
    return 'in $value';
  }

  @override
  String homeCountdownLate(String value) {
    return '$value late';
  }

  @override
  String get homeCountdownNow => 'now';

  @override
  String homeDurationHm(String h, String m) {
    return '${h}h $m';
  }

  @override
  String homeDurationH(int h) {
    return '${h}h';
  }

  @override
  String homeDurationM(int m) {
    return '$m min';
  }

  @override
  String get homeDayProgressLabel => 'Today’s doses';

  @override
  String get homeDayProgressTitle => 'Today’s progress';

  @override
  String get homeDayProgressHint =>
      'Doses confirmed out of those scheduled today. This is not a health score.';

  @override
  String get homeDayProgressDone => 'Done';

  @override
  String get homeDayProgressOngoing => 'In progress';

  @override
  String get homeDayProgressUpcoming => 'Upcoming';

  @override
  String get homeDayProgressLate => 'Some doses are waiting';

  @override
  String homeDayProgressPendingCount(int count) {
    return '$count upcoming';
  }

  @override
  String homeDayProgressLateCount(int count) {
    return '$count late';
  }

  @override
  String get homeTodaySummaryTitle => 'Today’s summary';

  @override
  String get homeTodaySummaryViewAll => 'View all';

  @override
  String get homeTodaySummaryBody => 'Your latest recorded measurements.';

  @override
  String get homeTodaySummaryEmpty =>
      'No measurements yet. Add one whenever you like.';

  @override
  String get homeDayDoneTitle => 'Day complete';

  @override
  String get homeDayDoneBody => 'Every dose is confirmed. Nicely done.';

  @override
  String get homeWeekTitle => 'Your week';

  @override
  String homeWeekSummary(int confirmed, int total) {
    return '$confirmed doses confirmed out of $total';
  }

  @override
  String get homeWeekEmpty => 'Your doses for the week will show up here.';

  @override
  String homeWeekPerfect(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count full days',
      one: '$count full day',
    );
    return '$_temp0';
  }

  @override
  String homeRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left',
      one: '$count left',
    );
    return '$_temp0';
  }

  @override
  String get homeCheckInTitle => 'How are you feeling today?';

  @override
  String get homeCheckInBody => 'One tap a day, just to keep track.';

  @override
  String get homeCheckInOk => 'I’m okay';

  @override
  String get homeCheckInBad => 'Not great';

  @override
  String get homeCheckInDoneOk => 'Today: okay';

  @override
  String get homeCheckInDoneBad => 'Today: not great';

  @override
  String get homeCheckInThanks => 'Thanks, noted.';

  @override
  String homeTreatmentDay(int day) {
    return 'Day $day';
  }

  @override
  String homeTreatmentDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String get homeTreatmentDayUnit => 'day';

  @override
  String get homeTreatmentOngoing => 'Treatment in progress';

  @override
  String get homePhaseDebut => 'Start';

  @override
  String get homePhaseEnCours => 'Ongoing';

  @override
  String get homePhaseMaintenance => 'Maintenance';

  @override
  String get homeMomentMorning => 'Morning';

  @override
  String get homeMomentAfternoon => 'Afternoon';

  @override
  String get homeMomentEvening => 'Evening';

  @override
  String get homeVitalsTitle => 'Your tracking';

  @override
  String get homeVitalsAdd => 'Add';

  @override
  String get homeVitalsFirst =>
      'First measurement saved. The curve shows up from the next one.';

  @override
  String get homeVitalsSystolic => 'Systolic';

  @override
  String get homeVitalsDiastolic => 'Diastolic';

  @override
  String get homeVitalsSaved => 'Measurement saved.';

  @override
  String get homeVitalsEmptyTitle => 'Track a measurement';

  @override
  String get homeVitalsEmptyBody =>
      'Weight, blood pressure, blood sugar… now and then is enough.';

  @override
  String get constantePoids => 'Weight';

  @override
  String get constanteTension => 'Blood pressure';

  @override
  String get constanteGlycemie => 'Blood sugar';

  @override
  String get constanteTemperature => 'Temperature';

  @override
  String get constanteSommeil => 'Sleep';

  @override
  String get constanteHumeur => 'Mood';

  @override
  String get addVitalTitle => 'New measurement';

  @override
  String get addVitalValue => 'Value';

  @override
  String get addVitalSystolic => 'Systolic';

  @override
  String get addVitalDiastolic => 'Diastolic';

  @override
  String get addVitalDate => 'Measured on';

  @override
  String get addVitalSave => 'Save';

  @override
  String get addVitalInvalid => 'Enter a valid number.';

  @override
  String get medsWizardTitle => 'Your medicines';

  @override
  String get medsWizardSubtitle =>
      'One line is enough to start. You can add more later.';

  @override
  String get medsSuggestions => 'Suggestions';

  @override
  String get medsNameLabel => 'Medicine name';

  @override
  String get medsDoseLabel => 'Dosage';

  @override
  String get medsDoseHint => 'e.g. 500 mg';

  @override
  String get medsTimesLabel => 'Dose times';

  @override
  String get medsAddTime => 'Add a time';

  @override
  String get medsNeedTime => 'Add at least one time';

  @override
  String get medsSaveCta => 'Save';

  @override
  String get medsSaved => 'Medicine saved. Today’s doses are ready.';
}

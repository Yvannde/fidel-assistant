/// Configuration runtime de l'app (endpoints, noms).
///
/// Surcharger l'API via :
/// `flutter run --dart-define=API_BASE_URL=https://educampro.edu.cm`
class AppConfig {
  static const String appName = 'Fidel Assistant';

  /// Prod : https://educampro.edu.cm
  /// Émulateur Android → machine hôte : http://10.0.2.2:8000
  /// iOS simulateur / desktop : http://127.0.0.1:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String apiV1Prefix = '/api/v1';

  /// Base complète des endpoints versionnés.
  static String get apiV1Base => '$apiBaseUrl$apiV1Prefix';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Client IDs Google (dart-define) — voir docs/google-auth-setup.md
  static const String googleClientIdAndroid = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_ANDROID',
  );
  static const String googleClientIdIos = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_IOS',
  );
  static const String googleClientIdWeb = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_WEB',
  );
}

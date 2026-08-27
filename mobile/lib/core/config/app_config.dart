/// Configuration runtime de l'app (endpoints, noms).
class AppConfig {
  static const String appName = 'Fidel Assistant';

  /// URL de l'API FastAPI — surcharger via --dart-define=API_BASE_URL=...
  /// Prod : https://educampro.edu.cm
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // émulateur Android → localhost host
  );

  static const String apiV1Prefix = '/api/v1';
}

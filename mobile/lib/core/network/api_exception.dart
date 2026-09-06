/// Erreur API Fidel — format `{ "error": { "code", "message" } }`.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  factory ApiException.fromResponse(int? statusCode, dynamic data) {
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return ApiException(
          code: (err['code'] as String?) ?? 'UNKNOWN',
          message: (err['message'] as String?) ?? 'Une erreur est survenue.',
          statusCode: statusCode,
        );
      }
      if (data['detail'] is String) {
        return ApiException(
          code: 'HTTP_ERROR',
          message: data['detail'] as String,
          statusCode: statusCode,
        );
      }
    }
    return ApiException(
      code: 'HTTP_ERROR',
      message: 'Erreur réseau (${statusCode ?? '?'}).',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}

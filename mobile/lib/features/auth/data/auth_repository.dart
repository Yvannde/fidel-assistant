import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _api = apiClient,
        _tokens = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
        skipAuth: true,
      );
      final data = res.data ?? {};
      final session = AuthSession.fromJson(data);
      await _tokens.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        sessionId: session.sessionId,
      );
      return session;
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _api.post<Map<String, dynamic>>(
          '/auth/logout',
          data: {'refresh_token': refresh},
        );
      }
    } on DioException {
      // On nettoie localement même si le serveur est injoignable.
    } finally {
      await _tokens.clear();
    }
  }
}

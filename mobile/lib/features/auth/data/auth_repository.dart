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
          'device_info': 'flutter',
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

  Future<void> register({
    required String email,
    required String langue,
    String? fuseauHoraire,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email.trim().toLowerCase(),
          'langue': langue,
          if (fuseauHoraire != null && fuseauHoraire.isNotEmpty)
            'fuseau_horaire': fuseauHoraire,
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> resendOtp({
    required String email,
    String type = 'inscription',
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/resend-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'type': type,
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        },
        skipAuth: true,
      );
      final token = res.data?['temp_token'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('temp_token manquant');
      }
      return token;
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> setPassword({
    required String tempToken,
    required String password,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/set-password',
        data: {
          'temp_token': tempToken,
          'password': password,
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> acceptCgu({
    required String tempToken,
    required String version,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/accept-cgu',
        data: {
          'temp_token': tempToken,
          'version': version,
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> acceptConsentementSante({
    required String tempToken,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/accept-consentement-sante',
        data: {'temp_token': tempToken},
        skipAuth: true,
      );
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

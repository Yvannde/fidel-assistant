import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    GoogleSignIn? googleSignIn,
  })  : _api = apiClient,
        _tokens = tokenStorage,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'openid', 'profile'],
              serverClientId: AppConfig.googleClientIdWeb.isEmpty
                  ? null
                  : AppConfig.googleClientIdWeb,
            );

  final ApiClient _api;
  final TokenStorage _tokens;
  final GoogleSignIn _googleSignIn;

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
      return _persistSession(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<AuthSession> loginWithGoogle({
    required String langue,
    String? fuseauHoraire,
  }) async {
    if (AppConfig.googleClientIdWeb.isEmpty) {
      throw ApiException(
        code: 'GOOGLE_NOT_CONFIGURED',
        message:
            'Google Sign-In n’est pas configuré (GOOGLE_CLIENT_ID_WEB manquant).',
      );
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw ApiException(
        code: 'GOOGLE_CANCELLED',
        message: 'Connexion Google annulée.',
      );
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException(
        code: 'GOOGLE_TOKEN_INVALID',
        message: 'Impossible d’obtenir le jeton Google (id_token).',
      );
    }

    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/google',
        data: {
          'id_token': idToken,
          'langue': langue,
          if (fuseauHoraire != null && fuseauHoraire.isNotEmpty)
            'fuseau_horaire': fuseauHoraire,
          'device_info': 'flutter',
        },
        skipAuth: true,
      );
      return _persistSession(res.data ?? {});
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
    String type = 'inscription',
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
          'type': type,
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

  Future<void> forgotPassword({required String email}) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email.trim().toLowerCase()},
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> resetPassword({
    String? email,
    String? code,
    String? tempToken,
    required String nouveauPassword,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'nouveau_password': nouveauPassword,
          if (tempToken != null && tempToken.isNotEmpty)
            'temp_token': tempToken,
          if (email != null && email.isNotEmpty)
            'email': email.trim().toLowerCase(),
          if (code != null && code.isNotEmpty) 'code': code.trim(),
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> acceptCgu({
    String? tempToken,
    required String version,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/accept-cgu',
        data: {
          'version': version,
          if (tempToken != null && tempToken.isNotEmpty)
            'temp_token': tempToken,
        },
        skipAuth: tempToken != null && tempToken.isNotEmpty,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> acceptConsentementSante({String? tempToken}) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/accept-consentement-sante',
        data: {
          if (tempToken != null && tempToken.isNotEmpty)
            'temp_token': tempToken,
        },
        skipAuth: tempToken != null && tempToken.isNotEmpty,
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
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }

  Future<AuthSession> _persistSession(Map<String, dynamic> data) async {
    final session = AuthSession.fromJson(data);
    await _tokens.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      sessionId: session.sessionId,
    );
    return session;
  }
}

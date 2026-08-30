import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Jetons JWT maison — Keychain / Keystore uniquement (jamais SharedPreferences).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _accessKey = 'fa_access_token';
  static const _refreshKey = 'fa_refresh_token';
  static const _sessionKey = 'fa_session_id';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<String?> readSessionId() => _storage.read(key: _sessionKey);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    String? sessionId,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    if (sessionId != null) {
      await _storage.write(key: _sessionKey, value: sessionId);
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _sessionKey),
    ]);
  }

  Future<bool> hasSession() async {
    final access = await readAccessToken();
    final refresh = await readRefreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_meta.dart';

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
  static const _sessionMetaKey = 'fa_session_meta';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _read(_accessKey);

  Future<String?> readRefreshToken() => _read(_refreshKey);

  Future<String?> readSessionId() => _read(_sessionKey);

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    String? sessionId,
  }) async {
    await _write(_accessKey, accessToken);
    await _write(_refreshKey, refreshToken);
    if (sessionId != null) {
      await _write(_sessionKey, sessionId);
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _write(_accessKey, accessToken);
  }

  Future<void> saveSessionMeta(SessionMeta meta) async {
    await _write(_sessionMetaKey, meta.encode());
  }

  Future<SessionMeta?> readSessionMeta() async {
    final raw = await _read(_sessionMetaKey);
    return SessionMeta.decode(raw);
  }

  Future<void> clear() async {
    await Future.wait([
      _delete(_accessKey),
      _delete(_refreshKey),
      _delete(_sessionKey),
      _delete(_sessionMetaKey),
    ]);
  }

  Future<bool> hasSession() async {
    final access = await readAccessToken();
    final refresh = await readRefreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }

  /// Sur Linux (Cloud Desktop), le keyring peut être verrouillé / absent :
  /// on ne fait pas planter l’app — session absente tant que le store est indispo.
  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      debugPrint('TokenStorage.read($key) failed: $e');
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      debugPrint('TokenStorage.write($key) failed: $e');
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      debugPrint('TokenStorage.delete($key) failed: $e');
    }
  }
}

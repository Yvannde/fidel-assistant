import 'package:shared_preferences/shared_preferences.dart';

/// Cache du 1er contact d'urgence pour SOS offline.
class EmergencyContactCache {
  EmergencyContactCache(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPhone = 'sos_emergency_phone_v1';
  static const _keyName = 'sos_emergency_name_v1';

  String? get phone {
    final v = _prefs.getString(_keyPhone)?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String? get name => _prefs.getString(_keyName);

  Future<void> saveFirst({required String phone, String? name}) async {
    final p = phone.trim();
    if (p.isEmpty) {
      await clear();
      return;
    }
    await _prefs.setString(_keyPhone, p);
    if (name != null && name.trim().isNotEmpty) {
      await _prefs.setString(_keyName, name.trim());
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_keyPhone);
    await _prefs.remove(_keyName);
  }
}

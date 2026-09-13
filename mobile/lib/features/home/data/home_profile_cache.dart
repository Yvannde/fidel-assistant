import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/dashboard_models.dart';

/// Cache local du profil Accueil (header + flags patient/aidant).
abstract final class HomeProfileCache {
  static const key = 'home_profile_cache_v1';

  static Future<void> save(SharedPreferences prefs, HomeProfile profile) async {
    await prefs.setString(
      key,
      jsonEncode({
        'nom_complet': profile.nomComplet,
        'has_patient_profile': profile.hasPatientProfile,
        'is_aidant': profile.isAidant,
        'email': profile.email,
        'phone': profile.phone,
        'langue': profile.langue,
        'fuseau_horaire': profile.fuseauHoraire,
        'has_password': profile.hasPassword,
      }),
    );
  }

  static HomeProfile? read(SharedPreferences prefs) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      return HomeProfile.fromMeJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(key);
  }
}

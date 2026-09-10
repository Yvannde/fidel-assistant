import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales de l’alarme médicament (pas sync serveur V1).
class AlarmPrefs {
  AlarmPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const defaultAssetAudio = 'assets/sounds/fidel_alarm.wav';
  static const customVoiceRelativePath = 'sounds/voix_rappel';

  static const _kPreavis = 'fa_alarm_preavis_minutes';
  static const _kSnooze = 'fa_alarm_snooze_minutes';
  static const _kVibrate = 'fa_alarm_vibrate';
  static const _kUseCustomVoice = 'fa_alarm_use_custom_voice';
  static const _kCustomVoiceExt = 'fa_alarm_custom_voice_ext';

  static const allowedPreavis = [2, 5, 10];
  static const allowedSnooze = [15, 30, 60];

  int get preavisMinutes {
    final v = _prefs.getInt(_kPreavis) ?? 5;
    return allowedPreavis.contains(v) ? v : 5;
  }

  Future<void> setPreavisMinutes(int minutes) async {
    final v = allowedPreavis.contains(minutes) ? minutes : 5;
    await _prefs.setInt(_kPreavis, v);
  }

  int get snoozeMinutes {
    final v = _prefs.getInt(_kSnooze) ?? 15;
    return allowedSnooze.contains(v) ? v : 15;
  }

  Future<void> setSnoozeMinutes(int minutes) async {
    final v = allowedSnooze.contains(minutes) ? minutes : 15;
    await _prefs.setInt(_kSnooze, v);
  }

  bool get vibrate => _prefs.getBool(_kVibrate) ?? true;

  Future<void> setVibrate(bool value) async {
    await _prefs.setBool(_kVibrate, value);
  }

  bool get useCustomVoice => _prefs.getBool(_kUseCustomVoice) ?? false;

  Future<void> setUseCustomVoice(bool value) async {
    await _prefs.setBool(_kUseCustomVoice, value);
  }

  String? get customVoiceExt => _prefs.getString(_kCustomVoiceExt);

  /// Chemin relatif (documents) pour le package `alarm`, ou null.
  String? get customVoiceRelative {
    final ext = customVoiceExt;
    if (ext == null || ext.isEmpty) return null;
    return '$customVoiceRelativePath.$ext';
  }

  /// Audio à passer à [AlarmSettings.assetAudioPath].
  Future<String> resolveAudioPath() async {
    if (!useCustomVoice) return defaultAssetAudio;
    final relative = customVoiceRelative;
    if (relative == null) return defaultAssetAudio;
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, relative));
    if (await file.exists()) return relative;
    return defaultAssetAudio;
  }

  /// Écrit le fichier voix sous `Documents/sounds/voix_rappel.<ext>` (sans forcer le toggle).
  Future<String> storeCustomVoiceBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    final ext = _extOf(filename);
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'sounds'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = File(p.join(dir.path, 'voix_rappel.$ext'));
    await dest.writeAsBytes(bytes, flush: true);
    await _prefs.setString(_kCustomVoiceExt, ext);
    return '$customVoiceRelativePath.$ext';
  }

  /// Écrit le fichier voix sous `Documents/sounds/voix_rappel.<ext>`.
  Future<String> cacheCustomVoiceBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    final path = await storeCustomVoiceBytes(bytes: bytes, filename: filename);
    await setUseCustomVoice(true);
    return path;
  }

  Future<String> cacheCustomVoiceFile(String sourcePath) async {
    final ext = _extOf(sourcePath);
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'sounds'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = File(p.join(dir.path, 'voix_rappel.$ext'));
    await File(sourcePath).copy(dest.path);
    await _prefs.setString(_kCustomVoiceExt, ext);
    await setUseCustomVoice(true);
    return '$customVoiceRelativePath.$ext';
  }

  Future<void> clearCustomVoiceCache() async {
    final relative = customVoiceRelative;
    if (relative != null) {
      final docs = await getApplicationDocumentsDirectory();
      final file = File(p.join(docs.path, relative));
      if (await file.exists()) await file.delete();
    }
    await _prefs.remove(_kCustomVoiceExt);
    await setUseCustomVoice(false);
  }

  static String _extOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'm4a';
    return name.substring(dot + 1).toLowerCase();
  }
}

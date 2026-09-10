import 'dart:io' show HttpDate;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/locale/locale_controller.dart';

/// Horloge corrigée via le header HTTP `Date` (Phase 2).
class ServerClock {
  ServerClock(this._prefs, {DateTime Function()? now})
      : _deviceNow = now ?? (() => DateTime.now().toUtc());

  static const offsetKey = 'server_clock_offset_ms_v1';

  final SharedPreferences _prefs;
  final DateTime Function() _deviceNow;
  Duration? _offset;

  Duration? get offset => _offset;

  void load() {
    final ms = _prefs.getInt(offsetKey);
    if (ms != null) {
      _offset = Duration(milliseconds: ms);
    }
  }

  /// Met à jour l’offset à partir d’un header `Date` RFC 1123.
  void observeHttpDate(String? dateHeader) {
    if (dateHeader == null || dateHeader.isEmpty) return;
    try {
      final server = HttpDate.parse(dateHeader).toUtc();
      final device = _deviceNow();
      _offset = server.difference(device);
      _prefs.setInt(offsetKey, _offset!.inMilliseconds);
    } catch (_) {
      // ignore invalid Date
    }
  }

  /// Instant UTC corrigé (device si offset inconnu).
  DateTime now() => _deviceNow().add(_offset ?? Duration.zero);
}

final serverClockProvider = Provider<ServerClock>((ref) {
  final clock = ServerClock(ref.watch(sharedPreferencesProvider));
  clock.load();
  return clock;
});

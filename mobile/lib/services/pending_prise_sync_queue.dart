import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/home/data/home_repository.dart';

/// File minimale confirm / report hors-ligne → API.
class PendingPriseSyncQueue {
  PendingPriseSyncQueue(this._prefs);

  static const _key = 'pending_prise_sync_v1';

  final SharedPreferences _prefs;

  List<Map<String, dynamic>> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<Map<String, dynamic>> items) async {
    await _prefs.setString(_key, jsonEncode(items));
  }

  Future<void> enqueueConfirm({
    required String priseId,
    DateTime? confirmeeAt,
  }) async {
    final items = _read()
      ..removeWhere(
        (e) => e['priseId'] == priseId && e['type'] == 'confirm',
      );
    items.add({
      'type': 'confirm',
      'priseId': priseId,
      'confirmeeAt': (confirmeeAt ?? DateTime.now().toUtc()).toIso8601String(),
    });
    await _write(items);
  }

  Future<void> enqueueReport({
    required String priseId,
    required DateTime nouvelleHeure,
  }) async {
    final items = _read()
      ..removeWhere(
        (e) => e['priseId'] == priseId && e['type'] == 'report',
      );
    items.add({
      'type': 'report',
      'priseId': priseId,
      'nouvelleHeure': nouvelleHeure.toUtc().toIso8601String(),
    });
    await _write(items);
  }

  /// Envoie ce qui peut l’être ; laisse le reste en file.
  Future<void> flush(HomeRepository repo) async {
    final items = _read();
    if (items.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    final confirms = <Map<String, dynamic>>[];

    for (final item in items) {
      final type = item['type'] as String?;
      if (type == 'confirm') {
        confirms.add(item);
      } else if (type == 'report') {
        final id = item['priseId'] as String?;
        final raw = item['nouvelleHeure'] as String?;
        if (id == null || raw == null) continue;
        try {
          await repo.reportPrise(id, DateTime.parse(raw).toUtc());
        } catch (_) {
          remaining.add(item);
        }
      } else {
        remaining.add(item);
      }
    }

    if (confirms.isNotEmpty) {
      try {
        await repo.syncPrisesOffline([
          for (final c in confirms)
            {
              'id': c['priseId'],
              'statut': 'confirmee',
              'confirmee_at': c['confirmeeAt'],
            },
        ]);
      } catch (_) {
        // Fallback unitaire si le batch échoue.
        for (final c in confirms) {
          final id = c['priseId'] as String?;
          if (id == null) continue;
          try {
            await repo.confirmPrise(id);
          } catch (_) {
            remaining.add(c);
          }
        }
      }
    }

    await _write(remaining);
  }
}

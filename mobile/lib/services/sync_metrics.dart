import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Observabilité sync légère (Phase 6) — debugPrint + dernière passe en prefs.
class SyncMetrics {
  SyncMetrics({SharedPreferences? prefs}) : _prefs = prefs;

  static const lastPassKey = 'sync_last_pass_v1';
  static const _uuid = Uuid();

  final SharedPreferences? _prefs;

  /// Enregistre une passe exécutée (ou partiellement exécutée).
  Future<void> recordPass({
    required DateTime startedAt,
    required int durationMs,
    int pushed = 0,
    int applied = 0,
    int duplicate = 0,
    int rejected = 0,
    int pulled = 0,
    int outboxRemaining = 0,
    String? skippedReason,
    String? error,
  }) async {
    final passId = _uuid.v4().substring(0, 8);
    final map = <String, Object?>{
      'pass_id': passId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'duration_ms': durationMs,
      'pushed': pushed,
      'applied': applied,
      'duplicate': duplicate,
      'rejected': rejected,
      'pulled': pulled,
      'outbox_remaining': outboxRemaining,
      if (skippedReason != null) 'skipped_reason': skippedReason,
      if (error != null) 'error': error,
    };
    debugPrint('SyncMetrics $map');
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(lastPassKey, jsonEncode(map));
    }
  }

  /// Flush scheduled ignoré (cooldown / offline / circuit).
  Future<void> recordSkip({required String skippedReason}) {
    return recordPass(
      startedAt: DateTime.now().toUtc(),
      durationMs: 0,
      skippedReason: skippedReason,
    );
  }

  static Map<String, dynamic>? readLastPass(SharedPreferences prefs) {
    final raw = prefs.getString(lastPassKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }
}

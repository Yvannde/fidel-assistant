import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Entrée outbox conforme au contrat `offline-sync`.
class SyncOutboxEntry {
  SyncOutboxEntry({
    required this.mutationId,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.clientTs,
    this.attempts = 0,
    DateTime? nextAttemptAt,
    this.state = SyncOutboxState.pending,
  }) : nextAttemptAt = nextAttemptAt ?? clientTs;

  final String mutationId;
  final String entity;
  final String entityId;
  final String op;
  final Map<String, dynamic> payload;
  final DateTime clientTs;
  final int attempts;
  final DateTime nextAttemptAt;
  final SyncOutboxState state;

  SyncOutboxEntry copyWith({
    int? attempts,
    DateTime? nextAttemptAt,
    SyncOutboxState? state,
  }) {
    return SyncOutboxEntry(
      mutationId: mutationId,
      entity: entity,
      entityId: entityId,
      op: op,
      payload: payload,
      clientTs: clientTs,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
        'mutation_id': mutationId,
        'entity': entity,
        'entity_id': entityId,
        'op': op,
        'payload': payload,
        'client_ts': clientTs.toUtc().toIso8601String(),
        'attempts': attempts,
        'next_attempt_at': nextAttemptAt.toUtc().toIso8601String(),
        'state': state.wireName,
      };

  factory SyncOutboxEntry.fromJson(Map<String, dynamic> json) {
    return SyncOutboxEntry(
      mutationId: '${json['mutation_id']}',
      entity: '${json['entity']}',
      entityId: '${json['entity_id']}',
      op: '${json['op']}',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      clientTs: DateTime.parse('${json['client_ts']}').toUtc(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      nextAttemptAt: DateTime.parse(
        '${json['next_attempt_at'] ?? json['client_ts']}',
      ).toUtc(),
      state: SyncOutboxState.fromWire(json['state']),
    );
  }
}

enum SyncOutboxState {
  pending,
  inflight,
  failedPermanent;

  String get wireName => switch (this) {
        SyncOutboxState.pending => 'pending',
        SyncOutboxState.inflight => 'inflight',
        SyncOutboxState.failedPermanent => 'failed_permanent',
      };

  static SyncOutboxState fromWire(Object? raw) {
    final s = '$raw';
    return SyncOutboxState.values.firstWhere(
      (e) => e.wireName == s || e.name == s,
      orElse: () => SyncOutboxState.pending,
    );
  }
}

/// Outbox SharedPreferences (Phase 1 — Drift en Phase 3).
class SyncOutbox {
  SyncOutbox(this._prefs);

  static const key = 'sync_outbox_v1';
  static const legacyKey = 'pending_prise_sync_v1';
  static const _uuid = Uuid();

  final SharedPreferences _prefs;
  bool _migrated = false;

  Future<void> ensureMigrated() async {
    if (_migrated) return;
    _migrated = true;
    final legacy = _prefs.getString(legacyKey);
    if (legacy == null || legacy.isEmpty) return;
    if ((_prefs.getString(key) ?? '').isNotEmpty) {
      await _prefs.remove(legacyKey);
      return;
    }
    try {
      final decoded = jsonDecode(legacy);
      if (decoded is! List) {
        await _prefs.remove(legacyKey);
        return;
      }
      final now = DateTime.now().toUtc();
      final entries = <SyncOutboxEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final type = map['type'] as String?;
        final priseId = map['priseId'] as String?;
        if (priseId == null || priseId.isEmpty) continue;
        if (type == 'confirm') {
          entries.add(
            SyncOutboxEntry(
              mutationId: _uuid.v4(),
              entity: 'prise',
              entityId: priseId,
              op: 'confirm',
              payload: {
                'confirmee_at': map['confirmeeAt'] ?? now.toIso8601String(),
                'canal': 'app',
              },
              clientTs: now,
            ),
          );
        } else if (type == 'report') {
          final raw = map['nouvelleHeure'] as String?;
          if (raw == null) continue;
          entries.add(
            SyncOutboxEntry(
              mutationId: _uuid.v4(),
              entity: 'prise',
              entityId: priseId,
              op: 'report',
              payload: {'nouvelle_heure': raw},
              clientTs: now,
            ),
          );
        }
      }
      await _writeAll(entries);
    } catch (_) {
      // ignore corrupt legacy
    }
    await _prefs.remove(legacyKey);
  }

  List<SyncOutboxEntry> _readAll() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => SyncOutboxEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAll(List<SyncOutboxEntry> entries) async {
    await _prefs.setString(
      key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<SyncOutboxEntry> enqueue({
    required String entity,
    required String entityId,
    required String op,
    required Map<String, dynamic> payload,
    DateTime? clientTs,
    String? mutationId,
  }) async {
    await ensureMigrated();
    final entry = SyncOutboxEntry(
      mutationId: mutationId ?? _uuid.v4(),
      entity: entity,
      entityId: entityId,
      op: op,
      payload: payload,
      clientTs: (clientTs ?? DateTime.now()).toUtc(),
    );
    final all = _readAll()..add(entry);
    await _writeAll(all);
    return entry;
  }

  Future<List<SyncOutboxEntry>> listReady({DateTime? now}) async {
    await ensureMigrated();
    final t = (now ?? DateTime.now()).toUtc();
    return _readAll()
        .where(
          (e) =>
              e.state != SyncOutboxState.failedPermanent &&
              !e.nextAttemptAt.isAfter(t),
        )
        .toList(growable: false);
  }

  Future<void> markInflight(String mutationId) async {
    await _update(mutationId, (e) => e.copyWith(state: SyncOutboxState.inflight));
  }

  Future<void> markDone(String mutationId) async {
    await ensureMigrated();
    final all = _readAll()..removeWhere((e) => e.mutationId == mutationId);
    await _writeAll(all);
  }

  Future<void> markRetry(String mutationId, {required int attempts}) async {
    final delaySec = min(300, pow(2, attempts).toInt());
    final jitter = Random().nextDouble() * 0.6 - 0.3; // ±30%
    final seconds = max(1, (delaySec * (1 + jitter)).round());
    final next = DateTime.now().toUtc().add(Duration(seconds: seconds));
    await _update(
      mutationId,
      (e) => e.copyWith(
        attempts: attempts,
        nextAttemptAt: next,
        state: SyncOutboxState.pending,
      ),
    );
  }

  Future<void> markPermanent(String mutationId) async {
    await _update(
      mutationId,
      (e) => e.copyWith(state: SyncOutboxState.failedPermanent),
    );
  }

  Future<void> _update(
    String mutationId,
    SyncOutboxEntry Function(SyncOutboxEntry) fn,
  ) async {
    await ensureMigrated();
    final all = _readAll();
    final idx = all.indexWhere((e) => e.mutationId == mutationId);
    if (idx < 0) return;
    all[idx] = fn(all[idx]);
    await _writeAll(all);
  }
}

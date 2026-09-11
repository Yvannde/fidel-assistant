import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/app_database.dart';
import '../core/database/providers.dart';
import '../core/locale/locale_controller.dart';
import '../core/network/api_exception.dart';
import '../core/network/providers.dart';
import '../features/home/data/home_repository.dart';
import 'network_status.dart';
import 'server_clock.dart';
import 'sync_outbox.dart';

/// Incrémenté après un pull réussi — l’UI Accueil écoute pour recharger la projection.
final syncPullTickProvider = StateProvider<int>((ref) => 0);

/// Port minimal pour confirm/report (testable sans mocker tout le repo).
abstract interface class SyncPriseGateway {
  Future<void> confirmPrise(String priseId, {String? clientMutationId});
  Future<void> reportPrise(
    String priseId,
    DateTime nouvelleHeure, {
    String? clientMutationId,
  });
}

/// Push/pull batch (Phase 4). Les fakes de test n’implémentent pas cette interface.
abstract interface class SyncBatchGateway {
  Future<SyncPushResponse> syncPush(List<Map<String, dynamic>> mutations);
  Future<SyncPullResponse> syncPull({String? since});
}

class HomeSyncPriseGateway implements SyncPriseGateway, SyncBatchGateway {
  HomeSyncPriseGateway(this._repo);

  final HomeRepository _repo;

  @override
  Future<void> confirmPrise(String priseId, {String? clientMutationId}) {
    return _repo.confirmPrise(priseId, clientMutationId: clientMutationId);
  }

  @override
  Future<void> reportPrise(
    String priseId,
    DateTime nouvelleHeure, {
    String? clientMutationId,
  }) {
    return _repo.reportPrise(
      priseId,
      nouvelleHeure,
      clientMutationId: clientMutationId,
    );
  }

  @override
  Future<SyncPushResponse> syncPush(List<Map<String, dynamic>> mutations) {
    return _repo.syncPush(mutations);
  }

  @override
  Future<SyncPullResponse> syncPull({String? since}) {
    return _repo.syncPull(since: since);
  }
}

/// Moteur de sync outbox — single-flight + FIFO + push/pull (Phase 4).
class SyncEngine {
  SyncEngine({
    required SyncOutbox outbox,
    required SyncPriseGateway Function() gatewayFactory,
    ServerClock? clock,
    NetworkStatus? network,
    AppDatabase? db,
    SharedPreferences? prefs,
    Future<void> Function()? onAfterPull,
  })  : _outbox = outbox,
        _gatewayFactory = gatewayFactory,
        _clock = clock,
        _network = network,
        _db = db,
        _prefs = prefs,
        _onAfterPull = onAfterPull;

  static const pullCursorKey = 'sync_pull_cursor_v1';

  final SyncOutbox _outbox;
  final SyncPriseGateway Function() _gatewayFactory;
  final ServerClock? _clock;
  final NetworkStatus? _network;
  final AppDatabase? _db;
  final SharedPreferences? _prefs;
  final Future<void> Function()? _onAfterPull;

  Future<void>? _inflight;

  DateTime _now() => _clock?.now() ?? DateTime.now().toUtc();

  /// Single-flight : les appels concurrents partagent la même passe.
  ///
  /// [force] : ignore `canSync` (post-mutation / refresh manuel).
  Future<void> flush({bool force = false}) {
    if (!force && _network != null && !_network.canSync) {
      return Future<void>.value();
    }
    if (_inflight != null) return _inflight!;
    final c = Completer<void>();
    _inflight = c.future;
    () async {
      try {
        await _runPass();
        c.complete();
      } catch (e, st) {
        debugPrint('SyncEngine.flush: $e\n$st');
        c.complete(); // ne propage pas — best-effort
      } finally {
        _inflight = null;
      }
    }();
    return c.future;
  }

  Future<void> enqueueConfirm({
    required String priseId,
    DateTime? confirmeeAt,
  }) async {
    final ts = confirmeeAt?.toUtc() ?? _now();
    await _outbox.enqueue(
      entity: 'prise',
      entityId: priseId,
      op: 'confirm',
      clientTs: ts,
      payload: {
        'confirmee_at': ts.toIso8601String(),
        'canal': 'app',
      },
    );
  }

  Future<void> enqueueReport({
    required String priseId,
    required DateTime nouvelleHeure,
  }) async {
    await _outbox.enqueue(
      entity: 'prise',
      entityId: priseId,
      op: 'report',
      clientTs: _now(),
      payload: {
        'nouvelle_heure': nouvelleHeure.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _runPass() async {
    final ready = await _outbox.listReady();
    final gateway = _gatewayFactory();
    final batch = gateway is SyncBatchGateway ? gateway as SyncBatchGateway : null;

    var anySuccess = false;
    var anyFail = false;
    var any5xx = false;

    if (ready.isNotEmpty) {
      if (batch != null) {
        try {
          final pushOutcome = await _runBatchPush(batch, ready);
          anySuccess = pushOutcome.success;
          anyFail = pushOutcome.fail;
          any5xx = pushOutcome.is5xx;
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            final unitary = await _runUnitaryPush(gateway, ready);
            anySuccess = unitary.success;
            anyFail = unitary.fail;
            any5xx = unitary.is5xx;
          } else {
            anyFail = true;
            any5xx = _is5xx(e);
            for (final entry in ready) {
              if (_isRetryable(e)) {
                await _outbox.markRetry(
                  entry.mutationId,
                  attempts: entry.attempts + 1,
                );
              } else {
                await _outbox.markPermanent(entry.mutationId);
              }
            }
          }
        } catch (e) {
          anyFail = true;
          any5xx = _is5xx(e);
          for (final entry in ready) {
            if (_isRetryable(e)) {
              await _outbox.markRetry(
                entry.mutationId,
                attempts: entry.attempts + 1,
              );
            } else {
              await _outbox.markPermanent(entry.mutationId);
            }
          }
        }
      } else {
        final unitary = await _runUnitaryPush(gateway, ready);
        anySuccess = unitary.success;
        anyFail = unitary.fail;
        any5xx = unitary.is5xx;
      }
    }

    if (batch != null) {
      try {
        await _runPull(batch);
      } catch (e) {
        debugPrint('SyncEngine.pull: $e');
        anyFail = true;
        if (_is5xx(e)) any5xx = true;
      }
    }

    final net = _network;
    if (net == null) return;
    if (anySuccess && !anyFail) {
      net.reportSyncSuccess();
    } else if (anyFail) {
      net.reportSyncFailure(is5xx: any5xx);
    }
  }

  Future<({bool success, bool fail, bool is5xx})> _runBatchPush(
    SyncBatchGateway batch,
    List<SyncOutboxEntry> ready,
  ) async {
    for (final entry in ready) {
      await _outbox.markInflight(entry.mutationId);
    }

    final mutations = ready
        .map(
          (e) => <String, dynamic>{
            'mutation_id': e.mutationId,
            'entity': e.entity,
            'entity_id': e.entityId,
            'op': e.op,
            'payload': e.payload,
            'client_ts': e.clientTs.toUtc().toIso8601String(),
          },
        )
        .toList();

    final response = await batch.syncPush(mutations);
    final byId = {
      for (final r in response.results) r.mutationId: r,
    };

    var anySuccess = false;
    var anyFail = false;
    for (final entry in ready) {
      final result = byId[entry.mutationId];
      if (result == null) {
        anyFail = true;
        await _outbox.markRetry(
          entry.mutationId,
          attempts: entry.attempts + 1,
        );
        continue;
      }
      if (result.status == 'applied' || result.status == 'duplicate') {
        await _outbox.markDone(entry.mutationId);
        anySuccess = true;
      } else if (result.status == 'rejected') {
        await _outbox.markPermanent(entry.mutationId);
      } else {
        anyFail = true;
        await _outbox.markRetry(
          entry.mutationId,
          attempts: entry.attempts + 1,
        );
      }
    }
    return (success: anySuccess, fail: anyFail, is5xx: false);
  }

  Future<({bool success, bool fail, bool is5xx})> _runUnitaryPush(
    SyncPriseGateway gateway,
    List<SyncOutboxEntry> ready,
  ) async {
    var anySuccess = false;
    var anyFail = false;
    var any5xx = false;

    for (final entry in ready) {
      await _outbox.markInflight(entry.mutationId);
      try {
        if (entry.op == 'confirm') {
          await gateway.confirmPrise(
            entry.entityId,
            clientMutationId: entry.mutationId,
          );
        } else if (entry.op == 'report') {
          final raw = entry.payload['nouvelle_heure'] as String?;
          if (raw == null) {
            await _outbox.markPermanent(entry.mutationId);
            continue;
          }
          await gateway.reportPrise(
            entry.entityId,
            DateTime.parse(raw).toUtc(),
            clientMutationId: entry.mutationId,
          );
        } else {
          await _outbox.markPermanent(entry.mutationId);
          continue;
        }
        await _outbox.markDone(entry.mutationId);
        anySuccess = true;
      } catch (e) {
        anyFail = true;
        if (_is5xx(e)) any5xx = true;
        if (_isRetryable(e)) {
          await _outbox.markRetry(
            entry.mutationId,
            attempts: entry.attempts + 1,
          );
        } else {
          await _outbox.markPermanent(entry.mutationId);
        }
      }
    }
    return (success: anySuccess, fail: anyFail, is5xx: any5xx);
  }

  Future<void> _runPull(SyncBatchGateway batch) async {
    final db = _db;
    if (db == null) return;

    final since = _prefs?.getString(pullCursorKey);
    final pull = await batch.syncPull(since: since);
    await db.mergePullEntities(pull.entities);
    final next = pull.nextCursor;
    if (next != null && next.isNotEmpty) {
      await _prefs?.setString(pullCursorKey, next);
    }
    final hook = _onAfterPull;
    if (hook != null) {
      try {
        await hook();
      } catch (e) {
        debugPrint('SyncEngine.onAfterPull: $e');
      }
    }
  }

  bool _is5xx(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      return code != null && code >= 500;
    }
    return false;
  }

  bool _isRetryable(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code != null && code >= 400 && code < 500) return false;
      return true; // timeout, connection, 5xx
    }
    if (e is ApiException) {
      return false;
    }
    return true;
  }
}

final syncOutboxProvider = Provider<SyncOutbox>((ref) {
  return SyncOutbox(
    ref.watch(appDatabaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final outbox = ref.watch(syncOutboxProvider);
  return SyncEngine(
    outbox: outbox,
    clock: ref.watch(serverClockProvider),
    network: ref.watch(networkStatusProvider),
    db: ref.watch(appDatabaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    gatewayFactory: () => HomeSyncPriseGateway(
      HomeRepository(apiClient: ref.read(apiClientProvider)),
    ),
    onAfterPull: () async {
      ref.read(syncPullTickProvider.notifier).state++;
    },
  );
});

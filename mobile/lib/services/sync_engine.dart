import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale/locale_controller.dart';
import '../core/network/api_exception.dart';
import '../core/network/providers.dart';
import '../features/home/data/home_repository.dart';
import 'sync_outbox.dart';

/// Port minimal pour confirm/report (testable sans mocker tout le repo).
abstract interface class SyncPriseGateway {
  Future<void> confirmPrise(String priseId, {String? clientMutationId});
  Future<void> reportPrise(
    String priseId,
    DateTime nouvelleHeure, {
    String? clientMutationId,
  });
}

class HomeSyncPriseGateway implements SyncPriseGateway {
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
}

/// Moteur de sync outbox — single-flight + FIFO (Phase 1).
class SyncEngine {
  SyncEngine({
    required SyncOutbox outbox,
    required SyncPriseGateway Function() gatewayFactory,
  })  : _outbox = outbox,
        _gatewayFactory = gatewayFactory;

  final SyncOutbox _outbox;
  final SyncPriseGateway Function() _gatewayFactory;

  Future<void>? _inflight;

  /// Single-flight : les appels concurrents partagent la même passe.
  Future<void> flush() {
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
    await _outbox.enqueue(
      entity: 'prise',
      entityId: priseId,
      op: 'confirm',
      payload: {
        'confirmee_at':
            (confirmeeAt ?? DateTime.now()).toUtc().toIso8601String(),
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
      payload: {
        'nouvelle_heure': nouvelleHeure.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _runPass() async {
    final ready = await _outbox.listReady();
    if (ready.isEmpty) return;
    final gateway = _gatewayFactory();

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
      } catch (e) {
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
  }

  bool _isRetryable(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code != null && code >= 400 && code < 500) return false;
      return true; // timeout, connection, 5xx
    }
    if (e is ApiException) {
      // 4xx métier → permanent
      return false;
    }
    return true;
  }
}

final syncOutboxProvider = Provider<SyncOutbox>((ref) {
  return SyncOutbox(ref.watch(sharedPreferencesProvider));
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final outbox = ref.watch(syncOutboxProvider);
  return SyncEngine(
    outbox: outbox,
    gatewayFactory: () => HomeSyncPriseGateway(
      HomeRepository(apiClient: ref.read(apiClientProvider)),
    ),
  );
});

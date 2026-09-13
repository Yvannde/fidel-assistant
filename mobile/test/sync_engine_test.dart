import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/core/database/app_database.dart';
import 'package:fidel_assistant/features/home/data/home_repository.dart';
import 'package:fidel_assistant/services/network_status.dart';
import 'package:fidel_assistant/services/server_clock.dart';
import 'package:fidel_assistant/services/sync_engine.dart';
import 'package:fidel_assistant/services/sync_outbox.dart';

class _FakeGateway implements SyncPriseGateway {
  _FakeGateway(
    this.log, {
    this.gate,
    this.throwOnConfirm = false,
  });

  final List<String> log;
  final Completer<void>? gate;
  final bool throwOnConfirm;

  @override
  Future<void> confirmPrise(String priseId, {String? clientMutationId}) async {
    if (gate != null) await gate!.future;
    if (throwOnConfirm) {
      throw DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 503,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    log.add('confirm:$priseId:${clientMutationId ?? ''}');
  }

  @override
  Future<void> reportPrise(
    String priseId,
    DateTime nouvelleHeure, {
    String? clientMutationId,
  }) async {
    if (gate != null) await gate!.future;
    log.add('report:$priseId:${clientMutationId ?? ''}');
  }

  @override
  Future<void> createConstante({
    required String type,
    required Object valeur,
    required String unite,
    required DateTime mesureAt,
    String source = 'manuel',
    String? clientMutationId,
  }) async {
    log.add('constante:$type:${clientMutationId ?? ''}');
  }

  @override
  Future<void> createCheckIn(String statut, {String? clientMutationId}) async {
    log.add('checkin:$statut:${clientMutationId ?? ''}');
  }
}

class _CutoffBatchFake implements SyncPriseGateway, SyncBatchGateway {
  _CutoffBatchFake();

  int pushCalls = 0;
  String? lastMutationId;

  @override
  Future<void> confirmPrise(String priseId, {String? clientMutationId}) async {}

  @override
  Future<void> reportPrise(
    String priseId,
    DateTime nouvelleHeure, {
    String? clientMutationId,
  }) async {}

  @override
  Future<void> createConstante({
    required String type,
    required Object valeur,
    required String unite,
    required DateTime mesureAt,
    String source = 'manuel',
    String? clientMutationId,
  }) async {}

  @override
  Future<void> createCheckIn(String statut, {String? clientMutationId}) async {}

  @override
  Future<SyncPushResponse> syncPush(List<Map<String, dynamic>> mutations) async {
    pushCalls++;
    lastMutationId = mutations.first['mutation_id'] as String?;
    if (pushCalls == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/sync/push'),
        type: DioExceptionType.connectionTimeout,
      );
    }
    return SyncPushResponse(
      results: [
        for (final m in mutations)
          SyncPushResultItem(
            mutationId: '${m['mutation_id']}',
            status: 'duplicate',
          ),
      ],
    );
  }

  @override
  Future<SyncPullResponse> syncPull({String? since}) async {
    return const SyncPullResponse(entities: []);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<SyncOutbox> outbox() async {
    final prefs = await SharedPreferences.getInstance();
    return SyncOutbox(db, prefs: prefs);
  }

  test('single-flight: parallel flush shares one pass', () async {
    final box = await outbox();
    final log = <String>[];
    final gate = Completer<void>();
    var factoryCalls = 0;

    final engine = SyncEngine(
      outbox: box,
      gatewayFactory: () {
        factoryCalls++;
        return _FakeGateway(log, gate: gate);
      },
    );

    await engine.enqueueConfirm(priseId: 'p1');
    final f1 = engine.flush();
    final f2 = engine.flush();
    expect(identical(f1, f2), isTrue);

    await Future<void>.delayed(Duration.zero);
    expect(factoryCalls, 1);
    gate.complete();
    await Future.wait([f1, f2]);
    expect(log.where((e) => e.startsWith('confirm:')).length, 1);
  });

  test('FIFO: report then confirm on same priseId', () async {
    final box = await outbox();
    final log = <String>[];

    final engine = SyncEngine(
      outbox: box,
      gatewayFactory: () => _FakeGateway(log),
    );

    final when = DateTime.utc(2026, 9, 10, 11);
    await engine.enqueueReport(priseId: 'same', nouvelleHeure: when);
    await engine.enqueueConfirm(priseId: 'same');
    await engine.flush();

    expect(log.map((e) => e.split(':').first).toList(), ['report', 'confirm']);
    expect(log.every((e) => e.contains('same')), isTrue);
  });

  test('gated flush skips when offline; force still runs', () async {
    final box = await outbox();
    final log = <String>[];
    final net = NetworkStatus(
      probe: () async => false,
      stabilityWindow: Duration.zero,
    );

    final engine = SyncEngine(
      outbox: box,
      network: net,
      gatewayFactory: () => _FakeGateway(log),
    );

    await engine.enqueueConfirm(priseId: 'p1');
    await engine.flush();
    expect(log, isEmpty);

    await engine.flush(force: true);
    expect(log.single, startsWith('confirm:p1:'));
  });

  test('5xx during flush reports to network breaker', () async {
    final box = await outbox();
    var t = DateTime.utc(2026, 9, 10, 12);
    final net = NetworkStatus(
      probe: () async => true,
      now: () => t,
      stabilityWindow: Duration.zero,
    );
    await net.runProbe();
    await net.runProbe();
    expect(net.canSync, isTrue);

    final engine = SyncEngine(
      outbox: box,
      network: net,
      gatewayFactory: () => _FakeGateway([], throwOnConfirm: true),
    );

    for (var i = 0; i < 5; i++) {
      await box.enqueue(
        entity: 'prise',
        entityId: 'p$i',
        op: 'confirm',
        payload: {},
      );
      await engine.flush(force: true);
    }
    expect(net.circuitOpen, isTrue);
  });

  test('QA#2 cut-off mid-push: retry same mutation_id then duplicate ack', () async {
    final prefs = await SharedPreferences.getInstance();
    final box = SyncOutbox(db, prefs: prefs);
    final fake = _CutoffBatchFake();
    final engine = SyncEngine(
      outbox: box,
      db: db,
      prefs: prefs,
      gatewayFactory: () => fake,
    );

    final entry = await box.enqueue(
      entity: 'prise',
      entityId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      op: 'confirm',
      payload: {'canal': 'app'},
      mutationId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    );

    await engine.flush(force: true);
    expect(fake.pushCalls, 1);
    final pending = await db.listAllOutbox();
    expect(pending, hasLength(1));
    expect(pending.single.mutationId, entry.mutationId);
    // Backoff after timeout — make entry ready for immediate retry.
    await db.updateOutboxEntry(
      pending.single.copyWith(
        nextAttemptAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
        state: SyncOutboxState.pending,
      ),
    );

    await engine.flush(force: true);
    expect(fake.pushCalls, 2);
    expect(fake.lastMutationId, entry.mutationId);
    expect(await box.listReady(), isEmpty);
  });

  test('QA#4 ServerClock skew: client_ts uses corrected now', () async {
    final prefs = await SharedPreferences.getInstance();
    // Device "now" is 09:00; server is 3h ahead → offset +3h.
    final deviceNow = DateTime.utc(2026, 9, 11, 9);
    final clock = ServerClock(prefs, now: () => deviceNow);
    clock.observeHttpDate('Fri, 11 Sep 2026 12:00:00 GMT');

    final box = SyncOutbox(db, prefs: prefs);
    final engine = SyncEngine(
      outbox: box,
      clock: clock,
      gatewayFactory: () => _FakeGateway([]),
    );

    await engine.enqueueConfirm(priseId: 'p-clock');
    final ready = await box.listReady();
    expect(ready, hasLength(1));
    final ts = ready.single.clientTs.toUtc();
    expect(ts.hour, 12);
    expect(
      ts.difference(DateTime.utc(2026, 9, 11, 12)).inMinutes.abs(),
      lessThan(2),
    );
  });
}

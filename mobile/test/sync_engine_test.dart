import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/core/database/app_database.dart';
import 'package:fidel_assistant/services/network_status.dart';
import 'package:fidel_assistant/services/sync_engine.dart';
import 'package:fidel_assistant/services/sync_outbox.dart';

class _FakeGateway implements SyncPriseGateway {
  _FakeGateway(this.log, {this.gate, this.throwOnConfirm = false});

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
}

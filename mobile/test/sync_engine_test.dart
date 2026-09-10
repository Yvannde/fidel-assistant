import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/services/sync_engine.dart';
import 'package:fidel_assistant/services/sync_outbox.dart';

class _FakeGateway implements SyncPriseGateway {
  _FakeGateway(this.log, {this.gate});

  final List<String> log;
  final Completer<void>? gate;

  @override
  Future<void> confirmPrise(String priseId, {String? clientMutationId}) async {
    if (gate != null) await gate!.future;
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

  test('single-flight: parallel flush shares one pass', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final outbox = SyncOutbox(prefs);
    final log = <String>[];
    final gate = Completer<void>();
    var factoryCalls = 0;

    final engine = SyncEngine(
      outbox: outbox,
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
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final outbox = SyncOutbox(prefs);
    final log = <String>[];

    final engine = SyncEngine(
      outbox: outbox,
      gatewayFactory: () => _FakeGateway(log),
    );

    final when = DateTime.utc(2026, 9, 10, 11);
    await engine.enqueueReport(priseId: 'same', nouvelleHeure: when);
    await engine.enqueueConfirm(priseId: 'same');
    await engine.flush();

    expect(log.map((e) => e.split(':').first).toList(), ['report', 'confirm']);
    expect(log.every((e) => e.contains('same')), isTrue);
  });
}

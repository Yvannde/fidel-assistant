import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/services/sync_outbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SyncOutbox outbox;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    outbox = SyncOutbox(prefs);
  });

  test('enqueue preserves FIFO order', () async {
    await outbox.enqueue(
      entity: 'prise',
      entityId: 'a',
      op: 'report',
      payload: {'nouvelle_heure': '2026-09-10T10:00:00Z'},
    );
    await outbox.enqueue(
      entity: 'prise',
      entityId: 'a',
      op: 'confirm',
      payload: {'canal': 'app'},
    );

    final ready = await outbox.listReady();
    expect(ready.map((e) => e.op).toList(), ['report', 'confirm']);
  });

  test('migrates pending_prise_sync_v1 then removes legacy key', () async {
    await prefs.setString(
      SyncOutbox.legacyKey,
      jsonEncode([
        {
          'type': 'confirm',
          'priseId': 'p1',
          'confirmeeAt': '2026-09-10T08:00:00.000Z',
        },
        {
          'type': 'report',
          'priseId': 'p2',
          'nouvelleHeure': '2026-09-10T09:30:00.000Z',
        },
      ]),
    );

    final ready = await outbox.listReady();
    expect(ready.length, 2);
    expect(ready[0].op, 'confirm');
    expect(ready[0].entityId, 'p1');
    expect(ready[1].op, 'report');
    expect(ready[1].entityId, 'p2');
    expect(prefs.getString(SyncOutbox.legacyKey), isNull);
    expect(prefs.getString(SyncOutbox.key), isNotNull);
  });

  test('markPermanent excludes from listReady; markRetry schedules later',
      () async {
    final e = await outbox.enqueue(
      entity: 'prise',
      entityId: 'x',
      op: 'confirm',
      payload: {},
    );
    await outbox.markPermanent(e.mutationId);
    expect(await outbox.listReady(), isEmpty);

    final e2 = await outbox.enqueue(
      entity: 'prise',
      entityId: 'y',
      op: 'confirm',
      payload: {},
    );
    await outbox.markRetry(e2.mutationId, attempts: 3);
    final now = DateTime.now().toUtc();
    final notYet = await outbox.listReady(now: now);
    expect(notYet, isEmpty);

    final later = await outbox.listReady(
      now: now.add(const Duration(minutes: 10)),
    );
    expect(later.single.mutationId, e2.mutationId);
    expect(later.single.attempts, 3);
    expect(later.single.state, SyncOutboxState.pending);
  });
}

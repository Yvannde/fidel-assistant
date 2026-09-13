import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidel_assistant/core/database/app_database.dart';
import 'package:fidel_assistant/features/home/data/home_repository.dart';
import 'package:fidel_assistant/services/sync_engine.dart';
import 'package:fidel_assistant/services/sync_outbox.dart';

class _BatchFake implements SyncPriseGateway, SyncBatchGateway {
  _BatchFake({
    required this.pushResults,
  });

  final List<SyncPushResultItem> pushResults;
  final List<List<Map<String, dynamic>>> pushed = [];

  @override
  Future<void> confirmPrise(String priseId, {String? clientMutationId}) async {
    fail('unitary confirm should not be used when batch is available');
  }

  @override
  Future<void> reportPrise(
    String priseId,
    DateTime nouvelleHeure, {
    String? clientMutationId,
  }) async {
    fail('unitary report should not be used when batch is available');
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
    fail('unitary createConstante should not be used when batch is available');
  }

  @override
  Future<void> createCheckIn(String statut, {String? clientMutationId}) async {
    fail('unitary createCheckIn should not be used when batch is available');
  }

  @override
  Future<SyncPushResponse> syncPush(List<Map<String, dynamic>> mutations) async {
    pushed.add(mutations);
    return SyncPushResponse(results: pushResults);
  }

  @override
  Future<SyncPullResponse> syncPull({String? since}) async {
    return SyncPullResponse(
      entities: const [],
      nextCursor: 'cursor-1',
      serverTime: DateTime.utc(2026, 9, 11),
    );
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

  test('batch push applied/duplicate ack outbox; rejected → permanent', () async {
    final prefs = await SharedPreferences.getInstance();
    final box = SyncOutbox(db, prefs: prefs);

    final m1 = await box.enqueue(
      entity: 'prise',
      entityId: 'p1',
      op: 'confirm',
      payload: {'canal': 'app'},
      mutationId: '11111111-1111-1111-1111-111111111111',
    );
    final m2 = await box.enqueue(
      entity: 'prise',
      entityId: 'p2',
      op: 'confirm',
      payload: {'canal': 'app'},
      mutationId: '22222222-2222-2222-2222-222222222222',
    );
    final m3 = await box.enqueue(
      entity: 'prise',
      entityId: 'p3',
      op: 'confirm',
      payload: {'canal': 'app'},
      mutationId: '33333333-3333-3333-3333-333333333333',
    );

    final fake = _BatchFake(
      pushResults: [
        SyncPushResultItem(mutationId: m1.mutationId, status: 'applied'),
        SyncPushResultItem(mutationId: m2.mutationId, status: 'duplicate'),
        SyncPushResultItem(
          mutationId: m3.mutationId,
          status: 'rejected',
          reason: 'SYNC_CONFLICT',
        ),
      ],
    );

    final engine = SyncEngine(
      outbox: box,
      db: db,
      prefs: prefs,
      gatewayFactory: () => fake,
    );

    await engine.flush(force: true);

    expect(fake.pushed, hasLength(1));
    expect(fake.pushed.single, hasLength(3));

    final remaining = await db.listAllOutbox();
    expect(remaining.map((e) => e.mutationId), [m3.mutationId]);
    expect(remaining.single.state, SyncOutboxState.failedPermanent);
    expect(prefs.getString(SyncEngine.pullCursorKey), 'cursor-1');
  });

  test('merge pull: higher server_version wins; pending outbox protects', () async {
    await db.mergePullEntities([
      {
        'type': 'prise',
        'id': 'p-a',
        'server_version': 1,
        'statut': 'en_attente',
        'medicament_nom': 'A',
        'dosage': '1',
        'heure_prevue': '2026-09-11T10:00:00.000Z',
        'updated_at': '2026-09-11T10:00:00.000Z',
      },
    ]);

    var row = await db.getPrise('p-a');
    expect(row!.statut, 'en_attente');
    expect(row.serverVersion, 1);

    await db.mergePullEntities([
      {
        'type': 'prise',
        'id': 'p-a',
        'server_version': 3,
        'statut': 'confirmee',
        'medicament_nom': 'A',
        'dosage': '1',
        'heure_prevue': '2026-09-11T10:00:00.000Z',
        'updated_at': '2026-09-11T11:00:00.000Z',
      },
    ]);
    row = await db.getPrise('p-a');
    expect(row!.statut, 'confirmee');
    expect(row.serverVersion, 3);

    // Lower version ignored
    await db.mergePullEntities([
      {
        'type': 'prise',
        'id': 'p-a',
        'server_version': 2,
        'statut': 'en_attente',
        'heure_prevue': '2026-09-11T10:00:00.000Z',
        'updated_at': '2026-09-11T10:30:00.000Z',
      },
    ]);
    row = await db.getPrise('p-a');
    expect(row!.statut, 'confirmee');
    expect(row.serverVersion, 3);

    // Pending outbox protects local intent
    await db.insertOutboxEntry(
      SyncOutboxEntry(
        mutationId: 'm-protect',
        entity: 'prise',
        entityId: 'p-a',
        op: 'report',
        payload: {'nouvelle_heure': '2026-09-11T12:00:00.000Z'},
        clientTs: DateTime.utc(2026, 9, 11, 12),
      ),
    );
    await db.mergePullEntities([
      {
        'type': 'prise',
        'id': 'p-a',
        'server_version': 99,
        'statut': 'manquee',
        'heure_prevue': '2026-09-11T10:00:00.000Z',
        'updated_at': '2026-09-11T13:00:00.000Z',
      },
    ]);
    row = await db.getPrise('p-a');
    expect(row!.statut, 'confirmee');
    expect(row.serverVersion, 3);
  });

  test('merge pull constante + check_in; pending outbox protects', () async {
    await db.mergePullEntities([
      {
        'type': 'constante',
        'id': 'c1',
        'type_constante': 'poids',
        'valeur': 70.0,
        'unite': 'kg',
        'mesure_at': '2026-09-11T09:00:00.000Z',
        'created_at': '2026-09-11T09:00:00.000Z',
        'source': 'manuel',
        'server_version': 1,
      },
      {
        'type': 'check_in',
        'id': 'ci1',
        'date': '2026-09-11',
        'statut': 'ca_va',
        'created_at': '2026-09-11T08:00:00.000Z',
      },
    ]);

    final consts = await db.listConstantesSince(DateTime.utc(2026, 9, 1));
    expect(consts, isNotEmpty);
    expect(consts.first.type.code, 'poids');

    final check = await db.getCheckInForDateKey('2026-09-11');
    expect(check, isNotNull);
    expect(check!.statut, 'ca_va');

    await db.insertOutboxEntry(
      SyncOutboxEntry(
        mutationId: 'm-ci',
        entity: 'check_in',
        entityId: '2026-09-11',
        op: 'create_check_in',
        payload: {'statut': 'pas_top'},
        clientTs: DateTime.utc(2026, 9, 11, 9),
      ),
    );
    await db.mergePullEntities([
      {
        'type': 'check_in',
        'id': 'ci2',
        'date': '2026-09-11',
        'statut': 'pas_top',
        'created_at': '2026-09-11T10:00:00.000Z',
      },
    ]);
    final protected = await db.getCheckInForDateKey('2026-09-11');
    expect(protected!.statut, 'ca_va');
  });

  test('batch push create_constante + create_check_in ack', () async {
    final prefs = await SharedPreferences.getInstance();
    final box = SyncOutbox(db, prefs: prefs);
    final mConst = await box.enqueue(
      entity: 'constante',
      entityId: '11111111-1111-1111-1111-111111111111',
      op: 'create_constante',
      payload: {
        'type': 'poids',
        'valeur': 71,
        'unite': 'kg',
        'mesure_at': '2026-09-11T10:00:00.000Z',
        'source': 'manuel',
      },
      mutationId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    );
    final mCheck = await box.enqueue(
      entity: 'check_in',
      entityId: '2026-09-11',
      op: 'create_check_in',
      payload: {'statut': 'ca_va'},
      mutationId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    );

    final fake = _BatchFake(
      pushResults: [
        SyncPushResultItem(mutationId: mConst.mutationId, status: 'applied'),
        SyncPushResultItem(mutationId: mCheck.mutationId, status: 'duplicate'),
      ],
    );
    final engine = SyncEngine(
      outbox: box,
      db: db,
      prefs: prefs,
      gatewayFactory: () => fake,
    );
    await engine.flush(force: true);

    expect(fake.pushed.single, hasLength(2));
    expect(fake.pushed.single[1]['entity_id'], isNull);
    expect(await db.listAllOutbox(), isEmpty);
  });
}

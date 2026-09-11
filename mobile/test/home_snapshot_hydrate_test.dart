import 'package:flutter_test/flutter_test.dart';

import 'package:fidel_assistant/core/database/app_database.dart';
import 'package:fidel_assistant/features/home/application/home_projection.dart';
import 'package:fidel_assistant/features/home/domain/dashboard_models.dart';
import 'package:fidel_assistant/services/sync_outbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test('offline hydrate: readDashboardMeta + outbox projection without network',
      () async {
    final now = DateTime.now();
    final dash = PatientDashboard(
      prochaineAction: 'prise',
      medicamentsConfigures: true,
      notificationsAccordees: true,
      traitements: const [],
      prisesAujourdhui: [
        PriseDuJour(
          id: 'p-offline',
          medicamentNom: 'Paracétamol',
          dosage: '500mg',
          heurePrevue: now.add(const Duration(hours: 1)),
          statut: 'en_attente',
        ),
      ],
    );

    await db.upsertDashboard(dash);
    await db.insertOutboxEntry(
      SyncOutboxEntry(
        mutationId: 'm-offline',
        entity: 'prise',
        entityId: 'p-offline',
        op: 'confirm',
        payload: {'canal': 'app'},
        clientTs: DateTime.now().toUtc(),
      ),
    );

    final base = await db.readDashboardMeta();
    expect(base, isNotNull);
    expect(base!.prisesAujourdhui, isNotEmpty);

    final outbox = await db.listActiveOutbox();
    final projected = HomeProjection.projectDashboard(
      base: base,
      outbox: outbox,
    );

    expect(projected.prisesAujourdhui.single.id, 'p-offline');
    expect(projected.prisesAujourdhui.single.statut, 'confirmee');
    expect(projected.prisesAujourdhui.single.isTaken, isTrue);
  });
}

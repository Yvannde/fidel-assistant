import 'package:drift/drift.dart';

/// Snapshot local des prises (horizon ~48 h + pending outbox).
@DataClassName('PriseSnapshot')
class PriseSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get dateKey => text()(); // YYYY-MM-DD
  DateTimeColumn get heurePrevue => dateTime()();
  TextColumn get statut => text()();
  TextColumn get medicamentNom => text().withDefault(const Constant(''))();
  TextColumn get dosage => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get serverVersion => integer().withDefault(const Constant(1))();
  TextColumn get payloadJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Miroir traitements / médicaments (JSON serveur autoritaire).
class TraitementMirrors extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Outbox sync (contrat offline-sync).
@DataClassName('OutboxRow')
class SyncOutboxEntries extends Table {
  TextColumn get mutationId => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get clientTs => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get state => text()(); // pending | inflight | failed_permanent
  IntColumn get sortIndex => integer()(); // FIFO enqueue order

  @override
  Set<Column<Object>> get primaryKey => {mutationId};
}

/// Meta dashboard (flags + traitements dashboard JSON).
class DashboardSnapshots extends Table {
  IntColumn get id => integer()(); // always 1
  TextColumn get prochaineAction => text()();
  BoolColumn get medicamentsConfigures => boolean()();
  BoolColumn get notificationsAccordees => boolean()();
  TextColumn get traitementsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Constantes de santé (append-only, Phase 5).
@DataClassName('ConstanteSnapshot')
class ConstanteSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get typeCode => text()();
  TextColumn get valeurJson => text()();
  TextColumn get unite => text()();
  DateTimeColumn get mesureAt => dateTime()();
  TextColumn get source => text().withDefault(const Constant('manuel'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  IntColumn get serverVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Check-in quotidien (1 / jour, Phase 5).
@DataClassName('CheckInSnapshot')
class CheckInSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get dateKey => text()(); // YYYY-MM-DD
  TextColumn get statut => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

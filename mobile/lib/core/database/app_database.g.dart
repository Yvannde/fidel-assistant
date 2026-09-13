// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PriseSnapshotsTable extends PriseSnapshots
    with TableInfo<$PriseSnapshotsTable, PriseSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriseSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateKeyMeta =
      const VerificationMeta('dateKey');
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
      'date_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heurePrevueMeta =
      const VerificationMeta('heurePrevue');
  @override
  late final GeneratedColumn<DateTime> heurePrevue = GeneratedColumn<DateTime>(
      'heure_prevue', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
      'statut', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _medicamentNomMeta =
      const VerificationMeta('medicamentNom');
  @override
  late final GeneratedColumn<String> medicamentNom = GeneratedColumn<String>(
      'medicament_nom', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
      'dosage', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _serverVersionMeta =
      const VerificationMeta('serverVersion');
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
      'server_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        dateKey,
        heurePrevue,
        statut,
        medicamentNom,
        dosage,
        updatedAt,
        serverVersion,
        payloadJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prise_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<PriseSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date_key')) {
      context.handle(_dateKeyMeta,
          dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta));
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('heure_prevue')) {
      context.handle(
          _heurePrevueMeta,
          heurePrevue.isAcceptableOrUnknown(
              data['heure_prevue']!, _heurePrevueMeta));
    } else if (isInserting) {
      context.missing(_heurePrevueMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(_statutMeta,
          statut.isAcceptableOrUnknown(data['statut']!, _statutMeta));
    } else if (isInserting) {
      context.missing(_statutMeta);
    }
    if (data.containsKey('medicament_nom')) {
      context.handle(
          _medicamentNomMeta,
          medicamentNom.isAcceptableOrUnknown(
              data['medicament_nom']!, _medicamentNomMeta));
    }
    if (data.containsKey('dosage')) {
      context.handle(_dosageMeta,
          dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('server_version')) {
      context.handle(
          _serverVersionMeta,
          serverVersion.isAcceptableOrUnknown(
              data['server_version']!, _serverVersionMeta));
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriseSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriseSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      dateKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_key'])!,
      heurePrevue: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}heure_prevue'])!,
      statut: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}statut'])!,
      medicamentNom: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}medicament_nom'])!,
      dosage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      serverVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_version'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json']),
    );
  }

  @override
  $PriseSnapshotsTable createAlias(String alias) {
    return $PriseSnapshotsTable(attachedDatabase, alias);
  }
}

class PriseSnapshot extends DataClass implements Insertable<PriseSnapshot> {
  final String id;
  final String dateKey;
  final DateTime heurePrevue;
  final String statut;
  final String medicamentNom;
  final String dosage;
  final DateTime? updatedAt;
  final int serverVersion;
  final String? payloadJson;
  const PriseSnapshot(
      {required this.id,
      required this.dateKey,
      required this.heurePrevue,
      required this.statut,
      required this.medicamentNom,
      required this.dosage,
      this.updatedAt,
      required this.serverVersion,
      this.payloadJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date_key'] = Variable<String>(dateKey);
    map['heure_prevue'] = Variable<DateTime>(heurePrevue);
    map['statut'] = Variable<String>(statut);
    map['medicament_nom'] = Variable<String>(medicamentNom);
    map['dosage'] = Variable<String>(dosage);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['server_version'] = Variable<int>(serverVersion);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    return map;
  }

  PriseSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return PriseSnapshotsCompanion(
      id: Value(id),
      dateKey: Value(dateKey),
      heurePrevue: Value(heurePrevue),
      statut: Value(statut),
      medicamentNom: Value(medicamentNom),
      dosage: Value(dosage),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      serverVersion: Value(serverVersion),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
    );
  }

  factory PriseSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriseSnapshot(
      id: serializer.fromJson<String>(json['id']),
      dateKey: serializer.fromJson<String>(json['dateKey']),
      heurePrevue: serializer.fromJson<DateTime>(json['heurePrevue']),
      statut: serializer.fromJson<String>(json['statut']),
      medicamentNom: serializer.fromJson<String>(json['medicamentNom']),
      dosage: serializer.fromJson<String>(json['dosage']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dateKey': serializer.toJson<String>(dateKey),
      'heurePrevue': serializer.toJson<DateTime>(heurePrevue),
      'statut': serializer.toJson<String>(statut),
      'medicamentNom': serializer.toJson<String>(medicamentNom),
      'dosage': serializer.toJson<String>(dosage),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'payloadJson': serializer.toJson<String?>(payloadJson),
    };
  }

  PriseSnapshot copyWith(
          {String? id,
          String? dateKey,
          DateTime? heurePrevue,
          String? statut,
          String? medicamentNom,
          String? dosage,
          Value<DateTime?> updatedAt = const Value.absent(),
          int? serverVersion,
          Value<String?> payloadJson = const Value.absent()}) =>
      PriseSnapshot(
        id: id ?? this.id,
        dateKey: dateKey ?? this.dateKey,
        heurePrevue: heurePrevue ?? this.heurePrevue,
        statut: statut ?? this.statut,
        medicamentNom: medicamentNom ?? this.medicamentNom,
        dosage: dosage ?? this.dosage,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        serverVersion: serverVersion ?? this.serverVersion,
        payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
      );
  PriseSnapshot copyWithCompanion(PriseSnapshotsCompanion data) {
    return PriseSnapshot(
      id: data.id.present ? data.id.value : this.id,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      heurePrevue:
          data.heurePrevue.present ? data.heurePrevue.value : this.heurePrevue,
      statut: data.statut.present ? data.statut.value : this.statut,
      medicamentNom: data.medicamentNom.present
          ? data.medicamentNom.value
          : this.medicamentNom,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriseSnapshot(')
          ..write('id: $id, ')
          ..write('dateKey: $dateKey, ')
          ..write('heurePrevue: $heurePrevue, ')
          ..write('statut: $statut, ')
          ..write('medicamentNom: $medicamentNom, ')
          ..write('dosage: $dosage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dateKey, heurePrevue, statut,
      medicamentNom, dosage, updatedAt, serverVersion, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriseSnapshot &&
          other.id == this.id &&
          other.dateKey == this.dateKey &&
          other.heurePrevue == this.heurePrevue &&
          other.statut == this.statut &&
          other.medicamentNom == this.medicamentNom &&
          other.dosage == this.dosage &&
          other.updatedAt == this.updatedAt &&
          other.serverVersion == this.serverVersion &&
          other.payloadJson == this.payloadJson);
}

class PriseSnapshotsCompanion extends UpdateCompanion<PriseSnapshot> {
  final Value<String> id;
  final Value<String> dateKey;
  final Value<DateTime> heurePrevue;
  final Value<String> statut;
  final Value<String> medicamentNom;
  final Value<String> dosage;
  final Value<DateTime?> updatedAt;
  final Value<int> serverVersion;
  final Value<String?> payloadJson;
  final Value<int> rowid;
  const PriseSnapshotsCompanion({
    this.id = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.heurePrevue = const Value.absent(),
    this.statut = const Value.absent(),
    this.medicamentNom = const Value.absent(),
    this.dosage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriseSnapshotsCompanion.insert({
    required String id,
    required String dateKey,
    required DateTime heurePrevue,
    required String statut,
    this.medicamentNom = const Value.absent(),
    this.dosage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        dateKey = Value(dateKey),
        heurePrevue = Value(heurePrevue),
        statut = Value(statut);
  static Insertable<PriseSnapshot> custom({
    Expression<String>? id,
    Expression<String>? dateKey,
    Expression<DateTime>? heurePrevue,
    Expression<String>? statut,
    Expression<String>? medicamentNom,
    Expression<String>? dosage,
    Expression<DateTime>? updatedAt,
    Expression<int>? serverVersion,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateKey != null) 'date_key': dateKey,
      if (heurePrevue != null) 'heure_prevue': heurePrevue,
      if (statut != null) 'statut': statut,
      if (medicamentNom != null) 'medicament_nom': medicamentNom,
      if (dosage != null) 'dosage': dosage,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverVersion != null) 'server_version': serverVersion,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriseSnapshotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? dateKey,
      Value<DateTime>? heurePrevue,
      Value<String>? statut,
      Value<String>? medicamentNom,
      Value<String>? dosage,
      Value<DateTime?>? updatedAt,
      Value<int>? serverVersion,
      Value<String?>? payloadJson,
      Value<int>? rowid}) {
    return PriseSnapshotsCompanion(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      heurePrevue: heurePrevue ?? this.heurePrevue,
      statut: statut ?? this.statut,
      medicamentNom: medicamentNom ?? this.medicamentNom,
      dosage: dosage ?? this.dosage,
      updatedAt: updatedAt ?? this.updatedAt,
      serverVersion: serverVersion ?? this.serverVersion,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (heurePrevue.present) {
      map['heure_prevue'] = Variable<DateTime>(heurePrevue.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (medicamentNom.present) {
      map['medicament_nom'] = Variable<String>(medicamentNom.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriseSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('dateKey: $dateKey, ')
          ..write('heurePrevue: $heurePrevue, ')
          ..write('statut: $statut, ')
          ..write('medicamentNom: $medicamentNom, ')
          ..write('dosage: $dosage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TraitementMirrorsTable extends TraitementMirrors
    with TableInfo<$TraitementMirrorsTable, TraitementMirror> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TraitementMirrorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, payloadJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'traitement_mirrors';
  @override
  VerificationContext validateIntegrity(Insertable<TraitementMirror> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TraitementMirror map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TraitementMirror(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TraitementMirrorsTable createAlias(String alias) {
    return $TraitementMirrorsTable(attachedDatabase, alias);
  }
}

class TraitementMirror extends DataClass
    implements Insertable<TraitementMirror> {
  final String id;
  final String payloadJson;
  final DateTime updatedAt;
  const TraitementMirror(
      {required this.id, required this.payloadJson, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TraitementMirrorsCompanion toCompanion(bool nullToAbsent) {
    return TraitementMirrorsCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory TraitementMirror.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TraitementMirror(
      id: serializer.fromJson<String>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TraitementMirror copyWith(
          {String? id, String? payloadJson, DateTime? updatedAt}) =>
      TraitementMirror(
        id: id ?? this.id,
        payloadJson: payloadJson ?? this.payloadJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TraitementMirror copyWithCompanion(TraitementMirrorsCompanion data) {
    return TraitementMirror(
      id: data.id.present ? data.id.value : this.id,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TraitementMirror(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TraitementMirror &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class TraitementMirrorsCompanion extends UpdateCompanion<TraitementMirror> {
  final Value<String> id;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TraitementMirrorsCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TraitementMirrorsCompanion.insert({
    required String id,
    required String payloadJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        payloadJson = Value(payloadJson),
        updatedAt = Value(updatedAt);
  static Insertable<TraitementMirror> custom({
    Expression<String>? id,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TraitementMirrorsCompanion copyWith(
      {Value<String>? id,
      Value<String>? payloadJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TraitementMirrorsCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TraitementMirrorsCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxEntriesTable extends SyncOutboxEntries
    with TableInfo<$SyncOutboxEntriesTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mutationIdMeta =
      const VerificationMeta('mutationId');
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
      'mutation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
      'op', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientTsMeta =
      const VerificationMeta('clientTs');
  @override
  late final GeneratedColumn<DateTime> clientTs = GeneratedColumn<DateTime>(
      'client_ts', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortIndexMeta =
      const VerificationMeta('sortIndex');
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
      'sort_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        mutationId,
        entity,
        entityId,
        op,
        payloadJson,
        clientTs,
        attempts,
        nextAttemptAt,
        state,
        sortIndex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox_entries';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mutation_id')) {
      context.handle(
          _mutationIdMeta,
          mutationId.isAcceptableOrUnknown(
              data['mutation_id']!, _mutationIdMeta));
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('client_ts')) {
      context.handle(_clientTsMeta,
          clientTs.isAcceptableOrUnknown(data['client_ts']!, _clientTsMeta));
    } else if (isInserting) {
      context.missing(_clientTsMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(_sortIndexMeta,
          sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta));
    } else if (isInserting) {
      context.missing(_sortIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mutationId};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      mutationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mutation_id'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      op: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      clientTs: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}client_ts'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      sortIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_index'])!,
    );
  }

  @override
  $SyncOutboxEntriesTable createAlias(String alias) {
    return $SyncOutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final String mutationId;
  final String entity;
  final String entityId;
  final String op;
  final String payloadJson;
  final DateTime clientTs;
  final int attempts;
  final DateTime nextAttemptAt;
  final String state;
  final int sortIndex;
  const OutboxRow(
      {required this.mutationId,
      required this.entity,
      required this.entityId,
      required this.op,
      required this.payloadJson,
      required this.clientTs,
      required this.attempts,
      required this.nextAttemptAt,
      required this.state,
      required this.sortIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mutation_id'] = Variable<String>(mutationId);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    map['payload_json'] = Variable<String>(payloadJson);
    map['client_ts'] = Variable<DateTime>(clientTs);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    map['state'] = Variable<String>(state);
    map['sort_index'] = Variable<int>(sortIndex);
    return map;
  }

  SyncOutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxEntriesCompanion(
      mutationId: Value(mutationId),
      entity: Value(entity),
      entityId: Value(entityId),
      op: Value(op),
      payloadJson: Value(payloadJson),
      clientTs: Value(clientTs),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      state: Value(state),
      sortIndex: Value(sortIndex),
    );
  }

  factory OutboxRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      mutationId: serializer.fromJson<String>(json['mutationId']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      clientTs: serializer.fromJson<DateTime>(json['clientTs']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      state: serializer.fromJson<String>(json['state']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mutationId': serializer.toJson<String>(mutationId),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'clientTs': serializer.toJson<DateTime>(clientTs),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'state': serializer.toJson<String>(state),
      'sortIndex': serializer.toJson<int>(sortIndex),
    };
  }

  OutboxRow copyWith(
          {String? mutationId,
          String? entity,
          String? entityId,
          String? op,
          String? payloadJson,
          DateTime? clientTs,
          int? attempts,
          DateTime? nextAttemptAt,
          String? state,
          int? sortIndex}) =>
      OutboxRow(
        mutationId: mutationId ?? this.mutationId,
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
        op: op ?? this.op,
        payloadJson: payloadJson ?? this.payloadJson,
        clientTs: clientTs ?? this.clientTs,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        state: state ?? this.state,
        sortIndex: sortIndex ?? this.sortIndex,
      );
  OutboxRow copyWithCompanion(SyncOutboxEntriesCompanion data) {
    return OutboxRow(
      mutationId:
          data.mutationId.present ? data.mutationId.value : this.mutationId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      clientTs: data.clientTs.present ? data.clientTs.value : this.clientTs,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      state: data.state.present ? data.state.value : this.state,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('mutationId: $mutationId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('clientTs: $clientTs, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('state: $state, ')
          ..write('sortIndex: $sortIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mutationId, entity, entityId, op, payloadJson,
      clientTs, attempts, nextAttemptAt, state, sortIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.mutationId == this.mutationId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.payloadJson == this.payloadJson &&
          other.clientTs == this.clientTs &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.state == this.state &&
          other.sortIndex == this.sortIndex);
}

class SyncOutboxEntriesCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> mutationId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> op;
  final Value<String> payloadJson;
  final Value<DateTime> clientTs;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<String> state;
  final Value<int> sortIndex;
  final Value<int> rowid;
  const SyncOutboxEntriesCompanion({
    this.mutationId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.clientTs = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.state = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxEntriesCompanion.insert({
    required String mutationId,
    required String entity,
    required String entityId,
    required String op,
    required String payloadJson,
    required DateTime clientTs,
    this.attempts = const Value.absent(),
    required DateTime nextAttemptAt,
    required String state,
    required int sortIndex,
    this.rowid = const Value.absent(),
  })  : mutationId = Value(mutationId),
        entity = Value(entity),
        entityId = Value(entityId),
        op = Value(op),
        payloadJson = Value(payloadJson),
        clientTs = Value(clientTs),
        nextAttemptAt = Value(nextAttemptAt),
        state = Value(state),
        sortIndex = Value(sortIndex);
  static Insertable<OutboxRow> custom({
    Expression<String>? mutationId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<String>? payloadJson,
    Expression<DateTime>? clientTs,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? state,
    Expression<int>? sortIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mutationId != null) 'mutation_id': mutationId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (clientTs != null) 'client_ts': clientTs,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (state != null) 'state': state,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxEntriesCompanion copyWith(
      {Value<String>? mutationId,
      Value<String>? entity,
      Value<String>? entityId,
      Value<String>? op,
      Value<String>? payloadJson,
      Value<DateTime>? clientTs,
      Value<int>? attempts,
      Value<DateTime>? nextAttemptAt,
      Value<String>? state,
      Value<int>? sortIndex,
      Value<int>? rowid}) {
    return SyncOutboxEntriesCompanion(
      mutationId: mutationId ?? this.mutationId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payloadJson: payloadJson ?? this.payloadJson,
      clientTs: clientTs ?? this.clientTs,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      state: state ?? this.state,
      sortIndex: sortIndex ?? this.sortIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (clientTs.present) {
      map['client_ts'] = Variable<DateTime>(clientTs.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxEntriesCompanion(')
          ..write('mutationId: $mutationId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('clientTs: $clientTs, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('state: $state, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DashboardSnapshotsTable extends DashboardSnapshots
    with TableInfo<$DashboardSnapshotsTable, DashboardSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _prochaineActionMeta =
      const VerificationMeta('prochaineAction');
  @override
  late final GeneratedColumn<String> prochaineAction = GeneratedColumn<String>(
      'prochaine_action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _medicamentsConfiguresMeta =
      const VerificationMeta('medicamentsConfigures');
  @override
  late final GeneratedColumn<bool> medicamentsConfigures =
      GeneratedColumn<bool>('medicaments_configures', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("medicaments_configures" IN (0, 1))'));
  static const VerificationMeta _notificationsAccordeesMeta =
      const VerificationMeta('notificationsAccordees');
  @override
  late final GeneratedColumn<bool> notificationsAccordees =
      GeneratedColumn<bool>('notifications_accordees', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("notifications_accordees" IN (0, 1))'));
  static const VerificationMeta _traitementsJsonMeta =
      const VerificationMeta('traitementsJson');
  @override
  late final GeneratedColumn<String> traitementsJson = GeneratedColumn<String>(
      'traitements_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        prochaineAction,
        medicamentsConfigures,
        notificationsAccordees,
        traitementsJson,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<DashboardSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prochaine_action')) {
      context.handle(
          _prochaineActionMeta,
          prochaineAction.isAcceptableOrUnknown(
              data['prochaine_action']!, _prochaineActionMeta));
    } else if (isInserting) {
      context.missing(_prochaineActionMeta);
    }
    if (data.containsKey('medicaments_configures')) {
      context.handle(
          _medicamentsConfiguresMeta,
          medicamentsConfigures.isAcceptableOrUnknown(
              data['medicaments_configures']!, _medicamentsConfiguresMeta));
    } else if (isInserting) {
      context.missing(_medicamentsConfiguresMeta);
    }
    if (data.containsKey('notifications_accordees')) {
      context.handle(
          _notificationsAccordeesMeta,
          notificationsAccordees.isAcceptableOrUnknown(
              data['notifications_accordees']!, _notificationsAccordeesMeta));
    } else if (isInserting) {
      context.missing(_notificationsAccordeesMeta);
    }
    if (data.containsKey('traitements_json')) {
      context.handle(
          _traitementsJsonMeta,
          traitementsJson.isAcceptableOrUnknown(
              data['traitements_json']!, _traitementsJsonMeta));
    } else if (isInserting) {
      context.missing(_traitementsJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DashboardSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      prochaineAction: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}prochaine_action'])!,
      medicamentsConfigures: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}medicaments_configures'])!,
      notificationsAccordees: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}notifications_accordees'])!,
      traitementsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}traitements_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DashboardSnapshotsTable createAlias(String alias) {
    return $DashboardSnapshotsTable(attachedDatabase, alias);
  }
}

class DashboardSnapshot extends DataClass
    implements Insertable<DashboardSnapshot> {
  final int id;
  final String prochaineAction;
  final bool medicamentsConfigures;
  final bool notificationsAccordees;
  final String traitementsJson;
  final DateTime updatedAt;
  const DashboardSnapshot(
      {required this.id,
      required this.prochaineAction,
      required this.medicamentsConfigures,
      required this.notificationsAccordees,
      required this.traitementsJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prochaine_action'] = Variable<String>(prochaineAction);
    map['medicaments_configures'] = Variable<bool>(medicamentsConfigures);
    map['notifications_accordees'] = Variable<bool>(notificationsAccordees);
    map['traitements_json'] = Variable<String>(traitementsJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DashboardSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return DashboardSnapshotsCompanion(
      id: Value(id),
      prochaineAction: Value(prochaineAction),
      medicamentsConfigures: Value(medicamentsConfigures),
      notificationsAccordees: Value(notificationsAccordees),
      traitementsJson: Value(traitementsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardSnapshot(
      id: serializer.fromJson<int>(json['id']),
      prochaineAction: serializer.fromJson<String>(json['prochaineAction']),
      medicamentsConfigures:
          serializer.fromJson<bool>(json['medicamentsConfigures']),
      notificationsAccordees:
          serializer.fromJson<bool>(json['notificationsAccordees']),
      traitementsJson: serializer.fromJson<String>(json['traitementsJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'prochaineAction': serializer.toJson<String>(prochaineAction),
      'medicamentsConfigures': serializer.toJson<bool>(medicamentsConfigures),
      'notificationsAccordees': serializer.toJson<bool>(notificationsAccordees),
      'traitementsJson': serializer.toJson<String>(traitementsJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DashboardSnapshot copyWith(
          {int? id,
          String? prochaineAction,
          bool? medicamentsConfigures,
          bool? notificationsAccordees,
          String? traitementsJson,
          DateTime? updatedAt}) =>
      DashboardSnapshot(
        id: id ?? this.id,
        prochaineAction: prochaineAction ?? this.prochaineAction,
        medicamentsConfigures:
            medicamentsConfigures ?? this.medicamentsConfigures,
        notificationsAccordees:
            notificationsAccordees ?? this.notificationsAccordees,
        traitementsJson: traitementsJson ?? this.traitementsJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DashboardSnapshot copyWithCompanion(DashboardSnapshotsCompanion data) {
    return DashboardSnapshot(
      id: data.id.present ? data.id.value : this.id,
      prochaineAction: data.prochaineAction.present
          ? data.prochaineAction.value
          : this.prochaineAction,
      medicamentsConfigures: data.medicamentsConfigures.present
          ? data.medicamentsConfigures.value
          : this.medicamentsConfigures,
      notificationsAccordees: data.notificationsAccordees.present
          ? data.notificationsAccordees.value
          : this.notificationsAccordees,
      traitementsJson: data.traitementsJson.present
          ? data.traitementsJson.value
          : this.traitementsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardSnapshot(')
          ..write('id: $id, ')
          ..write('prochaineAction: $prochaineAction, ')
          ..write('medicamentsConfigures: $medicamentsConfigures, ')
          ..write('notificationsAccordees: $notificationsAccordees, ')
          ..write('traitementsJson: $traitementsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, prochaineAction, medicamentsConfigures,
      notificationsAccordees, traitementsJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardSnapshot &&
          other.id == this.id &&
          other.prochaineAction == this.prochaineAction &&
          other.medicamentsConfigures == this.medicamentsConfigures &&
          other.notificationsAccordees == this.notificationsAccordees &&
          other.traitementsJson == this.traitementsJson &&
          other.updatedAt == this.updatedAt);
}

class DashboardSnapshotsCompanion extends UpdateCompanion<DashboardSnapshot> {
  final Value<int> id;
  final Value<String> prochaineAction;
  final Value<bool> medicamentsConfigures;
  final Value<bool> notificationsAccordees;
  final Value<String> traitementsJson;
  final Value<DateTime> updatedAt;
  const DashboardSnapshotsCompanion({
    this.id = const Value.absent(),
    this.prochaineAction = const Value.absent(),
    this.medicamentsConfigures = const Value.absent(),
    this.notificationsAccordees = const Value.absent(),
    this.traitementsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DashboardSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required String prochaineAction,
    required bool medicamentsConfigures,
    required bool notificationsAccordees,
    required String traitementsJson,
    required DateTime updatedAt,
  })  : prochaineAction = Value(prochaineAction),
        medicamentsConfigures = Value(medicamentsConfigures),
        notificationsAccordees = Value(notificationsAccordees),
        traitementsJson = Value(traitementsJson),
        updatedAt = Value(updatedAt);
  static Insertable<DashboardSnapshot> custom({
    Expression<int>? id,
    Expression<String>? prochaineAction,
    Expression<bool>? medicamentsConfigures,
    Expression<bool>? notificationsAccordees,
    Expression<String>? traitementsJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prochaineAction != null) 'prochaine_action': prochaineAction,
      if (medicamentsConfigures != null)
        'medicaments_configures': medicamentsConfigures,
      if (notificationsAccordees != null)
        'notifications_accordees': notificationsAccordees,
      if (traitementsJson != null) 'traitements_json': traitementsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DashboardSnapshotsCompanion copyWith(
      {Value<int>? id,
      Value<String>? prochaineAction,
      Value<bool>? medicamentsConfigures,
      Value<bool>? notificationsAccordees,
      Value<String>? traitementsJson,
      Value<DateTime>? updatedAt}) {
    return DashboardSnapshotsCompanion(
      id: id ?? this.id,
      prochaineAction: prochaineAction ?? this.prochaineAction,
      medicamentsConfigures:
          medicamentsConfigures ?? this.medicamentsConfigures,
      notificationsAccordees:
          notificationsAccordees ?? this.notificationsAccordees,
      traitementsJson: traitementsJson ?? this.traitementsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (prochaineAction.present) {
      map['prochaine_action'] = Variable<String>(prochaineAction.value);
    }
    if (medicamentsConfigures.present) {
      map['medicaments_configures'] =
          Variable<bool>(medicamentsConfigures.value);
    }
    if (notificationsAccordees.present) {
      map['notifications_accordees'] =
          Variable<bool>(notificationsAccordees.value);
    }
    if (traitementsJson.present) {
      map['traitements_json'] = Variable<String>(traitementsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('prochaineAction: $prochaineAction, ')
          ..write('medicamentsConfigures: $medicamentsConfigures, ')
          ..write('notificationsAccordees: $notificationsAccordees, ')
          ..write('traitementsJson: $traitementsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ConstanteSnapshotsTable extends ConstanteSnapshots
    with TableInfo<$ConstanteSnapshotsTable, ConstanteSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConstanteSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeCodeMeta =
      const VerificationMeta('typeCode');
  @override
  late final GeneratedColumn<String> typeCode = GeneratedColumn<String>(
      'type_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valeurJsonMeta =
      const VerificationMeta('valeurJson');
  @override
  late final GeneratedColumn<String> valeurJson = GeneratedColumn<String>(
      'valeur_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _uniteMeta = const VerificationMeta('unite');
  @override
  late final GeneratedColumn<String> unite = GeneratedColumn<String>(
      'unite', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mesureAtMeta =
      const VerificationMeta('mesureAt');
  @override
  late final GeneratedColumn<DateTime> mesureAt = GeneratedColumn<DateTime>(
      'mesure_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manuel'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _serverVersionMeta =
      const VerificationMeta('serverVersion');
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
      'server_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        typeCode,
        valeurJson,
        unite,
        mesureAt,
        source,
        createdAt,
        serverVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'constante_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<ConstanteSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type_code')) {
      context.handle(_typeCodeMeta,
          typeCode.isAcceptableOrUnknown(data['type_code']!, _typeCodeMeta));
    } else if (isInserting) {
      context.missing(_typeCodeMeta);
    }
    if (data.containsKey('valeur_json')) {
      context.handle(
          _valeurJsonMeta,
          valeurJson.isAcceptableOrUnknown(
              data['valeur_json']!, _valeurJsonMeta));
    } else if (isInserting) {
      context.missing(_valeurJsonMeta);
    }
    if (data.containsKey('unite')) {
      context.handle(
          _uniteMeta, unite.isAcceptableOrUnknown(data['unite']!, _uniteMeta));
    } else if (isInserting) {
      context.missing(_uniteMeta);
    }
    if (data.containsKey('mesure_at')) {
      context.handle(_mesureAtMeta,
          mesureAt.isAcceptableOrUnknown(data['mesure_at']!, _mesureAtMeta));
    } else if (isInserting) {
      context.missing(_mesureAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('server_version')) {
      context.handle(
          _serverVersionMeta,
          serverVersion.isAcceptableOrUnknown(
              data['server_version']!, _serverVersionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConstanteSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConstanteSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      typeCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type_code'])!,
      valeurJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}valeur_json'])!,
      unite: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unite'])!,
      mesureAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}mesure_at'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      serverVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_version'])!,
    );
  }

  @override
  $ConstanteSnapshotsTable createAlias(String alias) {
    return $ConstanteSnapshotsTable(attachedDatabase, alias);
  }
}

class ConstanteSnapshot extends DataClass
    implements Insertable<ConstanteSnapshot> {
  final String id;
  final String typeCode;
  final String valeurJson;
  final String unite;
  final DateTime mesureAt;
  final String source;
  final DateTime? createdAt;
  final int serverVersion;
  const ConstanteSnapshot(
      {required this.id,
      required this.typeCode,
      required this.valeurJson,
      required this.unite,
      required this.mesureAt,
      required this.source,
      this.createdAt,
      required this.serverVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type_code'] = Variable<String>(typeCode);
    map['valeur_json'] = Variable<String>(valeurJson);
    map['unite'] = Variable<String>(unite);
    map['mesure_at'] = Variable<DateTime>(mesureAt);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['server_version'] = Variable<int>(serverVersion);
    return map;
  }

  ConstanteSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return ConstanteSnapshotsCompanion(
      id: Value(id),
      typeCode: Value(typeCode),
      valeurJson: Value(valeurJson),
      unite: Value(unite),
      mesureAt: Value(mesureAt),
      source: Value(source),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      serverVersion: Value(serverVersion),
    );
  }

  factory ConstanteSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConstanteSnapshot(
      id: serializer.fromJson<String>(json['id']),
      typeCode: serializer.fromJson<String>(json['typeCode']),
      valeurJson: serializer.fromJson<String>(json['valeurJson']),
      unite: serializer.fromJson<String>(json['unite']),
      mesureAt: serializer.fromJson<DateTime>(json['mesureAt']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'typeCode': serializer.toJson<String>(typeCode),
      'valeurJson': serializer.toJson<String>(valeurJson),
      'unite': serializer.toJson<String>(unite),
      'mesureAt': serializer.toJson<DateTime>(mesureAt),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'serverVersion': serializer.toJson<int>(serverVersion),
    };
  }

  ConstanteSnapshot copyWith(
          {String? id,
          String? typeCode,
          String? valeurJson,
          String? unite,
          DateTime? mesureAt,
          String? source,
          Value<DateTime?> createdAt = const Value.absent(),
          int? serverVersion}) =>
      ConstanteSnapshot(
        id: id ?? this.id,
        typeCode: typeCode ?? this.typeCode,
        valeurJson: valeurJson ?? this.valeurJson,
        unite: unite ?? this.unite,
        mesureAt: mesureAt ?? this.mesureAt,
        source: source ?? this.source,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        serverVersion: serverVersion ?? this.serverVersion,
      );
  ConstanteSnapshot copyWithCompanion(ConstanteSnapshotsCompanion data) {
    return ConstanteSnapshot(
      id: data.id.present ? data.id.value : this.id,
      typeCode: data.typeCode.present ? data.typeCode.value : this.typeCode,
      valeurJson:
          data.valeurJson.present ? data.valeurJson.value : this.valeurJson,
      unite: data.unite.present ? data.unite.value : this.unite,
      mesureAt: data.mesureAt.present ? data.mesureAt.value : this.mesureAt,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConstanteSnapshot(')
          ..write('id: $id, ')
          ..write('typeCode: $typeCode, ')
          ..write('valeurJson: $valeurJson, ')
          ..write('unite: $unite, ')
          ..write('mesureAt: $mesureAt, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverVersion: $serverVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, typeCode, valeurJson, unite, mesureAt,
      source, createdAt, serverVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConstanteSnapshot &&
          other.id == this.id &&
          other.typeCode == this.typeCode &&
          other.valeurJson == this.valeurJson &&
          other.unite == this.unite &&
          other.mesureAt == this.mesureAt &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.serverVersion == this.serverVersion);
}

class ConstanteSnapshotsCompanion extends UpdateCompanion<ConstanteSnapshot> {
  final Value<String> id;
  final Value<String> typeCode;
  final Value<String> valeurJson;
  final Value<String> unite;
  final Value<DateTime> mesureAt;
  final Value<String> source;
  final Value<DateTime?> createdAt;
  final Value<int> serverVersion;
  final Value<int> rowid;
  const ConstanteSnapshotsCompanion({
    this.id = const Value.absent(),
    this.typeCode = const Value.absent(),
    this.valeurJson = const Value.absent(),
    this.unite = const Value.absent(),
    this.mesureAt = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConstanteSnapshotsCompanion.insert({
    required String id,
    required String typeCode,
    required String valeurJson,
    required String unite,
    required DateTime mesureAt,
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        typeCode = Value(typeCode),
        valeurJson = Value(valeurJson),
        unite = Value(unite),
        mesureAt = Value(mesureAt);
  static Insertable<ConstanteSnapshot> custom({
    Expression<String>? id,
    Expression<String>? typeCode,
    Expression<String>? valeurJson,
    Expression<String>? unite,
    Expression<DateTime>? mesureAt,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? serverVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (typeCode != null) 'type_code': typeCode,
      if (valeurJson != null) 'valeur_json': valeurJson,
      if (unite != null) 'unite': unite,
      if (mesureAt != null) 'mesure_at': mesureAt,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (serverVersion != null) 'server_version': serverVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConstanteSnapshotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? typeCode,
      Value<String>? valeurJson,
      Value<String>? unite,
      Value<DateTime>? mesureAt,
      Value<String>? source,
      Value<DateTime?>? createdAt,
      Value<int>? serverVersion,
      Value<int>? rowid}) {
    return ConstanteSnapshotsCompanion(
      id: id ?? this.id,
      typeCode: typeCode ?? this.typeCode,
      valeurJson: valeurJson ?? this.valeurJson,
      unite: unite ?? this.unite,
      mesureAt: mesureAt ?? this.mesureAt,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      serverVersion: serverVersion ?? this.serverVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (typeCode.present) {
      map['type_code'] = Variable<String>(typeCode.value);
    }
    if (valeurJson.present) {
      map['valeur_json'] = Variable<String>(valeurJson.value);
    }
    if (unite.present) {
      map['unite'] = Variable<String>(unite.value);
    }
    if (mesureAt.present) {
      map['mesure_at'] = Variable<DateTime>(mesureAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConstanteSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('typeCode: $typeCode, ')
          ..write('valeurJson: $valeurJson, ')
          ..write('unite: $unite, ')
          ..write('mesureAt: $mesureAt, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckInSnapshotsTable extends CheckInSnapshots
    with TableInfo<$CheckInSnapshotsTable, CheckInSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateKeyMeta =
      const VerificationMeta('dateKey');
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
      'date_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
      'statut', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, dateKey, statut, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_in_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<CheckInSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date_key')) {
      context.handle(_dateKeyMeta,
          dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta));
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(_statutMeta,
          statut.isAcceptableOrUnknown(data['statut']!, _statutMeta));
    } else if (isInserting) {
      context.missing(_statutMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckInSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckInSnapshot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      dateKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_key'])!,
      statut: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}statut'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $CheckInSnapshotsTable createAlias(String alias) {
    return $CheckInSnapshotsTable(attachedDatabase, alias);
  }
}

class CheckInSnapshot extends DataClass implements Insertable<CheckInSnapshot> {
  final String id;
  final String dateKey;
  final String statut;
  final DateTime? createdAt;
  const CheckInSnapshot(
      {required this.id,
      required this.dateKey,
      required this.statut,
      this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date_key'] = Variable<String>(dateKey);
    map['statut'] = Variable<String>(statut);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  CheckInSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return CheckInSnapshotsCompanion(
      id: Value(id),
      dateKey: Value(dateKey),
      statut: Value(statut),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory CheckInSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckInSnapshot(
      id: serializer.fromJson<String>(json['id']),
      dateKey: serializer.fromJson<String>(json['dateKey']),
      statut: serializer.fromJson<String>(json['statut']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dateKey': serializer.toJson<String>(dateKey),
      'statut': serializer.toJson<String>(statut),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  CheckInSnapshot copyWith(
          {String? id,
          String? dateKey,
          String? statut,
          Value<DateTime?> createdAt = const Value.absent()}) =>
      CheckInSnapshot(
        id: id ?? this.id,
        dateKey: dateKey ?? this.dateKey,
        statut: statut ?? this.statut,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
      );
  CheckInSnapshot copyWithCompanion(CheckInSnapshotsCompanion data) {
    return CheckInSnapshot(
      id: data.id.present ? data.id.value : this.id,
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      statut: data.statut.present ? data.statut.value : this.statut,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckInSnapshot(')
          ..write('id: $id, ')
          ..write('dateKey: $dateKey, ')
          ..write('statut: $statut, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dateKey, statut, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckInSnapshot &&
          other.id == this.id &&
          other.dateKey == this.dateKey &&
          other.statut == this.statut &&
          other.createdAt == this.createdAt);
}

class CheckInSnapshotsCompanion extends UpdateCompanion<CheckInSnapshot> {
  final Value<String> id;
  final Value<String> dateKey;
  final Value<String> statut;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const CheckInSnapshotsCompanion({
    this.id = const Value.absent(),
    this.dateKey = const Value.absent(),
    this.statut = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckInSnapshotsCompanion.insert({
    required String id,
    required String dateKey,
    required String statut,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        dateKey = Value(dateKey),
        statut = Value(statut);
  static Insertable<CheckInSnapshot> custom({
    Expression<String>? id,
    Expression<String>? dateKey,
    Expression<String>? statut,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dateKey != null) 'date_key': dateKey,
      if (statut != null) 'statut': statut,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckInSnapshotsCompanion copyWith(
      {Value<String>? id,
      Value<String>? dateKey,
      Value<String>? statut,
      Value<DateTime?>? createdAt,
      Value<int>? rowid}) {
    return CheckInSnapshotsCompanion(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('dateKey: $dateKey, ')
          ..write('statut: $statut, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PriseSnapshotsTable priseSnapshots = $PriseSnapshotsTable(this);
  late final $TraitementMirrorsTable traitementMirrors =
      $TraitementMirrorsTable(this);
  late final $SyncOutboxEntriesTable syncOutboxEntries =
      $SyncOutboxEntriesTable(this);
  late final $DashboardSnapshotsTable dashboardSnapshots =
      $DashboardSnapshotsTable(this);
  late final $ConstanteSnapshotsTable constanteSnapshots =
      $ConstanteSnapshotsTable(this);
  late final $CheckInSnapshotsTable checkInSnapshots =
      $CheckInSnapshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        priseSnapshots,
        traitementMirrors,
        syncOutboxEntries,
        dashboardSnapshots,
        constanteSnapshots,
        checkInSnapshots
      ];
}

typedef $$PriseSnapshotsTableCreateCompanionBuilder = PriseSnapshotsCompanion
    Function({
  required String id,
  required String dateKey,
  required DateTime heurePrevue,
  required String statut,
  Value<String> medicamentNom,
  Value<String> dosage,
  Value<DateTime?> updatedAt,
  Value<int> serverVersion,
  Value<String?> payloadJson,
  Value<int> rowid,
});
typedef $$PriseSnapshotsTableUpdateCompanionBuilder = PriseSnapshotsCompanion
    Function({
  Value<String> id,
  Value<String> dateKey,
  Value<DateTime> heurePrevue,
  Value<String> statut,
  Value<String> medicamentNom,
  Value<String> dosage,
  Value<DateTime?> updatedAt,
  Value<int> serverVersion,
  Value<String?> payloadJson,
  Value<int> rowid,
});

class $$PriseSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $PriseSnapshotsTable> {
  $$PriseSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateKey => $composableBuilder(
      column: $table.dateKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get heurePrevue => $composableBuilder(
      column: $table.heurePrevue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statut => $composableBuilder(
      column: $table.statut, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get medicamentNom => $composableBuilder(
      column: $table.medicamentNom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dosage => $composableBuilder(
      column: $table.dosage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));
}

class $$PriseSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PriseSnapshotsTable> {
  $$PriseSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateKey => $composableBuilder(
      column: $table.dateKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get heurePrevue => $composableBuilder(
      column: $table.heurePrevue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statut => $composableBuilder(
      column: $table.statut, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get medicamentNom => $composableBuilder(
      column: $table.medicamentNom,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dosage => $composableBuilder(
      column: $table.dosage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));
}

class $$PriseSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriseSnapshotsTable> {
  $$PriseSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<DateTime> get heurePrevue => $composableBuilder(
      column: $table.heurePrevue, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<String> get medicamentNom => $composableBuilder(
      column: $table.medicamentNom, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);
}

class $$PriseSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PriseSnapshotsTable,
    PriseSnapshot,
    $$PriseSnapshotsTableFilterComposer,
    $$PriseSnapshotsTableOrderingComposer,
    $$PriseSnapshotsTableAnnotationComposer,
    $$PriseSnapshotsTableCreateCompanionBuilder,
    $$PriseSnapshotsTableUpdateCompanionBuilder,
    (
      PriseSnapshot,
      BaseReferences<_$AppDatabase, $PriseSnapshotsTable, PriseSnapshot>
    ),
    PriseSnapshot,
    PrefetchHooks Function()> {
  $$PriseSnapshotsTableTableManager(
      _$AppDatabase db, $PriseSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriseSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriseSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriseSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> dateKey = const Value.absent(),
            Value<DateTime> heurePrevue = const Value.absent(),
            Value<String> statut = const Value.absent(),
            Value<String> medicamentNom = const Value.absent(),
            Value<String> dosage = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> serverVersion = const Value.absent(),
            Value<String?> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PriseSnapshotsCompanion(
            id: id,
            dateKey: dateKey,
            heurePrevue: heurePrevue,
            statut: statut,
            medicamentNom: medicamentNom,
            dosage: dosage,
            updatedAt: updatedAt,
            serverVersion: serverVersion,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String dateKey,
            required DateTime heurePrevue,
            required String statut,
            Value<String> medicamentNom = const Value.absent(),
            Value<String> dosage = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> serverVersion = const Value.absent(),
            Value<String?> payloadJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PriseSnapshotsCompanion.insert(
            id: id,
            dateKey: dateKey,
            heurePrevue: heurePrevue,
            statut: statut,
            medicamentNom: medicamentNom,
            dosage: dosage,
            updatedAt: updatedAt,
            serverVersion: serverVersion,
            payloadJson: payloadJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PriseSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PriseSnapshotsTable,
    PriseSnapshot,
    $$PriseSnapshotsTableFilterComposer,
    $$PriseSnapshotsTableOrderingComposer,
    $$PriseSnapshotsTableAnnotationComposer,
    $$PriseSnapshotsTableCreateCompanionBuilder,
    $$PriseSnapshotsTableUpdateCompanionBuilder,
    (
      PriseSnapshot,
      BaseReferences<_$AppDatabase, $PriseSnapshotsTable, PriseSnapshot>
    ),
    PriseSnapshot,
    PrefetchHooks Function()>;
typedef $$TraitementMirrorsTableCreateCompanionBuilder
    = TraitementMirrorsCompanion Function({
  required String id,
  required String payloadJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TraitementMirrorsTableUpdateCompanionBuilder
    = TraitementMirrorsCompanion Function({
  Value<String> id,
  Value<String> payloadJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TraitementMirrorsTableFilterComposer
    extends Composer<_$AppDatabase, $TraitementMirrorsTable> {
  $$TraitementMirrorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TraitementMirrorsTableOrderingComposer
    extends Composer<_$AppDatabase, $TraitementMirrorsTable> {
  $$TraitementMirrorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TraitementMirrorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TraitementMirrorsTable> {
  $$TraitementMirrorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TraitementMirrorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TraitementMirrorsTable,
    TraitementMirror,
    $$TraitementMirrorsTableFilterComposer,
    $$TraitementMirrorsTableOrderingComposer,
    $$TraitementMirrorsTableAnnotationComposer,
    $$TraitementMirrorsTableCreateCompanionBuilder,
    $$TraitementMirrorsTableUpdateCompanionBuilder,
    (
      TraitementMirror,
      BaseReferences<_$AppDatabase, $TraitementMirrorsTable, TraitementMirror>
    ),
    TraitementMirror,
    PrefetchHooks Function()> {
  $$TraitementMirrorsTableTableManager(
      _$AppDatabase db, $TraitementMirrorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TraitementMirrorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TraitementMirrorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TraitementMirrorsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TraitementMirrorsCompanion(
            id: id,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String payloadJson,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TraitementMirrorsCompanion.insert(
            id: id,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TraitementMirrorsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TraitementMirrorsTable,
    TraitementMirror,
    $$TraitementMirrorsTableFilterComposer,
    $$TraitementMirrorsTableOrderingComposer,
    $$TraitementMirrorsTableAnnotationComposer,
    $$TraitementMirrorsTableCreateCompanionBuilder,
    $$TraitementMirrorsTableUpdateCompanionBuilder,
    (
      TraitementMirror,
      BaseReferences<_$AppDatabase, $TraitementMirrorsTable, TraitementMirror>
    ),
    TraitementMirror,
    PrefetchHooks Function()>;
typedef $$SyncOutboxEntriesTableCreateCompanionBuilder
    = SyncOutboxEntriesCompanion Function({
  required String mutationId,
  required String entity,
  required String entityId,
  required String op,
  required String payloadJson,
  required DateTime clientTs,
  Value<int> attempts,
  required DateTime nextAttemptAt,
  required String state,
  required int sortIndex,
  Value<int> rowid,
});
typedef $$SyncOutboxEntriesTableUpdateCompanionBuilder
    = SyncOutboxEntriesCompanion Function({
  Value<String> mutationId,
  Value<String> entity,
  Value<String> entityId,
  Value<String> op,
  Value<String> payloadJson,
  Value<DateTime> clientTs,
  Value<int> attempts,
  Value<DateTime> nextAttemptAt,
  Value<String> state,
  Value<int> sortIndex,
  Value<int> rowid,
});

class $$SyncOutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get clientTs => $composableBuilder(
      column: $table.clientTs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnFilters(column));
}

class $$SyncOutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get clientTs => $composableBuilder(
      column: $table.clientTs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortIndex => $composableBuilder(
      column: $table.sortIndex, builder: (column) => ColumnOrderings(column));
}

class $$SyncOutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get clientTs =>
      $composableBuilder(column: $table.clientTs, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);
}

class $$SyncOutboxEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncOutboxEntriesTable,
    OutboxRow,
    $$SyncOutboxEntriesTableFilterComposer,
    $$SyncOutboxEntriesTableOrderingComposer,
    $$SyncOutboxEntriesTableAnnotationComposer,
    $$SyncOutboxEntriesTableCreateCompanionBuilder,
    $$SyncOutboxEntriesTableUpdateCompanionBuilder,
    (
      OutboxRow,
      BaseReferences<_$AppDatabase, $SyncOutboxEntriesTable, OutboxRow>
    ),
    OutboxRow,
    PrefetchHooks Function()> {
  $$SyncOutboxEntriesTableTableManager(
      _$AppDatabase db, $SyncOutboxEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mutationId = const Value.absent(),
            Value<String> entity = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> op = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> clientTs = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime> nextAttemptAt = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<int> sortIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncOutboxEntriesCompanion(
            mutationId: mutationId,
            entity: entity,
            entityId: entityId,
            op: op,
            payloadJson: payloadJson,
            clientTs: clientTs,
            attempts: attempts,
            nextAttemptAt: nextAttemptAt,
            state: state,
            sortIndex: sortIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mutationId,
            required String entity,
            required String entityId,
            required String op,
            required String payloadJson,
            required DateTime clientTs,
            Value<int> attempts = const Value.absent(),
            required DateTime nextAttemptAt,
            required String state,
            required int sortIndex,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncOutboxEntriesCompanion.insert(
            mutationId: mutationId,
            entity: entity,
            entityId: entityId,
            op: op,
            payloadJson: payloadJson,
            clientTs: clientTs,
            attempts: attempts,
            nextAttemptAt: nextAttemptAt,
            state: state,
            sortIndex: sortIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncOutboxEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncOutboxEntriesTable,
    OutboxRow,
    $$SyncOutboxEntriesTableFilterComposer,
    $$SyncOutboxEntriesTableOrderingComposer,
    $$SyncOutboxEntriesTableAnnotationComposer,
    $$SyncOutboxEntriesTableCreateCompanionBuilder,
    $$SyncOutboxEntriesTableUpdateCompanionBuilder,
    (
      OutboxRow,
      BaseReferences<_$AppDatabase, $SyncOutboxEntriesTable, OutboxRow>
    ),
    OutboxRow,
    PrefetchHooks Function()>;
typedef $$DashboardSnapshotsTableCreateCompanionBuilder
    = DashboardSnapshotsCompanion Function({
  Value<int> id,
  required String prochaineAction,
  required bool medicamentsConfigures,
  required bool notificationsAccordees,
  required String traitementsJson,
  required DateTime updatedAt,
});
typedef $$DashboardSnapshotsTableUpdateCompanionBuilder
    = DashboardSnapshotsCompanion Function({
  Value<int> id,
  Value<String> prochaineAction,
  Value<bool> medicamentsConfigures,
  Value<bool> notificationsAccordees,
  Value<String> traitementsJson,
  Value<DateTime> updatedAt,
});

class $$DashboardSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $DashboardSnapshotsTable> {
  $$DashboardSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prochaineAction => $composableBuilder(
      column: $table.prochaineAction,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get medicamentsConfigures => $composableBuilder(
      column: $table.medicamentsConfigures,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notificationsAccordees => $composableBuilder(
      column: $table.notificationsAccordees,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get traitementsJson => $composableBuilder(
      column: $table.traitementsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DashboardSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $DashboardSnapshotsTable> {
  $$DashboardSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prochaineAction => $composableBuilder(
      column: $table.prochaineAction,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get medicamentsConfigures => $composableBuilder(
      column: $table.medicamentsConfigures,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notificationsAccordees => $composableBuilder(
      column: $table.notificationsAccordees,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get traitementsJson => $composableBuilder(
      column: $table.traitementsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DashboardSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DashboardSnapshotsTable> {
  $$DashboardSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prochaineAction => $composableBuilder(
      column: $table.prochaineAction, builder: (column) => column);

  GeneratedColumn<bool> get medicamentsConfigures => $composableBuilder(
      column: $table.medicamentsConfigures, builder: (column) => column);

  GeneratedColumn<bool> get notificationsAccordees => $composableBuilder(
      column: $table.notificationsAccordees, builder: (column) => column);

  GeneratedColumn<String> get traitementsJson => $composableBuilder(
      column: $table.traitementsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DashboardSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DashboardSnapshotsTable,
    DashboardSnapshot,
    $$DashboardSnapshotsTableFilterComposer,
    $$DashboardSnapshotsTableOrderingComposer,
    $$DashboardSnapshotsTableAnnotationComposer,
    $$DashboardSnapshotsTableCreateCompanionBuilder,
    $$DashboardSnapshotsTableUpdateCompanionBuilder,
    (
      DashboardSnapshot,
      BaseReferences<_$AppDatabase, $DashboardSnapshotsTable, DashboardSnapshot>
    ),
    DashboardSnapshot,
    PrefetchHooks Function()> {
  $$DashboardSnapshotsTableTableManager(
      _$AppDatabase db, $DashboardSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardSnapshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> prochaineAction = const Value.absent(),
            Value<bool> medicamentsConfigures = const Value.absent(),
            Value<bool> notificationsAccordees = const Value.absent(),
            Value<String> traitementsJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DashboardSnapshotsCompanion(
            id: id,
            prochaineAction: prochaineAction,
            medicamentsConfigures: medicamentsConfigures,
            notificationsAccordees: notificationsAccordees,
            traitementsJson: traitementsJson,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String prochaineAction,
            required bool medicamentsConfigures,
            required bool notificationsAccordees,
            required String traitementsJson,
            required DateTime updatedAt,
          }) =>
              DashboardSnapshotsCompanion.insert(
            id: id,
            prochaineAction: prochaineAction,
            medicamentsConfigures: medicamentsConfigures,
            notificationsAccordees: notificationsAccordees,
            traitementsJson: traitementsJson,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DashboardSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DashboardSnapshotsTable,
    DashboardSnapshot,
    $$DashboardSnapshotsTableFilterComposer,
    $$DashboardSnapshotsTableOrderingComposer,
    $$DashboardSnapshotsTableAnnotationComposer,
    $$DashboardSnapshotsTableCreateCompanionBuilder,
    $$DashboardSnapshotsTableUpdateCompanionBuilder,
    (
      DashboardSnapshot,
      BaseReferences<_$AppDatabase, $DashboardSnapshotsTable, DashboardSnapshot>
    ),
    DashboardSnapshot,
    PrefetchHooks Function()>;
typedef $$ConstanteSnapshotsTableCreateCompanionBuilder
    = ConstanteSnapshotsCompanion Function({
  required String id,
  required String typeCode,
  required String valeurJson,
  required String unite,
  required DateTime mesureAt,
  Value<String> source,
  Value<DateTime?> createdAt,
  Value<int> serverVersion,
  Value<int> rowid,
});
typedef $$ConstanteSnapshotsTableUpdateCompanionBuilder
    = ConstanteSnapshotsCompanion Function({
  Value<String> id,
  Value<String> typeCode,
  Value<String> valeurJson,
  Value<String> unite,
  Value<DateTime> mesureAt,
  Value<String> source,
  Value<DateTime?> createdAt,
  Value<int> serverVersion,
  Value<int> rowid,
});

class $$ConstanteSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ConstanteSnapshotsTable> {
  $$ConstanteSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get typeCode => $composableBuilder(
      column: $table.typeCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valeurJson => $composableBuilder(
      column: $table.valeurJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unite => $composableBuilder(
      column: $table.unite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get mesureAt => $composableBuilder(
      column: $table.mesureAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => ColumnFilters(column));
}

class $$ConstanteSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConstanteSnapshotsTable> {
  $$ConstanteSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get typeCode => $composableBuilder(
      column: $table.typeCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valeurJson => $composableBuilder(
      column: $table.valeurJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unite => $composableBuilder(
      column: $table.unite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get mesureAt => $composableBuilder(
      column: $table.mesureAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$ConstanteSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConstanteSnapshotsTable> {
  $$ConstanteSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get typeCode =>
      $composableBuilder(column: $table.typeCode, builder: (column) => column);

  GeneratedColumn<String> get valeurJson => $composableBuilder(
      column: $table.valeurJson, builder: (column) => column);

  GeneratedColumn<String> get unite =>
      $composableBuilder(column: $table.unite, builder: (column) => column);

  GeneratedColumn<DateTime> get mesureAt =>
      $composableBuilder(column: $table.mesureAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => column);
}

class $$ConstanteSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConstanteSnapshotsTable,
    ConstanteSnapshot,
    $$ConstanteSnapshotsTableFilterComposer,
    $$ConstanteSnapshotsTableOrderingComposer,
    $$ConstanteSnapshotsTableAnnotationComposer,
    $$ConstanteSnapshotsTableCreateCompanionBuilder,
    $$ConstanteSnapshotsTableUpdateCompanionBuilder,
    (
      ConstanteSnapshot,
      BaseReferences<_$AppDatabase, $ConstanteSnapshotsTable, ConstanteSnapshot>
    ),
    ConstanteSnapshot,
    PrefetchHooks Function()> {
  $$ConstanteSnapshotsTableTableManager(
      _$AppDatabase db, $ConstanteSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConstanteSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConstanteSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConstanteSnapshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> typeCode = const Value.absent(),
            Value<String> valeurJson = const Value.absent(),
            Value<String> unite = const Value.absent(),
            Value<DateTime> mesureAt = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> serverVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConstanteSnapshotsCompanion(
            id: id,
            typeCode: typeCode,
            valeurJson: valeurJson,
            unite: unite,
            mesureAt: mesureAt,
            source: source,
            createdAt: createdAt,
            serverVersion: serverVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String typeCode,
            required String valeurJson,
            required String unite,
            required DateTime mesureAt,
            Value<String> source = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> serverVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConstanteSnapshotsCompanion.insert(
            id: id,
            typeCode: typeCode,
            valeurJson: valeurJson,
            unite: unite,
            mesureAt: mesureAt,
            source: source,
            createdAt: createdAt,
            serverVersion: serverVersion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConstanteSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConstanteSnapshotsTable,
    ConstanteSnapshot,
    $$ConstanteSnapshotsTableFilterComposer,
    $$ConstanteSnapshotsTableOrderingComposer,
    $$ConstanteSnapshotsTableAnnotationComposer,
    $$ConstanteSnapshotsTableCreateCompanionBuilder,
    $$ConstanteSnapshotsTableUpdateCompanionBuilder,
    (
      ConstanteSnapshot,
      BaseReferences<_$AppDatabase, $ConstanteSnapshotsTable, ConstanteSnapshot>
    ),
    ConstanteSnapshot,
    PrefetchHooks Function()>;
typedef $$CheckInSnapshotsTableCreateCompanionBuilder
    = CheckInSnapshotsCompanion Function({
  required String id,
  required String dateKey,
  required String statut,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$CheckInSnapshotsTableUpdateCompanionBuilder
    = CheckInSnapshotsCompanion Function({
  Value<String> id,
  Value<String> dateKey,
  Value<String> statut,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

class $$CheckInSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckInSnapshotsTable> {
  $$CheckInSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateKey => $composableBuilder(
      column: $table.dateKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statut => $composableBuilder(
      column: $table.statut, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CheckInSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckInSnapshotsTable> {
  $$CheckInSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateKey => $composableBuilder(
      column: $table.dateKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statut => $composableBuilder(
      column: $table.statut, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CheckInSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckInSnapshotsTable> {
  $$CheckInSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CheckInSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CheckInSnapshotsTable,
    CheckInSnapshot,
    $$CheckInSnapshotsTableFilterComposer,
    $$CheckInSnapshotsTableOrderingComposer,
    $$CheckInSnapshotsTableAnnotationComposer,
    $$CheckInSnapshotsTableCreateCompanionBuilder,
    $$CheckInSnapshotsTableUpdateCompanionBuilder,
    (
      CheckInSnapshot,
      BaseReferences<_$AppDatabase, $CheckInSnapshotsTable, CheckInSnapshot>
    ),
    CheckInSnapshot,
    PrefetchHooks Function()> {
  $$CheckInSnapshotsTableTableManager(
      _$AppDatabase db, $CheckInSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> dateKey = const Value.absent(),
            Value<String> statut = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CheckInSnapshotsCompanion(
            id: id,
            dateKey: dateKey,
            statut: statut,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String dateKey,
            required String statut,
            Value<DateTime?> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CheckInSnapshotsCompanion.insert(
            id: id,
            dateKey: dateKey,
            statut: statut,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CheckInSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CheckInSnapshotsTable,
    CheckInSnapshot,
    $$CheckInSnapshotsTableFilterComposer,
    $$CheckInSnapshotsTableOrderingComposer,
    $$CheckInSnapshotsTableAnnotationComposer,
    $$CheckInSnapshotsTableCreateCompanionBuilder,
    $$CheckInSnapshotsTableUpdateCompanionBuilder,
    (
      CheckInSnapshot,
      BaseReferences<_$AppDatabase, $CheckInSnapshotsTable, CheckInSnapshot>
    ),
    CheckInSnapshot,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PriseSnapshotsTableTableManager get priseSnapshots =>
      $$PriseSnapshotsTableTableManager(_db, _db.priseSnapshots);
  $$TraitementMirrorsTableTableManager get traitementMirrors =>
      $$TraitementMirrorsTableTableManager(_db, _db.traitementMirrors);
  $$SyncOutboxEntriesTableTableManager get syncOutboxEntries =>
      $$SyncOutboxEntriesTableTableManager(_db, _db.syncOutboxEntries);
  $$DashboardSnapshotsTableTableManager get dashboardSnapshots =>
      $$DashboardSnapshotsTableTableManager(_db, _db.dashboardSnapshots);
  $$ConstanteSnapshotsTableTableManager get constanteSnapshots =>
      $$ConstanteSnapshotsTableTableManager(_db, _db.constanteSnapshots);
  $$CheckInSnapshotsTableTableManager get checkInSnapshots =>
      $$CheckInSnapshotsTableTableManager(_db, _db.checkInSnapshots);
}

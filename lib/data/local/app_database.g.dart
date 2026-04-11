// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
mixin _$ReplyLightRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReplyLightRecordsTable get replyLightRecords =>
      attachedDatabase.replyLightRecords;
  ReplyLightRecordDaoManager get managers => ReplyLightRecordDaoManager(this);
}

class ReplyLightRecordDaoManager {
  final _$ReplyLightRecordDaoMixin _db;
  ReplyLightRecordDaoManager(this._db);
  $$ReplyLightRecordsTableTableManager get replyLightRecords =>
      $$ReplyLightRecordsTableTableManager(
        _db.attachedDatabase,
        _db.replyLightRecords,
      );
}

class $ReplyLightRecordsTable extends ReplyLightRecords
    with TableInfo<$ReplyLightRecordsTable, ReplyLightRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReplyLightRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _actorKeyMeta = const VerificationMeta(
    'actorKey',
  );
  @override
  late final GeneratedColumn<String> actorKey = GeneratedColumn<String>(
    'actor_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tidMeta = const VerificationMeta('tid');
  @override
  late final GeneratedColumn<String> tid = GeneratedColumn<String>(
    'tid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pidMeta = const VerificationMeta('pid');
  @override
  late final GeneratedColumn<String> pid = GeneratedColumn<String>(
    'pid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actorKey,
    tid,
    pid,
    createdAtMs,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reply_light_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplyLightRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('actor_key')) {
      context.handle(
        _actorKeyMeta,
        actorKey.isAcceptableOrUnknown(data['actor_key']!, _actorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_actorKeyMeta);
    }
    if (data.containsKey('tid')) {
      context.handle(
        _tidMeta,
        tid.isAcceptableOrUnknown(data['tid']!, _tidMeta),
      );
    } else if (isInserting) {
      context.missing(_tidMeta);
    }
    if (data.containsKey('pid')) {
      context.handle(
        _pidMeta,
        pid.isAcceptableOrUnknown(data['pid']!, _pidMeta),
      );
    } else if (isInserting) {
      context.missing(_pidMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {actorKey, tid, pid},
  ];
  @override
  ReplyLightRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplyLightRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      actorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_key'],
      )!,
      tid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tid'],
      )!,
      pid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pid'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $ReplyLightRecordsTable createAlias(String alias) {
    return $ReplyLightRecordsTable(attachedDatabase, alias);
  }
}

class ReplyLightRecord extends DataClass
    implements Insertable<ReplyLightRecord> {
  final int id;
  final String actorKey;
  final String tid;
  final String pid;
  final int createdAtMs;
  final int updatedAtMs;
  const ReplyLightRecord({
    required this.id,
    required this.actorKey,
    required this.tid,
    required this.pid,
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['actor_key'] = Variable<String>(actorKey);
    map['tid'] = Variable<String>(tid);
    map['pid'] = Variable<String>(pid);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  ReplyLightRecordsCompanion toCompanion(bool nullToAbsent) {
    return ReplyLightRecordsCompanion(
      id: Value(id),
      actorKey: Value(actorKey),
      tid: Value(tid),
      pid: Value(pid),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory ReplyLightRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplyLightRecord(
      id: serializer.fromJson<int>(json['id']),
      actorKey: serializer.fromJson<String>(json['actorKey']),
      tid: serializer.fromJson<String>(json['tid']),
      pid: serializer.fromJson<String>(json['pid']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actorKey': serializer.toJson<String>(actorKey),
      'tid': serializer.toJson<String>(tid),
      'pid': serializer.toJson<String>(pid),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  ReplyLightRecord copyWith({
    int? id,
    String? actorKey,
    String? tid,
    String? pid,
    int? createdAtMs,
    int? updatedAtMs,
  }) => ReplyLightRecord(
    id: id ?? this.id,
    actorKey: actorKey ?? this.actorKey,
    tid: tid ?? this.tid,
    pid: pid ?? this.pid,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  ReplyLightRecord copyWithCompanion(ReplyLightRecordsCompanion data) {
    return ReplyLightRecord(
      id: data.id.present ? data.id.value : this.id,
      actorKey: data.actorKey.present ? data.actorKey.value : this.actorKey,
      tid: data.tid.present ? data.tid.value : this.tid,
      pid: data.pid.present ? data.pid.value : this.pid,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplyLightRecord(')
          ..write('id: $id, ')
          ..write('actorKey: $actorKey, ')
          ..write('tid: $tid, ')
          ..write('pid: $pid, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, actorKey, tid, pid, createdAtMs, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplyLightRecord &&
          other.id == this.id &&
          other.actorKey == this.actorKey &&
          other.tid == this.tid &&
          other.pid == this.pid &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs);
}

class ReplyLightRecordsCompanion extends UpdateCompanion<ReplyLightRecord> {
  final Value<int> id;
  final Value<String> actorKey;
  final Value<String> tid;
  final Value<String> pid;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  const ReplyLightRecordsCompanion({
    this.id = const Value.absent(),
    this.actorKey = const Value.absent(),
    this.tid = const Value.absent(),
    this.pid = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  });
  ReplyLightRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String actorKey,
    required String tid,
    required String pid,
    required int createdAtMs,
    required int updatedAtMs,
  }) : actorKey = Value(actorKey),
       tid = Value(tid),
       pid = Value(pid),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<ReplyLightRecord> custom({
    Expression<int>? id,
    Expression<String>? actorKey,
    Expression<String>? tid,
    Expression<String>? pid,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actorKey != null) 'actor_key': actorKey,
      if (tid != null) 'tid': tid,
      if (pid != null) 'pid': pid,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
    });
  }

  ReplyLightRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? actorKey,
    Value<String>? tid,
    Value<String>? pid,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
  }) {
    return ReplyLightRecordsCompanion(
      id: id ?? this.id,
      actorKey: actorKey ?? this.actorKey,
      tid: tid ?? this.tid,
      pid: pid ?? this.pid,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (actorKey.present) {
      map['actor_key'] = Variable<String>(actorKey.value);
    }
    if (tid.present) {
      map['tid'] = Variable<String>(tid.value);
    }
    if (pid.present) {
      map['pid'] = Variable<String>(pid.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReplyLightRecordsCompanion(')
          ..write('id: $id, ')
          ..write('actorKey: $actorKey, ')
          ..write('tid: $tid, ')
          ..write('pid: $pid, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReplyLightRecordsTable replyLightRecords =
      $ReplyLightRecordsTable(this);
  late final ReplyLightRecordDao replyLightRecordDao = ReplyLightRecordDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [replyLightRecords];
}

typedef $$ReplyLightRecordsTableCreateCompanionBuilder =
    ReplyLightRecordsCompanion Function({
      Value<int> id,
      required String actorKey,
      required String tid,
      required String pid,
      required int createdAtMs,
      required int updatedAtMs,
    });
typedef $$ReplyLightRecordsTableUpdateCompanionBuilder =
    ReplyLightRecordsCompanion Function({
      Value<int> id,
      Value<String> actorKey,
      Value<String> tid,
      Value<String> pid,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
    });

class $$ReplyLightRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ReplyLightRecordsTable> {
  $$ReplyLightRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorKey => $composableBuilder(
    column: $table.actorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tid => $composableBuilder(
    column: $table.tid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pid => $composableBuilder(
    column: $table.pid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReplyLightRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReplyLightRecordsTable> {
  $$ReplyLightRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorKey => $composableBuilder(
    column: $table.actorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tid => $composableBuilder(
    column: $table.tid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pid => $composableBuilder(
    column: $table.pid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReplyLightRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReplyLightRecordsTable> {
  $$ReplyLightRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actorKey =>
      $composableBuilder(column: $table.actorKey, builder: (column) => column);

  GeneratedColumn<String> get tid =>
      $composableBuilder(column: $table.tid, builder: (column) => column);

  GeneratedColumn<String> get pid =>
      $composableBuilder(column: $table.pid, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$ReplyLightRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReplyLightRecordsTable,
          ReplyLightRecord,
          $$ReplyLightRecordsTableFilterComposer,
          $$ReplyLightRecordsTableOrderingComposer,
          $$ReplyLightRecordsTableAnnotationComposer,
          $$ReplyLightRecordsTableCreateCompanionBuilder,
          $$ReplyLightRecordsTableUpdateCompanionBuilder,
          (
            ReplyLightRecord,
            BaseReferences<
              _$AppDatabase,
              $ReplyLightRecordsTable,
              ReplyLightRecord
            >,
          ),
          ReplyLightRecord,
          PrefetchHooks Function()
        > {
  $$ReplyLightRecordsTableTableManager(
    _$AppDatabase db,
    $ReplyLightRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReplyLightRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReplyLightRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReplyLightRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> actorKey = const Value.absent(),
                Value<String> tid = const Value.absent(),
                Value<String> pid = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
              }) => ReplyLightRecordsCompanion(
                id: id,
                actorKey: actorKey,
                tid: tid,
                pid: pid,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String actorKey,
                required String tid,
                required String pid,
                required int createdAtMs,
                required int updatedAtMs,
              }) => ReplyLightRecordsCompanion.insert(
                id: id,
                actorKey: actorKey,
                tid: tid,
                pid: pid,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReplyLightRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReplyLightRecordsTable,
      ReplyLightRecord,
      $$ReplyLightRecordsTableFilterComposer,
      $$ReplyLightRecordsTableOrderingComposer,
      $$ReplyLightRecordsTableAnnotationComposer,
      $$ReplyLightRecordsTableCreateCompanionBuilder,
      $$ReplyLightRecordsTableUpdateCompanionBuilder,
      (
        ReplyLightRecord,
        BaseReferences<
          _$AppDatabase,
          $ReplyLightRecordsTable,
          ReplyLightRecord
        >,
      ),
      ReplyLightRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReplyLightRecordsTableTableManager get replyLightRecords =>
      $$ReplyLightRecordsTableTableManager(_db, _db.replyLightRecords);
}

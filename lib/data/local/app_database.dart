import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class ReplyLightRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get actorKey => text()();

  TextColumn get tid => text()();

  TextColumn get pid => text()();

  IntColumn get createdAtMs => integer()();

  IntColumn get updatedAtMs => integer()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{actorKey, tid, pid},
  ];
}

@DriftAccessor(tables: [ReplyLightRecords])
class ReplyLightRecordDao extends DatabaseAccessor<AppDatabase>
    with _$ReplyLightRecordDaoMixin {
  ReplyLightRecordDao(super.attachedDatabase);

  Future<void> markLighted({
    required String actorKey,
    required String tid,
    required String pid,
    int? nowEpochMs,
  }) async {
    final normalizedActorKey = actorKey.trim();
    final normalizedTid = tid.trim();
    final normalizedPid = pid.trim();
    if (normalizedActorKey.isEmpty ||
        normalizedTid.isEmpty ||
        normalizedPid.isEmpty) {
      return;
    }

    final now = nowEpochMs ?? DateTime.now().millisecondsSinceEpoch;
    await into(replyLightRecords).insert(
      ReplyLightRecordsCompanion.insert(
        actorKey: normalizedActorKey,
        tid: normalizedTid,
        pid: normalizedPid,
        createdAtMs: now,
        updatedAtMs: now,
      ),
      onConflict: DoUpdate(
        (_) => ReplyLightRecordsCompanion(updatedAtMs: Value(now)),
        target: <Column<Object>>[
          replyLightRecords.actorKey,
          replyLightRecords.tid,
          replyLightRecords.pid,
        ],
      ),
    );
  }

  Future<Set<String>> findLightedPids({
    required String actorKey,
    required String tid,
    required Iterable<String> pids,
  }) async {
    final normalizedPids = _normalizePids(pids);
    if (actorKey.trim().isEmpty ||
        tid.trim().isEmpty ||
        normalizedPids.isEmpty) {
      return const <String>{};
    }

    final query = select(replyLightRecords)
      ..where(
        (table) =>
            table.actorKey.equals(actorKey.trim()) &
            table.tid.equals(tid.trim()) &
            table.pid.isIn(normalizedPids),
      );

    final rows = await query.get();
    return rows.map((row) => row.pid).toSet();
  }

  Future<void> unmarkLighted({
    required String actorKey,
    required String tid,
    required String pid,
  }) async {
    final normalizedActorKey = actorKey.trim();
    final normalizedTid = tid.trim();
    final normalizedPid = pid.trim();
    if (normalizedActorKey.isEmpty ||
        normalizedTid.isEmpty ||
        normalizedPid.isEmpty) {
      return;
    }

    await (delete(replyLightRecords)..where(
          (table) =>
              table.actorKey.equals(normalizedActorKey) &
              table.tid.equals(normalizedTid) &
              table.pid.equals(normalizedPid),
        ))
        .go();
  }

  Stream<Set<String>> watchLightedPids({
    required String actorKey,
    required String tid,
    required Iterable<String> pids,
  }) {
    final normalizedPids = _normalizePids(pids);
    if (actorKey.trim().isEmpty ||
        tid.trim().isEmpty ||
        normalizedPids.isEmpty) {
      return Stream.value(const <String>{});
    }

    final query = select(replyLightRecords)
      ..where(
        (table) =>
            table.actorKey.equals(actorKey.trim()) &
            table.tid.equals(tid.trim()) &
            table.pid.isIn(normalizedPids),
      );

    return query.watch().map((rows) => rows.map((row) => row.pid).toSet());
  }

  List<String> _normalizePids(Iterable<String> pids) {
    return pids
        .map((pid) => pid.trim())
        .where((pid) => pid.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}

@DriftDatabase(tables: [ReplyLightRecords], daos: [ReplyLightRecordDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();
    },
    onUpgrade: (migrator, from, to) async {
      await _createIndexes();
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_reply_light_records_actor_updated '
      'ON reply_light_records (actor_key, updated_at_ms DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_reply_light_records_actor_tid '
      'ON reply_light_records (actor_key, tid)',
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'bluefish_local');
}

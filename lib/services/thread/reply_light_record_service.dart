import 'package:bluefish/data/local/app_database.dart';

class ReplyLightRecordService {
  final ReplyLightRecordDao _dao;

  ReplyLightRecordService({required ReplyLightRecordDao dao}) : _dao = dao;

  Future<void> markLighted({
    required String actorKey,
    required String tid,
    required String pid,
  }) {
    return _dao.markLighted(actorKey: actorKey, tid: tid, pid: pid);
  }

  Future<void> unmarkLighted({
    required String actorKey,
    required String tid,
    required String pid,
  }) {
    return _dao.unmarkLighted(actorKey: actorKey, tid: tid, pid: pid);
  }

  Future<Set<String>> findThreadLightedPids({
    required String? actorKey,
    required String tid,
    required Iterable<String> pids,
  }) async {
    final normalizedActorKey = actorKey?.trim();
    if (normalizedActorKey == null || normalizedActorKey.isEmpty) {
      return const <String>{};
    }

    return _dao.findLightedPids(
      actorKey: normalizedActorKey,
      tid: tid,
      pids: pids,
    );
  }

  Stream<Set<String>> watchThreadLightedPids({
    required String? actorKey,
    required String tid,
    required Iterable<String> pids,
  }) {
    final normalizedActorKey = actorKey?.trim();
    if (normalizedActorKey == null || normalizedActorKey.isEmpty) {
      return Stream.value(const <String>{});
    }

    return _dao.watchLightedPids(
      actorKey: normalizedActorKey,
      tid: tid,
      pids: pids,
    );
  }
}

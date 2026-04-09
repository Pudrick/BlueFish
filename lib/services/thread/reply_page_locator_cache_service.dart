import 'dart:async';
import 'dart:collection';

import 'package:bluefish/userdata/reply_page_locator_cache_store.dart';

class ReplyPageLocatorCacheStats {
  final int totalEntries;
  final int maxEntries;

  const ReplyPageLocatorCacheStats({
    required this.totalEntries,
    required this.maxEntries,
  });
}

class ReplyPageLocatorCacheService {
  static const int defaultMaxEntries = 1024;
  static const Duration _persistDebounceDuration = Duration(milliseconds: 350);

  final ReplyPageLocatorCacheStore _store;
  final LinkedHashMap<String, ReplyPageLocatorCacheEntry> _entries =
      LinkedHashMap<String, ReplyPageLocatorCacheEntry>();

  Future<void>? _initialization;
  Timer? _persistTimer;
  Future<void>? _persisting;
  bool _persistRequestedWhileRunning = false;
  bool _isInitialized = false;
  int _maxEntries;

  ReplyPageLocatorCacheService({
    ReplyPageLocatorCacheStore? store,
    int initialMaxEntries = defaultMaxEntries,
  }) : _store = store ?? ReplyPageLocatorCacheStore(),
       _maxEntries = initialMaxEntries;

  bool get isInitialized => _isInitialized;

  Future<void> ensureInitialized() {
    return _initialization ??= _loadFromStore();
  }

  Future<void> configureMaxEntries(int maxEntries) async {
    await ensureInitialized();
    if (maxEntries == _maxEntries) {
      return;
    }

    _maxEntries = maxEntries;
    _compactToMaxEntries();
    _schedulePersist();
  }

  Future<ReplyPageLocatorCacheEntry?> findExact({
    required String tid,
    required String targetPid,
  }) async {
    await ensureInitialized();

    final cacheKey = _cacheKey(tid, targetPid);
    final existing = _entries[cacheKey];
    if (existing == null) {
      return null;
    }

    final touched = existing.copyWith(
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    _entries.remove(cacheKey);
    _entries[cacheKey] = touched;
    _schedulePersist();
    return touched;
  }

  Future<ReplyPageLocatorCacheEntry?> findNearestInThread({
    required String tid,
    required String targetPid,
  }) async {
    await ensureInitialized();

    final normalizedTid = tid.trim();
    final targetPidNumber = int.tryParse(targetPid.trim());
    if (normalizedTid.isEmpty || targetPidNumber == null) {
      return null;
    }

    ReplyPageLocatorCacheEntry? best;
    int? bestDistance;

    for (final entry in _entries.values) {
      if (entry.tid != normalizedTid) {
        continue;
      }

      final entryPidNumber = int.tryParse(entry.targetPid);
      if (entryPidNumber == null) {
        continue;
      }

      final distance = (entryPidNumber - targetPidNumber).abs();
      if (best == null ||
          distance < bestDistance! ||
          (distance == bestDistance &&
              entry.updatedAtEpochMs > best.updatedAtEpochMs)) {
        best = entry;
        bestDistance = distance;
      }
    }

    if (best == null) {
      return null;
    }

    final key = _cacheKey(best.tid, best.targetPid);
    final existing = _entries[key];
    if (existing == null) {
      return null;
    }

    final touched = existing.copyWith(
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    _entries.remove(key);
    _entries[key] = touched;
    _schedulePersist();
    return touched;
  }

  Future<void> put({
    required String tid,
    required String targetPid,
    required int resolvedPage,
    required String resolutionType,
    String? message,
  }) async {
    await ensureInitialized();

    final normalizedTid = tid.trim();
    final normalizedPid = targetPid.trim();
    if (normalizedTid.isEmpty || normalizedPid.isEmpty || resolvedPage < 1) {
      return;
    }

    final cacheKey = _cacheKey(normalizedTid, normalizedPid);
    _entries.remove(cacheKey);
    while (_entries.length >= _maxEntries) {
      _entries.remove(_entries.keys.first);
    }

    _entries[cacheKey] = ReplyPageLocatorCacheEntry(
      tid: normalizedTid,
      targetPid: normalizedPid,
      resolvedPage: resolvedPage,
      resolutionType: resolutionType,
      message: message,
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    _schedulePersist();
  }

  Future<int> clearBefore(DateTime cutoff) async {
    await ensureInitialized();

    final cutoffEpochMs = cutoff.millisecondsSinceEpoch;
    final keysToDelete = <String>[];

    _entries.forEach((key, value) {
      if (value.updatedAtEpochMs < cutoffEpochMs) {
        keysToDelete.add(key);
      }
    });

    for (final key in keysToDelete) {
      _entries.remove(key);
    }

    await flush();
    return keysToDelete.length;
  }

  Future<void> clearAll() async {
    await ensureInitialized();
    _entries.clear();
    await _store.clear();
  }

  ReplyPageLocatorCacheStats statsSnapshot() {
    return ReplyPageLocatorCacheStats(
      totalEntries: _entries.length,
      maxEntries: _maxEntries,
    );
  }

  Future<void> flush() async {
    await ensureInitialized();
    _persistTimer?.cancel();
    _persistTimer = null;
    await _persistNow();
  }

  Future<void> _loadFromStore() async {
    final loadedEntries = await _store.load();
    _entries.clear();

    for (final entry in loadedEntries) {
      final key = _cacheKey(entry.tid, entry.targetPid);
      _entries.remove(key);
      _entries[key] = entry;
    }

    _compactToMaxEntries();
    _isInitialized = true;
  }

  void _compactToMaxEntries() {
    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounceDuration, () {
      unawaited(_persistNow());
    });
  }

  Future<void> _persistNow() async {
    final currentPersist = _persisting;
    if (currentPersist != null) {
      _persistRequestedWhileRunning = true;
      await currentPersist;
      return;
    }

    final snapshot = _entries.values.toList(growable: false);
    _persisting = _store.save(snapshot);

    try {
      await _persisting;
    } finally {
      _persisting = null;
    }

    if (_persistRequestedWhileRunning) {
      _persistRequestedWhileRunning = false;
      await _persistNow();
    }
  }

  String _cacheKey(String tid, String targetPid) {
    return '${tid.trim()}|${targetPid.trim()}';
  }
}

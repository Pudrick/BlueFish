import 'dart:convert';

import 'package:bluefish/models/thread/thread_recommend_state.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ThreadRecommendStatusSnapshot {
  final ThreadRecommendState state;
  final DateTime updatedAt;

  const ThreadRecommendStatusSnapshot({
    required this.state,
    required this.updatedAt,
  });

  factory ThreadRecommendStatusSnapshot.fromJson(Map<String, dynamic> json) {
    return ThreadRecommendStatusSnapshot(
      state:
          ThreadRecommendState.fromStorage(json['state']?.toString()) ??
          ThreadRecommendState.unknown,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'state': state.storageValue,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class ThreadRecommendStatusStore {
  static const String _storageKey = 'thread_recommend_status_records';

  SharedPreferences? _prefs;
  Future<void>? _initialization;
  final Map<String, ThreadRecommendStatusSnapshot> _records =
      <String, ThreadRecommendStatusSnapshot>{};

  Future<void> ensureInitialized() {
    return _initialization ??= _loadFromPrefs();
  }

  Future<ThreadRecommendStatusSnapshot?> read(String tid) async {
    await ensureInitialized();
    final normalizedTid = tid.trim();
    if (normalizedTid.isEmpty) {
      return null;
    }
    return _records[normalizedTid];
  }

  Future<void> write({
    required String tid,
    required ThreadRecommendState state,
    DateTime? updatedAt,
  }) async {
    await ensureInitialized();

    final normalizedTid = tid.trim();
    if (normalizedTid.isEmpty) {
      return;
    }

    if (state == ThreadRecommendState.checking ||
        state == ThreadRecommendState.unknown) {
      _records.remove(normalizedTid);
      await _persist();
      return;
    }

    _records[normalizedTid] = ThreadRecommendStatusSnapshot(
      state: state,
      updatedAt: updatedAt ?? DateTime.now(),
    );
    await _persist();
  }

  Future<void> clear(String tid) async {
    await ensureInitialized();
    final normalizedTid = tid.trim();
    if (normalizedTid.isEmpty) {
      return;
    }

    if (_records.remove(normalizedTid) == null) {
      return;
    }

    await _persist();
  }

  Future<void> clearAll() async {
    await ensureInitialized();
    if (_records.isEmpty) {
      return;
    }

    _records.clear();
    await _persist();
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final rawValue = _prefs!.getString(_storageKey);

    _records.clear();
    if (rawValue != null && rawValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawValue);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final normalizedTid = entry.key.trim();
            if (normalizedTid.isEmpty || entry.value is! Map) {
              continue;
            }

            final snapshot = ThreadRecommendStatusSnapshot.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            );
            if (!snapshot.state.isKnown) {
              continue;
            }
            _records[normalizedTid] = snapshot;
          }
        }
      } catch (_) {
        _records.clear();
      }
    }
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _storageKey,
      jsonEncode(
        _records.map(
          (tid, snapshot) =>
              MapEntry<String, Map<String, dynamic>>(tid, snapshot.toJson()),
        ),
      ),
    );
  }
}

final ThreadRecommendStatusStore threadRecommendStatusStore =
    ThreadRecommendStatusStore();

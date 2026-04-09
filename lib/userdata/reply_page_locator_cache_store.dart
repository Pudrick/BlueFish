import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ReplyPageLocatorCacheEntry {
  final String tid;
  final String targetPid;
  final int resolvedPage;
  final String resolutionType;
  final String? message;
  final int updatedAtEpochMs;

  const ReplyPageLocatorCacheEntry({
    required this.tid,
    required this.targetPid,
    required this.resolvedPage,
    required this.resolutionType,
    required this.message,
    required this.updatedAtEpochMs,
  });

  ReplyPageLocatorCacheEntry copyWith({
    String? tid,
    String? targetPid,
    int? resolvedPage,
    String? resolutionType,
    Object? message = _unset,
    int? updatedAtEpochMs,
  }) {
    return ReplyPageLocatorCacheEntry(
      tid: tid ?? this.tid,
      targetPid: targetPid ?? this.targetPid,
      resolvedPage: resolvedPage ?? this.resolvedPage,
      resolutionType: resolutionType ?? this.resolutionType,
      message: identical(message, _unset) ? this.message : message as String?,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tid': tid,
      'targetPid': targetPid,
      'resolvedPage': resolvedPage,
      'resolutionType': resolutionType,
      'message': message,
      'updatedAtEpochMs': updatedAtEpochMs,
    };
  }

  static ReplyPageLocatorCacheEntry? fromJson(Object? rawJson) {
    if (rawJson is! Map) {
      return null;
    }

    final json = Map<String, dynamic>.from(rawJson);
    final tid = json['tid']?.toString().trim() ?? '';
    final targetPid = json['targetPid']?.toString().trim() ?? '';
    final resolvedPage = _parseInt(json['resolvedPage']);
    final resolutionType = json['resolutionType']?.toString().trim() ?? '';
    final updatedAtEpochMs = _parseInt(json['updatedAtEpochMs']);

    if (tid.isEmpty ||
        targetPid.isEmpty ||
        resolvedPage == null ||
        resolvedPage < 1 ||
        resolutionType.isEmpty ||
        updatedAtEpochMs == null ||
        updatedAtEpochMs < 0) {
      return null;
    }

    final message = json['message']?.toString();

    return ReplyPageLocatorCacheEntry(
      tid: tid,
      targetPid: targetPid,
      resolvedPage: resolvedPage,
      resolutionType: resolutionType,
      message: message,
      updatedAtEpochMs: updatedAtEpochMs,
    );
  }

  static int? _parseInt(Object? rawValue) {
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is double) {
      return rawValue.toInt();
    }
    if (rawValue == null) {
      return null;
    }
    return int.tryParse(rawValue.toString());
  }
}

class ReplyPageLocatorCacheStore {
  static const String _storageKey = 'reply_page_locator.cache.v1';
  static const int _schemaVersion = 1;

  SharedPreferences? _prefs;

  ReplyPageLocatorCacheStore({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<ReplyPageLocatorCacheEntry>> load() async {
    final prefs = await _preferences;
    final rawValue = prefs.getString(_storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      return const <ReplyPageLocatorCacheEntry>[];
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) {
        return const <ReplyPageLocatorCacheEntry>[];
      }

      final map = Map<String, dynamic>.from(decoded);
      final version = ReplyPageLocatorCacheEntry._parseInt(map['version']) ?? 0;
      if (version != _schemaVersion) {
        return const <ReplyPageLocatorCacheEntry>[];
      }

      final rawEntries = map['entries'];
      if (rawEntries is! List) {
        return const <ReplyPageLocatorCacheEntry>[];
      }

      final entries = <ReplyPageLocatorCacheEntry>[];
      for (final item in rawEntries) {
        final entry = ReplyPageLocatorCacheEntry.fromJson(item);
        if (entry != null) {
          entries.add(entry);
        }
      }
      return entries;
    } catch (_) {
      return const <ReplyPageLocatorCacheEntry>[];
    }
  }

  Future<void> save(List<ReplyPageLocatorCacheEntry> entries) async {
    final prefs = await _preferences;
    final payload = <String, dynamic>{
      'version': _schemaVersion,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(_storageKey);
  }
}

const Object _unset = Object();

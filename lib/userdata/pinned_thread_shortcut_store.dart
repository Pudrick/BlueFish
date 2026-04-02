import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class PinnedThreadShortcut {
  final String tid;
  final String title;

  const PinnedThreadShortcut({required this.tid, required this.title});

  factory PinnedThreadShortcut.fromJson(Map<String, dynamic> json) {
    final tid = json['tid']?.toString().trim() ?? '';
    final title = json['title']?.toString().trim() ?? '';

    return PinnedThreadShortcut(
      tid: tid,
      title: title.isEmpty ? '帖子 $tid' : title,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'tid': tid, 'title': title};
  }
}

class PinnedThreadShortcutStore extends ChangeNotifier {
  static const String _storageKey = 'pinned_thread_shortcuts';

  SharedPreferences? _prefs;
  Future<void>? _initialization;
  final List<PinnedThreadShortcut> _shortcuts = <PinnedThreadShortcut>[];

  bool _isInitialized = false;

  PinnedThreadShortcutStore() {
    ensureInitialized();
  }

  bool get isInitialized => _isInitialized;

  List<PinnedThreadShortcut> get shortcuts =>
      List<PinnedThreadShortcut>.unmodifiable(_shortcuts);

  bool isPinned(String tid) {
    return _shortcuts.any((shortcut) => shortcut.tid == tid.trim());
  }

  Future<void> ensureInitialized() {
    return _initialization ??= _loadFromPrefs();
  }

  Future<void> add(PinnedThreadShortcut shortcut) async {
    await ensureInitialized();

    final normalizedTid = shortcut.tid.trim();
    if (normalizedTid.isEmpty) {
      return;
    }

    final normalizedShortcut = PinnedThreadShortcut(
      tid: normalizedTid,
      title: shortcut.title.trim().isEmpty
          ? '帖子 $normalizedTid'
          : shortcut.title.trim(),
    );

    _shortcuts.removeWhere((entry) => entry.tid == normalizedTid);
    _shortcuts.insert(0, normalizedShortcut);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String tid) async {
    await ensureInitialized();

    final normalizedTid = tid.trim();
    final int beforeCount = _shortcuts.length;
    _shortcuts.removeWhere((entry) => entry.tid == normalizedTid);
    if (_shortcuts.length == beforeCount) {
      return;
    }

    await _persist();
    notifyListeners();
  }

  Future<void> toggle(PinnedThreadShortcut shortcut) async {
    await ensureInitialized();

    if (isPinned(shortcut.tid)) {
      await remove(shortcut.tid);
      return;
    }

    await add(shortcut);
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final rawValue = _prefs!.getString(_storageKey);

    _shortcuts.clear();
    if (rawValue != null && rawValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawValue);
        if (decoded is List) {
          final Set<String> seenTids = <String>{};
          for (final item in decoded) {
            if (item is! Map) {
              continue;
            }

            final shortcut = PinnedThreadShortcut.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (shortcut.tid.isEmpty || !seenTids.add(shortcut.tid)) {
              continue;
            }

            _shortcuts.add(shortcut);
          }
        }
      } catch (_) {
        _shortcuts.clear();
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _storageKey,
      jsonEncode(
        _shortcuts.map((shortcut) => shortcut.toJson()).toList(growable: false),
      ),
    );
  }
}

final PinnedThreadShortcutStore pinnedThreadShortcutStore =
    PinnedThreadShortcutStore();

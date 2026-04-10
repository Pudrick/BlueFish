import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluefish/services/thread/reply_page_locator_log_models.dart';

abstract class ReplyPageLocatorLogWriter {
  Future<void> writeRecord(ReplyPageLocatorLogRecord record);
}

class ReplyPageLocatorLogSink implements ReplyPageLocatorLogWriter {
  static const int defaultMaxRecords = 300;
  static const String defaultRelativeDirectory = 'playground/logs';
  static const String defaultFileName = 'reply_page_locator.jsonl';
  static const Map<String, String> _stringSanitizationOverrides =
      <String, String>{
        '目标楼层无法显示': 'target_reply_not_visible',
        '目标回复早于当前帖子第一页可见范围，无法跳转。': 'target_reply_before_first_visible_page',
      };
  static final RegExp _localizedCharacterPattern = RegExp(
    r'[\u3000-\u303F\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\uFF00-\uFFEF]',
  );

  final int _maxRecords;
  final String _relativeDirectory;
  final String _fileName;
  final Future<Directory> Function() _resolveProjectRoot;

  Future<void>? _writing;
  bool _writeRequestedWhileRunning = false;

  ReplyPageLocatorLogSink({
    int maxRecords = defaultMaxRecords,
    String relativeDirectory = defaultRelativeDirectory,
    String fileName = defaultFileName,
    Future<Directory> Function()? projectRootResolver,
  }) : _maxRecords = maxRecords < 1 ? defaultMaxRecords : maxRecords,
       _relativeDirectory = relativeDirectory,
       _fileName = fileName,
       _resolveProjectRoot =
           projectRootResolver ?? resolveProjectRootFromCurrentDirectory;

  @override
  Future<void> writeRecord(ReplyPageLocatorLogRecord record) async {
    final currentWrite = _writing;
    if (currentWrite != null) {
      _writeRequestedWhileRunning = true;
      await currentWrite;
      return writeRecord(record);
    }

    _writing = _writeRecordNow(record);
    try {
      await _writing;
    } finally {
      _writing = null;
    }

    if (_writeRequestedWhileRunning) {
      _writeRequestedWhileRunning = false;
    }
  }

  Future<List<ReplyPageLocatorLogRecord>> readRecords() async {
    final file = await _resolveLogFile(createDirectory: false);
    if (!await file.exists()) {
      return const <ReplyPageLocatorLogRecord>[];
    }

    final content = await file.readAsString();
    return _decodeFileContent(content);
  }

  Future<void> clear() async {
    final file = await _resolveLogFile(createDirectory: false);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> resolveLogFilePath() async {
    final file = await _resolveLogFile(createDirectory: false);
    return file.path;
  }

  Future<void> _writeRecordNow(ReplyPageLocatorLogRecord record) async {
    final file = await _resolveLogFile(createDirectory: true);
    final existingContent = await file.exists()
        ? await file.readAsString()
        : '';
    final existingRecords = _decodeFileContent(existingContent);

    final nextRecords = <ReplyPageLocatorLogRecord>[...existingRecords, record];
    final removeCount = nextRecords.length - _maxRecords;
    if (removeCount > 0) {
      nextRecords.removeRange(0, removeCount);
    }

    final payload = _buildJsonLinesPayload(nextRecords);

    await file.writeAsString(payload, flush: true);
  }

  String _buildJsonLinesPayload(List<ReplyPageLocatorLogRecord> records) {
    if (records.isEmpty) {
      return '';
    }

    return records
        .map((record) => jsonEncode(_sanitizeRecord(record).toJson()))
        .join('\n');
  }

  List<ReplyPageLocatorLogRecord> _decodeFileContent(String content) {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return const <ReplyPageLocatorLogRecord>[];
    }

    return _decodeJsonLines(content.split(RegExp(r'\r?\n')));
  }

  List<ReplyPageLocatorLogRecord> _decodeJsonLines(List<String> lines) {
    final records = <ReplyPageLocatorLogRecord>[];
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(line);
        final record = ReplyPageLocatorLogRecord.fromJson(decoded);
        if (record != null) {
          records.add(record);
        }
      } catch (_) {
        // Ignore malformed historical lines so logging can self-heal.
      }
    }
    return records;
  }

  ReplyPageLocatorLogRecord _sanitizeRecord(ReplyPageLocatorLogRecord record) {
    return ReplyPageLocatorLogRecord(
      tid: _sanitizeString(record.tid),
      pid: _sanitizeString(record.pid),
      probeBudget: record.probeBudget,
      startedAtEpochMs: record.startedAtEpochMs,
      finishedAtEpochMs: record.finishedAtEpochMs,
      outcome: _sanitizeString(record.outcome),
      resolvedPage: record.resolvedPage,
      shouldNavigate: record.shouldNavigate,
      probesUsed: record.probesUsed,
      resultMessage: _sanitizeNullableString(record.resultMessage),
      exceptionMessage: _sanitizeNullableString(record.exceptionMessage),
      steps: record.steps.map(_sanitizeStep).toList(growable: false),
    );
  }

  ReplyPageLocatorLogStep _sanitizeStep(ReplyPageLocatorLogStep step) {
    return ReplyPageLocatorLogStep(
      name: _sanitizeString(step.name),
      atEpochMs: step.atEpochMs,
      details: _sanitizeMap(step.details),
    );
  }

  Map<String, Object?> _sanitizeMap(Map<dynamic, dynamic> rawMap) {
    final sanitized = <String, Object?>{};
    for (final entry in rawMap.entries) {
      final key = _sanitizeString(entry.key.toString());
      if (key.isEmpty) {
        continue;
      }
      sanitized[key] = _sanitizeValue(entry.value);
    }
    return sanitized;
  }

  List<Object?> _sanitizeList(List<dynamic> rawList) {
    return rawList
        .map<Object?>((entry) => _sanitizeValue(entry))
        .toList(growable: false);
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (value is String) {
      return _sanitizeNullableString(value);
    }
    if (value is List) {
      return _sanitizeList(value);
    }
    if (value is Map) {
      return _sanitizeMap(value);
    }

    return _sanitizeNullableString(value.toString());
  }

  String? _sanitizeNullableString(String? value) {
    if (value == null) {
      return null;
    }

    final sanitized = _sanitizeString(value);
    if (sanitized.isEmpty) {
      return null;
    }
    return sanitized;
  }

  String _sanitizeString(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final overridden = _stringSanitizationOverrides[trimmed];
    if (overridden != null) {
      return overridden;
    }

    return trimmed
        .replaceAll(_localizedCharacterPattern, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<File> _resolveLogFile({required bool createDirectory}) async {
    final projectRoot = await _resolveProjectRoot();
    final normalizedRelativeDirectory = _normalizeRelativePath(
      _relativeDirectory,
    );

    Directory logDirectory = projectRoot;
    if (normalizedRelativeDirectory.isNotEmpty) {
      logDirectory = Directory(
        _joinPath(projectRoot.path, normalizedRelativeDirectory),
      );
    }

    if (createDirectory) {
      await logDirectory.create(recursive: true);
    }

    return File(_joinPath(logDirectory.path, _fileName));
  }

  static Future<Directory> resolveProjectRootFromCurrentDirectory() async {
    var current = Directory.current.absolute;

    while (true) {
      final markerFile = File(_joinPath(current.path, 'pubspec.yaml'));
      if (await markerFile.exists()) {
        return current;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        throw StateError(
          'Unable to locate project root containing pubspec.yaml from '
          '${Directory.current.path}.',
        );
      }
      current = parent;
    }
  }

  static String _normalizeRelativePath(String rawPath) {
    final normalized = rawPath.trim().replaceAll('\\', '/');
    return normalized
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .join(Platform.pathSeparator);
  }

  static String _joinPath(String base, String child) {
    final normalizedChild = child.replaceAll('\\', '/');
    final segments = normalizedChild.split('/').where((s) => s.isNotEmpty);

    var current = base;
    for (final segment in segments) {
      current = '$current${Platform.pathSeparator}$segment';
    }
    return current;
  }
}

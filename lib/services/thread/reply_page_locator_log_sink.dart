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
  static const String _recordMarker = '--- 回复定位记录 ---';

  static const JsonEncoder _prettyJsonEncoder = JsonEncoder.withIndent('  ');

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

    final payload = _buildReadablePayload(nextRecords);

    await file.writeAsString(payload, flush: true);
  }

  String _buildReadablePayload(List<ReplyPageLocatorLogRecord> records) {
    final payload = StringBuffer();
    payload.writeln('# BlueFish 回复跳转定位日志（可读版）');
    payload.writeln('#');
    payload.writeln('# 字段说明：');
    payload.writeln('# - tid / pid: 目标帖子 ID 与目标回复 ID');
    payload.writeln('# - probeBudget: 本次允许探测的最大页数预算');
    payload.writeln('# - startedAtEpochMs / finishedAtEpochMs: 毫秒时间戳');
    payload.writeln('# - outcome: 本次定位结论（exact、bracket、tailLastPage 等）');
    payload.writeln('# - resolvedPage: 最终定位到的页码（若无则为 null）');
    payload.writeln('# - shouldNavigate: 是否应继续跳转到 thread_detail');
    payload.writeln('# - probesUsed: 实际探测页数');
    payload.writeln('# - steps: 详细计算与比对过程（name、atEpochMs、details）');
    payload.writeln('#');
    payload.writeln('# 格式说明：每条记录由标记行开始，后接一段格式化 JSON。');

    for (final item in records) {
      payload.writeln(_recordMarker);
      payload.writeln(_prettyJsonEncoder.convert(item.toJson()));
    }

    return payload.toString();
  }

  List<ReplyPageLocatorLogRecord> _decodeFileContent(String content) {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return const <ReplyPageLocatorLogRecord>[];
    }

    if (normalized.contains(_recordMarker)) {
      return _decodeReadableContent(content);
    }

    return _decodeLines(content.split(RegExp(r'\r?\n')));
  }

  List<ReplyPageLocatorLogRecord> _decodeReadableContent(String content) {
    final records = <ReplyPageLocatorLogRecord>[];
    final sections = content.split(_recordMarker);

    for (final rawSection in sections) {
      final section = rawSection.trim();
      if (section.isEmpty || section.startsWith('#')) {
        continue;
      }

      try {
        final decoded = jsonDecode(section);
        final record = ReplyPageLocatorLogRecord.fromJson(decoded);
        if (record != null) {
          records.add(record);
        }
      } catch (_) {
        // Skip malformed blocks to keep historical files readable.
      }
    }

    return records;
  }

  List<ReplyPageLocatorLogRecord> _decodeLines(List<String> lines) {
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

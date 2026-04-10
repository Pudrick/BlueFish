import 'package:flutter/foundation.dart';

@immutable
class ReplyPageLocatorLogStep {
  final String name;
  final int atEpochMs;
  final Map<String, Object?> details;

  const ReplyPageLocatorLogStep({
    required this.name,
    required this.atEpochMs,
    required this.details,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'atEpochMs': atEpochMs,
      'details': details,
    };
  }

  static ReplyPageLocatorLogStep? fromJson(Object? rawJson) {
    if (rawJson is! Map) {
      return null;
    }

    final json = Map<String, dynamic>.from(rawJson);
    final name = json['name']?.toString().trim() ?? '';
    final atEpochMs = _parseInt(json['atEpochMs']);
    final rawDetails = json['details'];

    if (name.isEmpty || atEpochMs == null || atEpochMs < 0) {
      return null;
    }

    final details = <String, Object?>{};
    if (rawDetails is Map) {
      for (final entry in rawDetails.entries) {
        final key = entry.key.toString();
        details[key] = _toSupportedValue(entry.value);
      }
    }

    return ReplyPageLocatorLogStep(
      name: name,
      atEpochMs: atEpochMs,
      details: details,
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

  static Object? _toSupportedValue(Object? value) {
    if (value == null ||
        value is num ||
        value is bool ||
        value is String ||
        value is List ||
        value is Map) {
      return value;
    }
    return value.toString();
  }
}

@immutable
class ReplyPageLocatorLogRecord {
  final String tid;
  final String pid;
  final int probeBudget;
  final int startedAtEpochMs;
  final int finishedAtEpochMs;
  final String outcome;
  final int? resolvedPage;
  final bool? shouldNavigate;
  final int? probesUsed;
  final String? resultMessage;
  final String? exceptionMessage;
  final List<ReplyPageLocatorLogStep> steps;

  const ReplyPageLocatorLogRecord({
    required this.tid,
    required this.pid,
    required this.probeBudget,
    required this.startedAtEpochMs,
    required this.finishedAtEpochMs,
    required this.outcome,
    required this.resolvedPage,
    required this.shouldNavigate,
    required this.probesUsed,
    required this.resultMessage,
    required this.exceptionMessage,
    required this.steps,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'tid': tid,
      'pid': pid,
      'probeBudget': probeBudget,
      'startedAtEpochMs': startedAtEpochMs,
      'finishedAtEpochMs': finishedAtEpochMs,
      'outcome': outcome,
      'resolvedPage': resolvedPage,
      'shouldNavigate': shouldNavigate,
      'probesUsed': probesUsed,
      'resultMessage': resultMessage,
      'exceptionMessage': exceptionMessage,
      'steps': steps.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  static ReplyPageLocatorLogRecord? fromJson(Object? rawJson) {
    if (rawJson is! Map) {
      return null;
    }

    final json = Map<String, dynamic>.from(rawJson);
    final tid = json['tid']?.toString().trim() ?? '';
    final pid = json['pid']?.toString().trim() ?? '';
    final probeBudget = ReplyPageLocatorLogStep._parseInt(json['probeBudget']);
    final startedAtEpochMs = ReplyPageLocatorLogStep._parseInt(
      json['startedAtEpochMs'],
    );
    final finishedAtEpochMs = ReplyPageLocatorLogStep._parseInt(
      json['finishedAtEpochMs'],
    );
    final outcome = json['outcome']?.toString().trim() ?? '';

    if (tid.isEmpty ||
        pid.isEmpty ||
        probeBudget == null ||
        probeBudget < 1 ||
        startedAtEpochMs == null ||
        startedAtEpochMs < 0 ||
        finishedAtEpochMs == null ||
        finishedAtEpochMs < startedAtEpochMs ||
        outcome.isEmpty) {
      return null;
    }

    final resolvedPage = ReplyPageLocatorLogStep._parseInt(
      json['resolvedPage'],
    );
    final shouldNavigate = json['shouldNavigate'];
    final probesUsed = ReplyPageLocatorLogStep._parseInt(json['probesUsed']);
    final resultMessage = json['resultMessage']?.toString();
    final exceptionMessage = json['exceptionMessage']?.toString();

    final rawSteps = json['steps'];
    final steps = <ReplyPageLocatorLogStep>[];
    if (rawSteps is List) {
      for (final item in rawSteps) {
        final step = ReplyPageLocatorLogStep.fromJson(item);
        if (step != null) {
          steps.add(step);
        }
      }
    }

    return ReplyPageLocatorLogRecord(
      tid: tid,
      pid: pid,
      probeBudget: probeBudget,
      startedAtEpochMs: startedAtEpochMs,
      finishedAtEpochMs: finishedAtEpochMs,
      outcome: outcome,
      resolvedPage: resolvedPage,
      shouldNavigate: shouldNavigate is bool ? shouldNavigate : null,
      probesUsed: probesUsed,
      resultMessage: resultMessage,
      exceptionMessage: exceptionMessage,
      steps: steps,
    );
  }
}

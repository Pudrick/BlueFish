part of 'reply_page_locator_service.dart';

class _ReplyPageLocatorProbeSession {
  final ReplyPageLocatorService service;
  final String normalizedTid;
  final int normalizedBudget;
  final bool Function()? isCanceled;
  final _LocateTrace trace;
  final Map<int, ThreadDetail> visitedPages = <int, ThreadDetail>{};

  int probesUsed = 0;
  bool budgetExhausted = false;
  bool _budgetTelemetryRecorded = false;

  _ReplyPageLocatorProbeSession({
    required this.service,
    required this.normalizedTid,
    required this.normalizedBudget,
    required this.isCanceled,
    required this.trace,
  });

  Future<_ProbeOutcome> fetchPage(
    int page, {
    required String tracePrefix,
    bool countAgainstBudget = true,
  }) async {
    trace.addStep('${tracePrefix}_begin', <String, Object?>{
      'page': page,
      'countAgainstBudget': countAgainstBudget,
      'probesUsed': probesUsed,
      'probeBudget': normalizedBudget,
      'alreadyVisited': visitedPages.containsKey(page),
    });
    if (service._isCanceled(isCanceled)) {
      trace.addStep('${tracePrefix}_canceled', <String, Object?>{'page': page});
      return _ProbeOutcome(terminal: canceledResult());
    }

    final existing = visitedPages[page];
    if (existing != null) {
      trace.addStep('${tracePrefix}_reuse_cached_page', <String, Object?>{
        'page': page,
        ..._detailSummary(existing),
      });
      return _ProbeOutcome(detail: existing, reused: true);
    }

    if (countAgainstBudget && probesUsed >= normalizedBudget) {
      budgetExhausted = true;
      trace.addStep('${tracePrefix}_budget_reached', <String, Object?>{
        'page': page,
        'probesUsed': probesUsed,
        'probeBudget': normalizedBudget,
      });
      return const _ProbeOutcome();
    }

    if (countAgainstBudget) {
      probesUsed += 1;
    }
    final detailResult = await service._threadDetailService.getThreadDetail(
      normalizedTid,
      page,
    );

    if (service._isCanceled(isCanceled)) {
      trace.addStep('${tracePrefix}_canceled_after_fetch', <String, Object?>{
        'page': page,
        'probesUsed': probesUsed,
      });
      return _ProbeOutcome(terminal: canceledResult());
    }

    ThreadDetail? detail;
    detailResult.when(
      success: (data) {
        detail = data;
      },
      failure: (_, __) {},
    );
    if (detail == null) {
      trace.addStep('${tracePrefix}_detail_missing', <String, Object?>{
        'page': page,
      });
      return const _ProbeOutcome();
    }

    visitedPages[page] = detail!;
    trace.addStep('${tracePrefix}_success', <String, Object?>{
      'page': page,
      ..._detailSummary(detail!),
    });
    return _ProbeOutcome(detail: detail);
  }

  ReplyPageLocateResult canceledResult() {
    return ReplyPageLocateResult.canceled(
      probesUsed: probesUsed,
      probeBudget: normalizedBudget,
    );
  }

  ReplyPageLocateResult fallbackPage1Result() {
    return ReplyPageLocateResult.fallbackPage1(
      probesUsed: probesUsed,
      probeBudget: normalizedBudget,
    );
  }

  void recordBudgetExhausted([String? traceStepName]) {
    if (!_budgetTelemetryRecorded && budgetExhausted) {
      ReplyPageLocatorService._budgetExhausted += 1;
      _budgetTelemetryRecorded = true;
      if (traceStepName != null) {
        trace.addStep(traceStepName);
      }
    }
  }
}

class _LocateTrace {
  final String tid;
  final String pid;
  final int probeBudget;
  final int _startedAtEpochMs;
  final List<ReplyPageLocatorLogStep> _steps = <ReplyPageLocatorLogStep>[];

  _LocateTrace({
    required this.tid,
    required this.pid,
    required this.probeBudget,
  }) : _startedAtEpochMs = DateTime.now().millisecondsSinceEpoch;

  void addStep(String name, [Map<String, Object?> details = const {}]) {
    _steps.add(
      ReplyPageLocatorLogStep(
        name: name,
        atEpochMs: DateTime.now().millisecondsSinceEpoch,
        details: _normalizeDetails(details),
      ),
    );
  }

  ReplyPageLocatorLogRecord completeWithResult(ReplyPageLocateResult result) {
    return ReplyPageLocatorLogRecord(
      tid: tid,
      pid: pid,
      probeBudget: probeBudget,
      startedAtEpochMs: _startedAtEpochMs,
      finishedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      outcome: result.resolutionType.name,
      resolvedPage: result.resolvedPage,
      shouldNavigate: result.shouldNavigate,
      probesUsed: result.probesUsed,
      resultMessage: result.message,
      exceptionMessage: null,
      steps: List<ReplyPageLocatorLogStep>.unmodifiable(_steps),
    );
  }

  ReplyPageLocatorLogRecord completeWithException(String exceptionMessage) {
    return ReplyPageLocatorLogRecord(
      tid: tid,
      pid: pid,
      probeBudget: probeBudget,
      startedAtEpochMs: _startedAtEpochMs,
      finishedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      outcome: 'exception',
      resolvedPage: null,
      shouldNavigate: null,
      probesUsed: null,
      resultMessage: null,
      exceptionMessage: exceptionMessage,
      steps: List<ReplyPageLocatorLogStep>.unmodifiable(_steps),
    );
  }

  Map<String, Object?> _normalizeDetails(Map<String, Object?> details) {
    final normalized = <String, Object?>{};
    details.forEach((key, value) {
      normalized[key] = _normalizeValue(value);
    });
    return normalized;
  }

  Object? _normalizeValue(Object? value) {
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

class _ProbeOutcome {
  final ThreadDetail? detail;
  final ReplyPageLocateResult? terminal;
  final bool reused;

  const _ProbeOutcome({this.detail, this.terminal, this.reused = false});
}

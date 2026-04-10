import 'dart:async';
import 'dart:convert';

import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/thread/single_reply_floor.dart';
import 'package:bluefish/models/thread/thread_detail.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_log_models.dart';
import 'package:bluefish/services/thread/reply_page_locator_log_sink.dart';
import 'package:bluefish/services/thread/thread_detail_service.dart';
import 'package:bluefish/userdata/reply_page_locator_cache_store.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum ReplyPageResolutionType {
  exact,
  bracket,
  tailLastPage,
  errorOutOfLowBound,
  fallbackPage1,
  canceled,
}

class ReplyPageLocateResult {
  final int? resolvedPage;
  final ReplyPageResolutionType resolutionType;
  final String? message;
  final int probesUsed;
  final int probeBudget;

  const ReplyPageLocateResult._({
    required this.resolvedPage,
    required this.resolutionType,
    required this.message,
    required this.probesUsed,
    required this.probeBudget,
  });

  bool get shouldNavigate =>
      resolvedPage != null &&
      resolutionType != ReplyPageResolutionType.canceled &&
      resolutionType != ReplyPageResolutionType.errorOutOfLowBound;

  factory ReplyPageLocateResult.exact({
    required int page,
    required int probesUsed,
    required int probeBudget,
  }) {
    return ReplyPageLocateResult._(
      resolvedPage: page,
      resolutionType: ReplyPageResolutionType.exact,
      message: null,
      probesUsed: probesUsed,
      probeBudget: probeBudget,
    );
  }

  factory ReplyPageLocateResult.bracket({
    required int page,
    required int probesUsed,
    required int probeBudget,
  }) {
    return ReplyPageLocateResult._(
      resolvedPage: page,
      resolutionType: ReplyPageResolutionType.bracket,
      message: '目标楼层无法显示',
      probesUsed: probesUsed,
      probeBudget: probeBudget,
    );
  }

  factory ReplyPageLocateResult.tailLastPage({
    required int page,
    required int probesUsed,
    required int probeBudget,
  }) {
    return ReplyPageLocateResult._(
      resolvedPage: page,
      resolutionType: ReplyPageResolutionType.tailLastPage,
      message: null,
      probesUsed: probesUsed,
      probeBudget: probeBudget,
    );
  }

  factory ReplyPageLocateResult.errorOutOfLowBound({
    required int probesUsed,
    required int probeBudget,
  }) {
    return ReplyPageLocateResult._(
      resolvedPage: null,
      resolutionType: ReplyPageResolutionType.errorOutOfLowBound,
      message: '目标回复早于当前帖子第一页可见范围，无法跳转。',
      probesUsed: probesUsed,
      probeBudget: probeBudget,
    );
  }

  factory ReplyPageLocateResult.fallbackPage1({
    required int probesUsed,
    required int probeBudget,
  }) {
    return ReplyPageLocateResult._(
      resolvedPage: 1,
      resolutionType: ReplyPageResolutionType.fallbackPage1,
      message: null,
      probesUsed: probesUsed,
      probeBudget: probeBudget,
    );
  }

  factory ReplyPageLocateResult.canceled({
    required int probesUsed,
    required int probeBudget,
  }) {
    return ReplyPageLocateResult._(
      resolvedPage: null,
      resolutionType: ReplyPageResolutionType.canceled,
      message: null,
      probesUsed: probesUsed,
      probeBudget: probeBudget,
    );
  }
}

class ReplyPageLocatorTelemetry {
  final int totalLookups;
  final int officialHintHits;
  final int interpolationHits;
  final int bracketHits;
  final int canceled;
  final int budgetExhausted;
  final int lowBoundErrors;
  final int tailLastPageHits;

  const ReplyPageLocatorTelemetry({
    required this.totalLookups,
    required this.officialHintHits,
    required this.interpolationHits,
    required this.bracketHits,
    required this.canceled,
    required this.budgetExhausted,
    required this.lowBoundErrors,
    required this.tailLastPageHits,
  });

  double _rateOf(int count) {
    if (totalLookups <= 0) {
      return 0;
    }
    return count / totalLookups;
  }

  double get officialHintHitRate => _rateOf(officialHintHits);

  double get interpolationHitRate => _rateOf(interpolationHits);

  double get bracketHitRate => _rateOf(bracketHits);

  double get cancelRate => _rateOf(canceled);

  double get budgetExhaustedRate => _rateOf(budgetExhausted);
}

class ReplyPageLocatorService {
  static const String _officialHintBaseUrl =
      'https://my.hupu.com/pcmapi/pc/bbs/v1/reply/getPostPageNum';
  static const int _internalMaxProbeBudget = 60;

  static int _totalLookups = 0;
  static int _officialHintHits = 0;
  static int _interpolationHits = 0;
  static int _bracketHits = 0;
  static int _canceled = 0;
  static int _budgetExhausted = 0;
  static int _lowBoundErrors = 0;
  static int _tailLastPageHits = 0;

  final http.Client _client;
  final ThreadDetailService _threadDetailService;
  final ReplyPageLocatorCacheService _cacheService;
  final ReplyPageLocatorLogWriter _logWriter;
  final bool Function() _shouldWriteJumpLogs;

  ReplyPageLocatorService({
    http.Client? client,
    ThreadDetailService? threadDetailService,
    ReplyPageLocatorCacheService? cacheService,
    ReplyPageLocatorLogWriter? logWriter,
    bool Function()? shouldWriteJumpLogs,
  }) : _client = client ?? httpClient,
       _threadDetailService = threadDetailService ?? ThreadDetailService(),
       _cacheService = cacheService ?? ReplyPageLocatorCacheService(),
       _logWriter = logWriter ?? ReplyPageLocatorLogSink(),
       _shouldWriteJumpLogs = shouldWriteJumpLogs ?? (() => true);

  static ReplyPageLocatorTelemetry telemetrySnapshot() {
    return ReplyPageLocatorTelemetry(
      totalLookups: _totalLookups,
      officialHintHits: _officialHintHits,
      interpolationHits: _interpolationHits,
      bracketHits: _bracketHits,
      canceled: _canceled,
      budgetExhausted: _budgetExhausted,
      lowBoundErrors: _lowBoundErrors,
      tailLastPageHits: _tailLastPageHits,
    );
  }

  static void resetTelemetry() {
    _totalLookups = 0;
    _officialHintHits = 0;
    _interpolationHits = 0;
    _bracketHits = 0;
    _canceled = 0;
    _budgetExhausted = 0;
    _lowBoundErrors = 0;
    _tailLastPageHits = 0;
  }

  Future<ReplyPageLocateResult> locateReplyPage({
    required String tid,
    required String pid,
    required int probeBudget,
    int cacheMaxEntries = ReplyPageLocatorCacheService.defaultMaxEntries,
    int coarseProbeStride = AppSettings.defaultReplyLocateCoarseProbeStride,
    bool useCache = true,
    bool Function()? isCanceled,
  }) async {
    _totalLookups += 1;

    final normalizedTid = tid.trim();
    final normalizedPid = pid.trim();
    final normalizedBudget = _normalizeBudget(probeBudget);
    final normalizedCacheMaxEntries = cacheMaxEntries < 1
        ? ReplyPageLocatorCacheService.defaultMaxEntries
        : cacheMaxEntries;
    final normalizedCoarseProbeStride = _normalizeCoarseProbeStride(
      coarseProbeStride,
    );

    final trace = _LocateTrace(
      tid: normalizedTid,
      pid: normalizedPid,
      probeBudget: normalizedBudget,
    );
    trace.addStep('normalize_input', <String, Object?>{
      'tid': normalizedTid,
      'pid': normalizedPid,
      'probeBudget': probeBudget,
      'normalizedProbeBudget': normalizedBudget,
      'useCache': useCache,
      'cacheMaxEntries': cacheMaxEntries,
      'normalizedCacheMaxEntries': normalizedCacheMaxEntries,
      'coarseProbeStride': coarseProbeStride,
      'normalizedCoarseProbeStride': normalizedCoarseProbeStride,
    });

    ReplyPageLocateResult? completedResult;
    Object? thrownError;

    try {
      if (_isCanceled(isCanceled)) {
        _canceled += 1;
        trace.addStep('canceled_before_locate');
        completedResult = ReplyPageLocateResult.canceled(
          probesUsed: 0,
          probeBudget: normalizedBudget,
        );
        return completedResult;
      }

      if (useCache) {
        await _cacheService.ensureInitialized();
        await _cacheService.configureMaxEntries(normalizedCacheMaxEntries);
        final cached = await _cacheService.findExact(
          tid: normalizedTid,
          targetPid: normalizedPid,
        );
        if (cached != null) {
          trace.addStep('cache_exact_hit', <String, Object?>{
            'resolvedPage': cached.resolvedPage,
            'resolutionType': cached.resolutionType,
            'message': cached.message,
          });
          completedResult = _resultFromCacheEntry(cached, normalizedBudget);
          return completedResult;
        }
        trace.addStep('cache_exact_miss');
      } else {
        trace.addStep('cache_disabled');
      }

      final targetPidNumber = _parsePidNumber(normalizedPid);
      trace.addStep('parse_target_pid', <String, Object?>{
        'rawPid': normalizedPid,
        'targetPidNumber': targetPidNumber,
      });
      final officialHintRaw = await _fetchOfficialHintPage(
        tid: normalizedTid,
        pid: normalizedPid,
      );
      trace.addStep('official_hint_result', <String, Object?>{
        'officialHintRaw': officialHintRaw,
      });

      final hintDrivenResult = await _locateReplyPageByHintRange(
        normalizedTid: normalizedTid,
        normalizedPid: normalizedPid,
        targetPidNumber: targetPidNumber,
        normalizedBudget: normalizedBudget,
        coarseProbeStride: normalizedCoarseProbeStride,
        useCache: useCache,
        officialHintRaw: officialHintRaw,
        isCanceled: isCanceled,
        trace: trace,
      );

      if (hintDrivenResult != null) {
        trace.addStep('hint_range_terminal', <String, Object?>{
          'resolutionType': hintDrivenResult.resolutionType.name,
          'resolvedPage': hintDrivenResult.resolvedPage,
          'probesUsed': hintDrivenResult.probesUsed,
          'shouldNavigate': hintDrivenResult.shouldNavigate,
        });
        completedResult = _finalize(
          tid: normalizedTid,
          pid: normalizedPid,
          result: hintDrivenResult,
          useCache: useCache,
        );
        return completedResult;
      }

      trace.addStep('hint_range_fallback_to_legacy');
      final legacyResult = await _locateReplyPageLegacy(
        normalizedTid: normalizedTid,
        normalizedPid: normalizedPid,
        targetPidNumber: targetPidNumber,
        normalizedBudget: normalizedBudget,
        coarseProbeStride: normalizedCoarseProbeStride,
        useCache: useCache,
        officialHintRaw: officialHintRaw,
        isCanceled: isCanceled,
        trace: trace,
      );
      trace.addStep('legacy_terminal', <String, Object?>{
        'resolutionType': legacyResult.resolutionType.name,
        'resolvedPage': legacyResult.resolvedPage,
        'probesUsed': legacyResult.probesUsed,
        'shouldNavigate': legacyResult.shouldNavigate,
      });
      completedResult = _finalize(
        tid: normalizedTid,
        pid: normalizedPid,
        result: legacyResult,
        useCache: useCache,
      );
      return completedResult;
    } catch (error, stackTrace) {
      thrownError = error;
      trace.addStep('exception_thrown', <String, Object?>{
        'error': error.toString(),
      });
      debugPrint(
        'ReplyPageLocatorService failed for tid=$normalizedTid pid=$normalizedPid: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      if (completedResult != null) {
        await _persistTraceRecord(trace.completeWithResult(completedResult));
      } else if (thrownError != null) {
        await _persistTraceRecord(
          trace.completeWithException(thrownError.toString()),
        );
      }
    }
  }

  Future<ReplyPageLocateResult?> _locateReplyPageByHintRange({
    required String normalizedTid,
    required String normalizedPid,
    required int? targetPidNumber,
    required int normalizedBudget,
    required int coarseProbeStride,
    required bool useCache,
    required int? officialHintRaw,
    bool Function()? isCanceled,
    required _LocateTrace trace,
  }) async {
    trace.addStep('hint_range_start', <String, Object?>{
      'targetPidNumber': targetPidNumber,
      'officialHintRaw': officialHintRaw,
      'normalizedBudget': normalizedBudget,
      'coarseProbeStride': coarseProbeStride,
      'useCache': useCache,
    });
    if (targetPidNumber == null ||
        officialHintRaw == null ||
        officialHintRaw < 1) {
      trace.addStep('hint_range_skipped', <String, Object?>{
        'reason': 'missing_target_or_invalid_hint',
      });
      return null;
    }

    final Map<int, ThreadDetail> visitedPages = <int, ThreadDetail>{};
    int probesUsed = 0;
    bool budgetExhausted = false;
    bool budgetTelemetryRecorded = false;

    void recordBudgetExhausted() {
      if (!budgetTelemetryRecorded && budgetExhausted) {
        _budgetExhausted += 1;
        budgetTelemetryRecorded = true;
        trace.addStep('hint_budget_exhausted_counter_incremented');
      }
    }

    ReplyPageLocateResult fallbackPage1() {
      trace.addStep('hint_fallback_page1', <String, Object?>{
        'probesUsed': probesUsed,
        'probeBudget': normalizedBudget,
      });
      recordBudgetExhausted();
      return ReplyPageLocateResult.fallbackPage1(
        probesUsed: probesUsed,
        probeBudget: normalizedBudget,
      );
    }

    Future<_ProbeOutcome> probePage(
      int page, {
      bool countAgainstBudget = true,
    }) async {
      trace.addStep('hint_probe_begin', <String, Object?>{
        'page': page,
        'countAgainstBudget': countAgainstBudget,
        'probesUsed': probesUsed,
        'probeBudget': normalizedBudget,
        'alreadyVisited': visitedPages.containsKey(page),
      });
      if (_isCanceled(isCanceled)) {
        trace.addStep('hint_probe_canceled', <String, Object?>{'page': page});
        return _ProbeOutcome(
          terminal: ReplyPageLocateResult.canceled(
            probesUsed: probesUsed,
            probeBudget: normalizedBudget,
          ),
        );
      }

      final existing = visitedPages[page];
      if (existing != null) {
        trace.addStep('hint_probe_reuse_cached_page', <String, Object?>{
          'page': page,
          ..._detailSummary(existing),
        });
        return _ProbeOutcome(detail: existing);
      }

      if (countAgainstBudget && probesUsed >= normalizedBudget) {
        budgetExhausted = true;
        trace.addStep('hint_probe_budget_reached', <String, Object?>{
          'page': page,
          'probesUsed': probesUsed,
          'probeBudget': normalizedBudget,
        });
        return const _ProbeOutcome();
      }

      if (countAgainstBudget) {
        probesUsed += 1;
      }
      final detailResult = await _threadDetailService.getThreadDetail(
        normalizedTid,
        page,
      );

      if (_isCanceled(isCanceled)) {
        trace.addStep('hint_probe_canceled_after_fetch', <String, Object?>{
          'page': page,
          'probesUsed': probesUsed,
        });
        return _ProbeOutcome(
          terminal: ReplyPageLocateResult.canceled(
            probesUsed: probesUsed,
            probeBudget: normalizedBudget,
          ),
        );
      }

      ThreadDetail? detail;
      detailResult.when(
        success: (data) {
          detail = data;
        },
        failure: (_, __) {},
      );
      if (detail == null) {
        trace.addStep('hint_probe_detail_missing', <String, Object?>{
          'page': page,
        });
        return const _ProbeOutcome();
      }

      visitedPages[page] = detail!;
      trace.addStep('hint_probe_success', <String, Object?>{
        'page': page,
        ..._detailSummary(detail!),
      });
      return _ProbeOutcome(detail: detail);
    }

    final officialOutcome = await probePage(officialHintRaw);
    if (officialOutcome.terminal != null) {
      _traceResult(
        trace,
        'hint_official_probe_terminal',
        officialOutcome.terminal!,
      );
      return officialOutcome.terminal;
    }

    final officialHintDetail = officialOutcome.detail;
    if (officialHintDetail == null) {
      trace.addStep('hint_official_probe_no_detail');
      return null;
    }

    final totalPages = officialHintDetail.totalPagesNum;
    final officialHint = _normalizeOfficialHint(
      officialHintRaw: officialHintRaw,
      totalPages: totalPages,
    );
    if (officialHint == null) {
      trace.addStep('hint_official_invalid_for_total_pages', <String, Object?>{
        'officialHintRaw': officialHintRaw,
        'totalPages': totalPages,
      });
      return null;
    }

    final officialHintResult = _resolveCandidatePageResult(
      detail: officialHintDetail,
      targetPid: normalizedPid,
      targetPidNumber: targetPidNumber,
      probesUsed: probesUsed,
      probeBudget: normalizedBudget,
      trace: trace,
      stage: 'hint_official',
    );
    if (officialHintResult != null) {
      if (officialHintResult.resolutionType == ReplyPageResolutionType.exact) {
        _officialHintHits += 1;
      }
      _traceResult(
        trace,
        'hint_official_candidate_terminal',
        officialHintResult,
      );
      return officialHintResult;
    }

    final firstPageOutcome = await probePage(1);
    if (firstPageOutcome.terminal != null) {
      _traceResult(
        trace,
        'hint_first_page_terminal',
        firstPageOutcome.terminal!,
      );
      return firstPageOutcome.terminal;
    }

    final firstPageDetail = firstPageOutcome.detail;
    if (firstPageDetail == null) {
      trace.addStep('hint_first_page_missing');
      return fallbackPage1();
    }

    final lowBoundResult = _resolveLowBoundResult(
      detail: firstPageDetail,
      targetPidNumber: targetPidNumber,
      probesUsed: probesUsed,
      probeBudget: normalizedBudget,
      trace: trace,
      stage: 'hint_low_bound',
    );
    if (lowBoundResult != null) {
      _traceResult(trace, 'hint_low_bound_terminal', lowBoundResult);
      return lowBoundResult;
    }

    ThreadDetail? lastPageDetail;
    if (totalPages > 1) {
      final lastPageOutcome = await probePage(totalPages);
      if (lastPageOutcome.terminal != null) {
        _traceResult(
          trace,
          'hint_last_page_terminal',
          lastPageOutcome.terminal!,
        );
        return lastPageOutcome.terminal;
      }

      lastPageDetail = lastPageOutcome.detail;
      if (lastPageDetail != null) {
        final lastPageCandidateResult = _resolveCandidatePageResult(
          detail: lastPageDetail,
          targetPid: normalizedPid,
          targetPidNumber: targetPidNumber,
          probesUsed: probesUsed,
          probeBudget: normalizedBudget,
          trace: trace,
          stage: 'hint_last_page',
        );
        if (lastPageCandidateResult != null) {
          _traceResult(
            trace,
            'hint_last_page_candidate_terminal',
            lastPageCandidateResult,
          );
          return lastPageCandidateResult;
        }

        final tailPageResult = _resolveTailLastPageResult(
          detail: lastPageDetail,
          targetPidNumber: targetPidNumber,
          probesUsed: probesUsed,
          probeBudget: normalizedBudget,
          trace: trace,
          stage: 'hint_tail_compare',
        );
        if (tailPageResult != null) {
          _traceResult(trace, 'hint_tail_terminal', tailPageResult);
          return tailPageResult;
        }
      }
    } else {
      lastPageDetail = firstPageDetail;
    }

    ThreadDetail currentHintDetail = officialHintDetail;
    final officialRelation = _classifyPageRange(
      officialHintDetail,
      targetPidNumber,
    );
    trace.addStep('hint_official_range_relation', <String, Object?>{
      'relation': officialRelation.name,
      ..._detailSummary(officialHintDetail),
      'targetPidNumber': targetPidNumber,
    });
    if (officialRelation != _PageTargetRelation.within) {
      final coarseIntervalOutcome = await _resolveCoarseInterpolationInterval(
        totalPages: totalPages,
        targetPidNumber: targetPidNumber,
        coarseProbeStride: coarseProbeStride,
        probePage: (int page) => probePage(page, countAgainstBudget: false),
        trace: trace,
        stage: 'hint_coarse',
      );
      if (coarseIntervalOutcome.terminal != null) {
        _traceResult(
          trace,
          'hint_coarse_terminal',
          coarseIntervalOutcome.terminal!,
        );
        return coarseIntervalOutcome.terminal;
      }

      var interpolationLowerBound = firstPageDetail;
      var interpolationUpperBound = lastPageDetail ?? firstPageDetail;
      final coarseInterval = coarseIntervalOutcome.interval;
      if (coarseInterval != null) {
        interpolationLowerBound = coarseInterval.lowerBoundDetail;
        interpolationUpperBound = coarseInterval.upperBoundDetail;
        trace.addStep('hint_coarse_interval_applied', <String, Object?>{
          'lowerPage': interpolationLowerBound.currentPage,
          'upperPage': interpolationUpperBound.currentPage,
          'lowerFirstPid': _firstReplyPid(interpolationLowerBound),
          'upperFirstPid': _firstReplyPid(interpolationUpperBound),
        });
      } else {
        trace.addStep('hint_coarse_interval_unavailable_fallback_global');
      }

      final interpolatedPage = _computeInterpolatedPage(
        totalPages: totalPages,
        targetPidNumber: targetPidNumber,
        lowerBoundDetail: interpolationLowerBound,
        upperBoundDetail: interpolationUpperBound,
        trace: trace,
        stage: 'hint_interpolation',
      );
      trace.addStep('hint_interpolation_page', <String, Object?>{
        'interpolatedPage': interpolatedPage,
        'officialCurrentPage': currentHintDetail.currentPage,
      });

      if (interpolatedPage != null &&
          interpolatedPage != currentHintDetail.currentPage) {
        final interpolationOutcome = await probePage(interpolatedPage);
        if (interpolationOutcome.terminal != null) {
          _traceResult(
            trace,
            'hint_interpolation_probe_terminal',
            interpolationOutcome.terminal!,
          );
          return interpolationOutcome.terminal;
        }

        final interpolationDetail = interpolationOutcome.detail;
        if (interpolationDetail != null) {
          currentHintDetail = interpolationDetail;
          final interpolationResult = _resolveCandidatePageResult(
            detail: interpolationDetail,
            targetPid: normalizedPid,
            targetPidNumber: targetPidNumber,
            probesUsed: probesUsed,
            probeBudget: normalizedBudget,
            trace: trace,
            stage: 'hint_interpolation_candidate',
          );
          if (interpolationResult != null) {
            if (interpolationResult.resolutionType ==
                ReplyPageResolutionType.exact) {
              _interpolationHits += 1;
            }
            _traceResult(
              trace,
              'hint_interpolation_candidate_terminal',
              interpolationResult,
            );
            return interpolationResult;
          }
        }
      }
    }

    int seedPage = currentHintDetail.currentPage;
    final currentHintFirstPid = _parsePidNumber(
      _firstReplyPid(currentHintDetail),
    );
    trace.addStep('hint_seed_base', <String, Object?>{
      'seedPage': seedPage,
      'currentHintFirstPid': currentHintFirstPid,
      'targetPidNumber': targetPidNumber,
    });

    if (useCache) {
      final nearestCacheEntry = await _cacheService.findNearestInThread(
        tid: normalizedTid,
        targetPid: normalizedPid,
      );
      final cachePid = nearestCacheEntry == null
          ? null
          : _parsePidNumber(nearestCacheEntry.targetPid);
      trace.addStep('hint_cache_nearest_result', <String, Object?>{
        'hasNearest': nearestCacheEntry != null,
        'nearestResolvedPage': nearestCacheEntry?.resolvedPage,
        'nearestTargetPid': nearestCacheEntry?.targetPid,
        'nearestPidNumber': cachePid,
      });

      if (currentHintFirstPid != null &&
          currentHintFirstPid == targetPidNumber) {
        final result = ReplyPageLocateResult.exact(
          page: currentHintDetail.currentPage,
          probesUsed: probesUsed,
          probeBudget: normalizedBudget,
        );
        _traceResult(trace, 'hint_seed_exact_from_first_pid', result);
        return result;
      }

      if (nearestCacheEntry != null &&
          cachePid != null &&
          cachePid == targetPidNumber) {
        final result = _resultFromCacheEntry(
          nearestCacheEntry,
          normalizedBudget,
        );
        _traceResult(trace, 'hint_seed_exact_from_cache_pid', result);
        return result;
      }

      if (nearestCacheEntry != null && cachePid != null) {
        if (currentHintFirstPid == null) {
          seedPage = nearestCacheEntry.resolvedPage;
        } else {
          final hintPage = currentHintDetail.currentPage;
          final cachePage = nearestCacheEntry.resolvedPage;

          if (cachePid > targetPidNumber &&
              currentHintFirstPid > targetPidNumber) {
            seedPage = cachePage < hintPage ? cachePage : hintPage;
          } else if (cachePid < targetPidNumber &&
              currentHintFirstPid < targetPidNumber) {
            seedPage = cachePage > hintPage ? cachePage : hintPage;
          } else if ((cachePid < targetPidNumber &&
                  targetPidNumber < currentHintFirstPid) ||
              (currentHintFirstPid < targetPidNumber &&
                  targetPidNumber < cachePid)) {
            final cacheDistance = (cachePid - targetPidNumber).abs();
            final hintDistance = (currentHintFirstPid - targetPidNumber).abs();
            seedPage = cacheDistance <= hintDistance ? cachePage : hintPage;
          }
        }
      }
    }

    seedPage = seedPage.clamp(1, totalPages).toInt();
    trace.addStep('hint_seed_page_final', <String, Object?>{
      'seedPage': seedPage,
      'totalPages': totalPages,
    });

    final directionalResult = await _scanDirectionalByPageRange(
      seedPage: seedPage,
      targetPid: normalizedPid,
      targetPidNumber: targetPidNumber,
      totalPages: totalPages,
      probeBudget: normalizedBudget,
      currentProbesUsed: () => probesUsed,
      probePage: probePage,
      trace: trace,
    );
    if (directionalResult != null) {
      _traceResult(trace, 'hint_directional_terminal', directionalResult);
      return directionalResult;
    }

    return fallbackPage1();
  }

  Future<ReplyPageLocateResult> _locateReplyPageLegacy({
    required String normalizedTid,
    required String normalizedPid,
    required int? targetPidNumber,
    required int normalizedBudget,
    required int coarseProbeStride,
    required bool useCache,
    required int? officialHintRaw,
    bool Function()? isCanceled,
    required _LocateTrace trace,
  }) async {
    trace.addStep('legacy_start', <String, Object?>{
      'targetPidNumber': targetPidNumber,
      'officialHintRaw': officialHintRaw,
      'normalizedBudget': normalizedBudget,
      'coarseProbeStride': coarseProbeStride,
      'useCache': useCache,
    });
    final Map<int, ThreadDetail> visitedPages = <int, ThreadDetail>{};
    int probesUsed = 0;
    bool budgetExhausted = false;

    Future<_ProbeOutcome> probePage(
      int page, {
      bool evaluate = true,
      bool countAgainstBudget = true,
    }) async {
      trace.addStep('legacy_probe_begin', <String, Object?>{
        'page': page,
        'evaluate': evaluate,
        'countAgainstBudget': countAgainstBudget,
        'probesUsed': probesUsed,
        'probeBudget': normalizedBudget,
        'alreadyVisited': visitedPages.containsKey(page),
      });
      if (_isCanceled(isCanceled)) {
        trace.addStep('legacy_probe_canceled', <String, Object?>{'page': page});
        return _ProbeOutcome(
          terminal: ReplyPageLocateResult.canceled(
            probesUsed: probesUsed,
            probeBudget: normalizedBudget,
          ),
        );
      }

      final existing = visitedPages[page];
      if (existing != null) {
        final terminal = evaluate
            ? _evaluatePage(
                detail: existing,
                targetPid: normalizedPid,
                targetPidNumber: targetPidNumber,
                probesUsed: probesUsed,
                probeBudget: normalizedBudget,
                trace: trace,
                stage: 'legacy_probe_reuse',
              )
            : null;
        if (terminal != null) {
          _traceResult(trace, 'legacy_probe_reuse_terminal', terminal);
        }
        return _ProbeOutcome(detail: existing, terminal: terminal);
      }

      if (countAgainstBudget && probesUsed >= normalizedBudget) {
        budgetExhausted = true;
        trace.addStep('legacy_probe_budget_reached', <String, Object?>{
          'page': page,
          'probesUsed': probesUsed,
          'probeBudget': normalizedBudget,
        });
        return const _ProbeOutcome();
      }

      if (countAgainstBudget) {
        probesUsed += 1;
      }
      final detailResult = await _threadDetailService.getThreadDetail(
        normalizedTid,
        page,
      );

      if (_isCanceled(isCanceled)) {
        trace.addStep('legacy_probe_canceled_after_fetch', <String, Object?>{
          'page': page,
          'probesUsed': probesUsed,
        });
        return _ProbeOutcome(
          terminal: ReplyPageLocateResult.canceled(
            probesUsed: probesUsed,
            probeBudget: normalizedBudget,
          ),
        );
      }

      ThreadDetail? detail;
      detailResult.when(
        success: (data) {
          detail = data;
        },
        failure: (_, __) {},
      );
      if (detail == null) {
        trace.addStep('legacy_probe_detail_missing', <String, Object?>{
          'page': page,
        });
        return const _ProbeOutcome();
      }

      visitedPages[page] = detail!;
      trace.addStep('legacy_probe_success', <String, Object?>{
        'page': page,
        ..._detailSummary(detail!),
      });
      final terminal = evaluate
          ? _evaluatePage(
              detail: detail!,
              targetPid: normalizedPid,
              targetPidNumber: targetPidNumber,
              probesUsed: probesUsed,
              probeBudget: normalizedBudget,
              trace: trace,
              stage: 'legacy_probe_evaluate',
            )
          : null;

      if (terminal != null) {
        _traceResult(trace, 'legacy_probe_terminal', terminal);
      }

      return _ProbeOutcome(detail: detail, terminal: terminal);
    }

    final firstPageOutcome = await probePage(1);
    final firstPageTerminal = firstPageOutcome.terminal;
    if (firstPageTerminal != null) {
      _traceResult(trace, 'legacy_first_page_terminal', firstPageTerminal);
      return firstPageTerminal;
    }

    final firstPageDetail = firstPageOutcome.detail;
    if (firstPageDetail == null) {
      if (budgetExhausted) {
        _budgetExhausted += 1;
      }
      trace.addStep('legacy_first_page_missing_fallback', <String, Object?>{
        'budgetExhausted': budgetExhausted,
        'probesUsed': probesUsed,
      });
      return ReplyPageLocateResult.fallbackPage1(
        probesUsed: probesUsed,
        probeBudget: normalizedBudget,
      );
    }

    final totalPages = firstPageDetail.totalPagesNum;
    final officialHint = _normalizeOfficialHint(
      officialHintRaw: officialHintRaw,
      totalPages: totalPages,
    );
    trace.addStep('legacy_official_hint_normalized', <String, Object?>{
      'officialHintRaw': officialHintRaw,
      'officialHint': officialHint,
      'totalPages': totalPages,
    });

    ThreadDetail? officialHintDetail;
    if (officialHint != null) {
      final officialOutcome = await probePage(officialHint);
      final officialTerminal = officialOutcome.terminal;
      if (officialTerminal != null) {
        if (officialTerminal.resolutionType == ReplyPageResolutionType.exact) {
          _officialHintHits += 1;
        }
        _traceResult(trace, 'legacy_official_terminal', officialTerminal);
        return officialTerminal;
      }
      officialHintDetail = officialOutcome.detail;
    }

    ThreadDetail? lastPageDetail = visitedPages[totalPages];
    if (lastPageDetail == null && totalPages > 1) {
      final lastPageOutcome = await probePage(totalPages);
      final lastPageTerminal = lastPageOutcome.terminal;
      if (lastPageTerminal != null) {
        _traceResult(trace, 'legacy_last_page_terminal', lastPageTerminal);
        return lastPageTerminal;
      }
      lastPageDetail = lastPageOutcome.detail;
    }

    final coarseIntervalOutcome = await _resolveCoarseInterpolationInterval(
      totalPages: totalPages,
      targetPidNumber: targetPidNumber,
      coarseProbeStride: coarseProbeStride,
      probePage: (int page) =>
          probePage(page, evaluate: false, countAgainstBudget: false),
      trace: trace,
      stage: 'legacy_coarse',
    );
    if (coarseIntervalOutcome.terminal != null) {
      _traceResult(
        trace,
        'legacy_coarse_terminal',
        coarseIntervalOutcome.terminal!,
      );
      return coarseIntervalOutcome.terminal!;
    }

    var interpolationLowerBound = firstPageDetail;
    var interpolationUpperBound = lastPageDetail ?? firstPageDetail;
    final coarseInterval = coarseIntervalOutcome.interval;
    if (coarseInterval != null) {
      interpolationLowerBound = coarseInterval.lowerBoundDetail;
      interpolationUpperBound = coarseInterval.upperBoundDetail;
      trace.addStep('legacy_coarse_interval_applied', <String, Object?>{
        'lowerPage': interpolationLowerBound.currentPage,
        'upperPage': interpolationUpperBound.currentPage,
        'lowerFirstPid': _firstReplyPid(interpolationLowerBound),
        'upperFirstPid': _firstReplyPid(interpolationUpperBound),
      });
    } else {
      trace.addStep('legacy_coarse_interval_unavailable_fallback_global');
    }

    ThreadDetail? interpolationDetail;
    final interpolationPage = _computeInterpolatedPage(
      totalPages: totalPages,
      targetPidNumber: targetPidNumber,
      lowerBoundDetail: interpolationLowerBound,
      upperBoundDetail: interpolationUpperBound,
      trace: trace,
      stage: 'legacy_interpolation',
    );
    trace.addStep('legacy_interpolation_page', <String, Object?>{
      'interpolationPage': interpolationPage,
    });

    if (interpolationPage != null) {
      final interpolationOutcome = await probePage(interpolationPage);
      final interpolationTerminal = interpolationOutcome.terminal;
      if (interpolationTerminal != null) {
        if (interpolationTerminal.resolutionType ==
            ReplyPageResolutionType.exact) {
          _interpolationHits += 1;
        }
        _traceResult(
          trace,
          'legacy_interpolation_terminal',
          interpolationTerminal,
        );
        return interpolationTerminal;
      }
      interpolationDetail = interpolationOutcome.detail;
    }

    int seedPage =
        (interpolationDetail ?? officialHintDetail ?? firstPageDetail)
            .currentPage;
    int? seedFirstPid = _parsePidNumber(
      _firstReplyPid(
        interpolationDetail ?? officialHintDetail ?? firstPageDetail,
      ),
    );

    if (useCache && officialHintDetail != null && targetPidNumber != null) {
      final nearestCacheEntry = await _cacheService.findNearestInThread(
        tid: normalizedTid,
        targetPid: normalizedPid,
      );
      final hintFirstPid = _parsePidNumber(_firstReplyPid(officialHintDetail));
      final cachePid = nearestCacheEntry == null
          ? null
          : _parsePidNumber(nearestCacheEntry.targetPid);
      trace.addStep('legacy_cache_nearest_result', <String, Object?>{
        'hasNearest': nearestCacheEntry != null,
        'nearestResolvedPage': nearestCacheEntry?.resolvedPage,
        'nearestTargetPid': nearestCacheEntry?.targetPid,
        'hintFirstPid': hintFirstPid,
        'cachePid': cachePid,
      });

      if (hintFirstPid != null && hintFirstPid == targetPidNumber) {
        final result = ReplyPageLocateResult.exact(
          page: officialHintDetail.currentPage,
          probesUsed: probesUsed,
          probeBudget: normalizedBudget,
        );
        _traceResult(trace, 'legacy_seed_exact_from_hint_first_pid', result);
        return result;
      }

      if (nearestCacheEntry != null &&
          cachePid != null &&
          cachePid == targetPidNumber) {
        final result = _resultFromCacheEntry(
          nearestCacheEntry,
          normalizedBudget,
        );
        _traceResult(trace, 'legacy_seed_exact_from_cache_pid', result);
        return result;
      }

      if (nearestCacheEntry != null &&
          cachePid != null &&
          hintFirstPid != null) {
        final hintPage = officialHintDetail.currentPage;
        final cachePage = nearestCacheEntry.resolvedPage;

        if (cachePid > targetPidNumber && hintFirstPid > targetPidNumber) {
          seedPage = cachePage < hintPage ? cachePage : hintPage;
        } else if (cachePid < targetPidNumber &&
            hintFirstPid < targetPidNumber) {
          seedPage = cachePage > hintPage ? cachePage : hintPage;
        } else if ((cachePid < targetPidNumber &&
                targetPidNumber < hintFirstPid) ||
            (hintFirstPid < targetPidNumber && targetPidNumber < cachePid)) {
          final cacheDistance = (cachePid - targetPidNumber).abs();
          final hintDistance = (hintFirstPid - targetPidNumber).abs();
          seedPage = cacheDistance <= hintDistance ? cachePage : hintPage;
        }

        seedPage = seedPage.clamp(1, totalPages).toInt();
        final selectedSeedDetail = visitedPages[seedPage];
        seedFirstPid = selectedSeedDetail == null
            ? null
            : _parsePidNumber(_firstReplyPid(selectedSeedDetail));
      }
    }

    trace.addStep('legacy_seed_final', <String, Object?>{
      'seedPage': seedPage,
      'seedFirstPid': seedFirstPid,
      'totalPages': totalPages,
    });

    final firstPidDirectionalTerminal = await _scanDirectionalByFirstPid(
      seedPage: seedPage,
      seedFirstPid: seedFirstPid,
      targetPid: normalizedPid,
      targetPidNumber: targetPidNumber,
      totalPages: totalPages,
      probeBudget: normalizedBudget,
      currentProbesUsed: () => probesUsed,
      visitedPages: visitedPages,
      probePage: probePage,
      trace: trace,
    );

    if (firstPidDirectionalTerminal != null) {
      _traceResult(
        trace,
        'legacy_first_pid_directional_terminal',
        firstPidDirectionalTerminal,
      );
      return firstPidDirectionalTerminal;
    }

    final directionalCandidates = _buildDirectionalCandidates(
      seedPage: seedPage,
      seedFirstPid: seedFirstPid,
      targetPidNumber: targetPidNumber,
      totalPages: totalPages,
      visitedPages: visitedPages.keys.toSet(),
    );

    for (final page in directionalCandidates) {
      trace.addStep('legacy_directional_candidate_probe', <String, Object?>{
        'page': page,
      });
      final outcome = await probePage(page);
      final terminal = outcome.terminal;
      if (terminal != null) {
        _traceResult(trace, 'legacy_directional_candidate_terminal', terminal);
        return terminal;
      }
      if (_isCanceled(isCanceled)) {
        final canceledResult = ReplyPageLocateResult.canceled(
          probesUsed: probesUsed,
          probeBudget: normalizedBudget,
        );
        _traceResult(trace, 'legacy_directional_canceled', canceledResult);
        return canceledResult;
      }
      if (probesUsed >= normalizedBudget) {
        budgetExhausted = true;
        trace.addStep('legacy_directional_budget_reached', <String, Object?>{
          'probesUsed': probesUsed,
          'probeBudget': normalizedBudget,
        });
        break;
      }
    }

    if (budgetExhausted) {
      _budgetExhausted += 1;
      trace.addStep('legacy_budget_exhausted_counter_incremented');
    }
    trace.addStep('legacy_fallback_page1', <String, Object?>{
      'probesUsed': probesUsed,
      'probeBudget': normalizedBudget,
    });
    return ReplyPageLocateResult.fallbackPage1(
      probesUsed: probesUsed,
      probeBudget: normalizedBudget,
    );
  }

  ReplyPageLocateResult _finalize({
    required String tid,
    required String pid,
    required ReplyPageLocateResult result,
    required bool useCache,
  }) {
    switch (result.resolutionType) {
      case ReplyPageResolutionType.bracket:
        _bracketHits += 1;
        break;
      case ReplyPageResolutionType.errorOutOfLowBound:
        _lowBoundErrors += 1;
        break;
      case ReplyPageResolutionType.tailLastPage:
        _tailLastPageHits += 1;
        break;
      case ReplyPageResolutionType.canceled:
        _canceled += 1;
        break;
      case ReplyPageResolutionType.exact:
      case ReplyPageResolutionType.fallbackPage1:
        break;
    }

    if (!useCache || !result.shouldNavigate || result.resolvedPage == null) {
      return result;
    }

    if (result.resolutionType == ReplyPageResolutionType.fallbackPage1) {
      return result;
    }

    unawaited(
      _cacheService.put(
        tid: tid,
        targetPid: pid,
        resolvedPage: result.resolvedPage!,
        resolutionType: result.resolutionType.name,
        message: result.message,
      ),
    );
    return result;
  }

  ReplyPageLocateResult _resultFromCacheEntry(
    ReplyPageLocatorCacheEntry entry,
    int probeBudget,
  ) {
    return ReplyPageLocateResult._(
      resolvedPage: entry.resolvedPage,
      resolutionType: _resolutionTypeFromName(entry.resolutionType),
      message: entry.message,
      probesUsed: 0,
      probeBudget: probeBudget,
    );
  }

  ReplyPageResolutionType _resolutionTypeFromName(String rawType) {
    return switch (rawType) {
      'exact' => ReplyPageResolutionType.exact,
      'bracket' => ReplyPageResolutionType.bracket,
      'tailLastPage' => ReplyPageResolutionType.tailLastPage,
      'errorOutOfLowBound' => ReplyPageResolutionType.errorOutOfLowBound,
      'fallbackPage1' => ReplyPageResolutionType.fallbackPage1,
      'canceled' => ReplyPageResolutionType.canceled,
      _ => ReplyPageResolutionType.exact,
    };
  }

  ReplyPageLocateResult? _resolveCandidatePageResult({
    required ThreadDetail detail,
    required String targetPid,
    required int targetPidNumber,
    required int probesUsed,
    required int probeBudget,
    _LocateTrace? trace,
    String? stage,
  }) {
    final relation = _classifyPageRange(detail, targetPidNumber);
    trace?.addStep('compare_page_range', <String, Object?>{
      'stage': stage,
      'targetPidNumber': targetPidNumber,
      'relation': relation.name,
      ..._detailSummary(detail),
    });
    if (relation != _PageTargetRelation.within) {
      return null;
    }

    final evaluatedResult = _evaluateCandidatePage(
      detail: detail,
      targetPid: targetPid,
      targetPidNumber: targetPidNumber,
      probesUsed: probesUsed,
      probeBudget: probeBudget,
    );
    trace?.addStep('compare_candidate_page', <String, Object?>{
      'stage': stage,
      'resultResolutionType': evaluatedResult?.resolutionType.name,
      'resolvedPage': evaluatedResult?.resolvedPage,
      'probesUsed': probesUsed,
    });

    return evaluatedResult ??
        ReplyPageLocateResult.fallbackPage1(
          probesUsed: probesUsed,
          probeBudget: probeBudget,
        );
  }

  ReplyPageLocateResult? _resolveLowBoundResult({
    required ThreadDetail detail,
    required int targetPidNumber,
    required int probesUsed,
    required int probeBudget,
    _LocateTrace? trace,
    String? stage,
  }) {
    final firstReplyPidNumber = _parsePidNumber(_firstReplyPid(detail));
    trace?.addStep('compare_low_bound', <String, Object?>{
      'stage': stage,
      'currentPage': detail.currentPage,
      'targetPidNumber': targetPidNumber,
      'firstReplyPidNumber': firstReplyPidNumber,
    });
    if (detail.currentPage <= 1 &&
        firstReplyPidNumber != null &&
        targetPidNumber < firstReplyPidNumber) {
      return ReplyPageLocateResult.errorOutOfLowBound(
        probesUsed: probesUsed,
        probeBudget: probeBudget,
      );
    }
    return null;
  }

  ReplyPageLocateResult? _resolveTailLastPageResult({
    required ThreadDetail detail,
    required int targetPidNumber,
    required int probesUsed,
    required int probeBudget,
    _LocateTrace? trace,
    String? stage,
  }) {
    final lastReplyPidNumber = _parsePidNumber(_lastReplyPid(detail));
    trace?.addStep('compare_tail_last_page', <String, Object?>{
      'stage': stage,
      'currentPage': detail.currentPage,
      'totalPages': detail.totalPagesNum,
      'targetPidNumber': targetPidNumber,
      'lastReplyPidNumber': lastReplyPidNumber,
    });
    if (detail.currentPage >= detail.totalPagesNum &&
        lastReplyPidNumber != null &&
        targetPidNumber > lastReplyPidNumber) {
      return ReplyPageLocateResult.tailLastPage(
        page: detail.currentPage,
        probesUsed: probesUsed,
        probeBudget: probeBudget,
      );
    }
    return null;
  }

  ReplyPageLocateResult? _evaluateCandidatePage({
    required ThreadDetail detail,
    required String targetPid,
    required int targetPidNumber,
    required int probesUsed,
    required int probeBudget,
  }) {
    if (_containsExactPid(detail, targetPid)) {
      return ReplyPageLocateResult.exact(
        page: detail.currentPage,
        probesUsed: probesUsed,
        probeBudget: probeBudget,
      );
    }

    if (_containsBracket(detail.replies, targetPidNumber)) {
      return ReplyPageLocateResult.bracket(
        page: detail.currentPage,
        probesUsed: probesUsed,
        probeBudget: probeBudget,
      );
    }

    return null;
  }

  ReplyPageLocateResult? _evaluatePage({
    required ThreadDetail detail,
    required String targetPid,
    required int? targetPidNumber,
    required int probesUsed,
    required int probeBudget,
    _LocateTrace? trace,
    String? stage,
  }) {
    if (targetPidNumber != null) {
      final candidateResult = _evaluateCandidatePage(
        detail: detail,
        targetPid: targetPid,
        targetPidNumber: targetPidNumber,
        probesUsed: probesUsed,
        probeBudget: probeBudget,
      );
      trace?.addStep('evaluate_page_candidate', <String, Object?>{
        'stage': stage,
        'targetPidNumber': targetPidNumber,
        'resultResolutionType': candidateResult?.resolutionType.name,
        ..._detailSummary(detail),
      });
      if (candidateResult != null) {
        return candidateResult;
      }
    } else if (_containsExactPid(detail, targetPid)) {
      trace?.addStep(
        'evaluate_page_exact_without_numeric_pid',
        <String, Object?>{
          'stage': stage,
          'targetPid': targetPid,
          ..._detailSummary(detail),
        },
      );
      return ReplyPageLocateResult.exact(
        page: detail.currentPage,
        probesUsed: probesUsed,
        probeBudget: probeBudget,
      );
    }

    final firstReplyPidNumber = _parsePidNumber(_firstReplyPid(detail));
    trace?.addStep('evaluate_page_boundary_compare', <String, Object?>{
      'stage': stage,
      'targetPidNumber': targetPidNumber,
      'firstReplyPidNumber': firstReplyPidNumber,
      'currentPage': detail.currentPage,
      'totalPages': detail.totalPagesNum,
    });
    if (targetPidNumber != null && firstReplyPidNumber != null) {
      if (detail.currentPage <= 1 && targetPidNumber < firstReplyPidNumber) {
        return ReplyPageLocateResult.errorOutOfLowBound(
          probesUsed: probesUsed,
          probeBudget: probeBudget,
        );
      }
      if (detail.currentPage >= detail.totalPagesNum &&
          targetPidNumber > firstReplyPidNumber) {
        return ReplyPageLocateResult.tailLastPage(
          page: detail.currentPage,
          probesUsed: probesUsed,
          probeBudget: probeBudget,
        );
      }
    }

    return null;
  }

  bool _containsExactPid(ThreadDetail detail, String targetPid) {
    for (final reply in detail.replies) {
      if (reply.pid == targetPid) {
        return true;
      }
    }
    return false;
  }

  bool _containsBracket(List<SingleReplyFloor> replies, int targetPidNumber) {
    if (replies.length < 2) {
      return false;
    }

    for (var index = 1; index < replies.length; index += 1) {
      final previous = _parsePidNumber(replies[index - 1].pid);
      final current = _parsePidNumber(replies[index].pid);
      if (previous == null || current == null) {
        continue;
      }
      if (previous < targetPidNumber && targetPidNumber < current) {
        return true;
      }
    }

    return false;
  }

  int? _computeInterpolatedPage({
    required int totalPages,
    required int? targetPidNumber,
    required ThreadDetail lowerBoundDetail,
    required ThreadDetail upperBoundDetail,
    _LocateTrace? trace,
    String? stage,
  }) {
    if (targetPidNumber == null || totalPages <= 1) {
      trace?.addStep('interpolation_skipped', <String, Object?>{
        'stage': stage,
        'targetPidNumber': targetPidNumber,
        'totalPages': totalPages,
      });
      return null;
    }

    var lowerDetail = lowerBoundDetail;
    var upperDetail = upperBoundDetail;

    var lowerPage = lowerDetail.currentPage.clamp(1, totalPages).toInt();
    var upperPage = upperDetail.currentPage.clamp(1, totalPages).toInt();
    if (lowerPage > upperPage) {
      final swapDetail = lowerDetail;
      lowerDetail = upperDetail;
      upperDetail = swapDetail;

      final swapPage = lowerPage;
      lowerPage = upperPage;
      upperPage = swapPage;
    }

    if (lowerPage == upperPage) {
      trace?.addStep('interpolation_single_page_bounds', <String, Object?>{
        'stage': stage,
        'targetPidNumber': targetPidNumber,
        'page': lowerPage,
      });
      return lowerPage;
    }

    final lowerFirstPidNumber = _parsePidNumber(_firstReplyPid(lowerDetail));
    final upperFirstPidNumber = _parsePidNumber(_firstReplyPid(upperDetail));

    if (lowerFirstPidNumber == null || upperFirstPidNumber == null) {
      trace?.addStep('interpolation_missing_boundary_pid', <String, Object?>{
        'stage': stage,
        'lowerPage': lowerPage,
        'upperPage': upperPage,
        'lowerFirstPidNumber': lowerFirstPidNumber,
        'upperFirstPidNumber': upperFirstPidNumber,
      });
      return null;
    }

    final denominator = upperFirstPidNumber - lowerFirstPidNumber;
    if (denominator <= 0) {
      trace?.addStep('interpolation_invalid_denominator', <String, Object?>{
        'stage': stage,
        'denominator': denominator,
        'lowerPage': lowerPage,
        'upperPage': upperPage,
        'lowerFirstPidNumber': lowerFirstPidNumber,
        'upperFirstPidNumber': upperFirstPidNumber,
      });
      return null;
    }

    final ratio = (targetPidNumber - lowerFirstPidNumber) / denominator;
    if (!ratio.isFinite) {
      trace?.addStep('interpolation_non_finite_ratio', <String, Object?>{
        'stage': stage,
        'ratio': ratio,
      });
      return null;
    }

    final pageSpan = upperPage - lowerPage;
    final interpolated = lowerPage + (ratio * pageSpan).floor();
    final clamped = interpolated.clamp(lowerPage, upperPage).toInt();
    trace?.addStep('interpolation_computed', <String, Object?>{
      'stage': stage,
      'targetPidNumber': targetPidNumber,
      'lowerPage': lowerPage,
      'upperPage': upperPage,
      'lowerFirstPidNumber': lowerFirstPidNumber,
      'upperFirstPidNumber': upperFirstPidNumber,
      'ratio': ratio,
      'pageSpan': pageSpan,
      'interpolated': interpolated,
      'clamped': clamped,
      'totalPages': totalPages,
    });
    return clamped;
  }

  Future<ReplyPageLocateResult?> _scanDirectionalByPageRange({
    required int seedPage,
    required String targetPid,
    required int targetPidNumber,
    required int totalPages,
    required int probeBudget,
    required int Function() currentProbesUsed,
    required Future<_ProbeOutcome> Function(int page) probePage,
    _LocateTrace? trace,
  }) async {
    var currentPage = seedPage.clamp(1, totalPages).toInt();
    final scannedPages = <int>{};
    int? direction;

    while (!scannedPages.contains(currentPage)) {
      scannedPages.add(currentPage);
      trace?.addStep('scan_by_page_range_iteration', <String, Object?>{
        'currentPage': currentPage,
        'targetPidNumber': targetPidNumber,
        'direction': direction,
      });

      final outcome = await probePage(currentPage);
      if (outcome.terminal != null) {
        _traceResult(
          trace,
          'scan_by_page_range_probe_terminal',
          outcome.terminal!,
        );
        return outcome.terminal;
      }

      final detail = outcome.detail;
      if (detail == null) {
        return null;
      }

      switch (_classifyPageRange(detail, targetPidNumber)) {
        case _PageTargetRelation.within:
          trace?.addStep('scan_by_page_range_relation', <String, Object?>{
            'relation': _PageTargetRelation.within.name,
            'currentPage': currentPage,
            ..._detailSummary(detail),
          });
          return _evaluateCandidatePage(
                detail: detail,
                targetPid: targetPid,
                targetPidNumber: targetPidNumber,
                probesUsed: currentProbesUsed(),
                probeBudget: probeBudget,
              ) ??
              ReplyPageLocateResult.fallbackPage1(
                probesUsed: currentProbesUsed(),
                probeBudget: probeBudget,
              );
        case _PageTargetRelation.before:
          trace?.addStep('scan_by_page_range_relation', <String, Object?>{
            'relation': _PageTargetRelation.before.name,
            'currentPage': currentPage,
            ..._detailSummary(detail),
          });
          if (detail.currentPage <= 1) {
            return ReplyPageLocateResult.errorOutOfLowBound(
              probesUsed: currentProbesUsed(),
              probeBudget: probeBudget,
            );
          }
          direction = -1;
          break;
        case _PageTargetRelation.after:
          trace?.addStep('scan_by_page_range_relation', <String, Object?>{
            'relation': _PageTargetRelation.after.name,
            'currentPage': currentPage,
            ..._detailSummary(detail),
          });
          if (detail.currentPage >= totalPages) {
            return ReplyPageLocateResult.tailLastPage(
              page: detail.currentPage,
              probesUsed: currentProbesUsed(),
              probeBudget: probeBudget,
            );
          }
          direction = 1;
          break;
        case _PageTargetRelation.unknown:
          trace?.addStep('scan_by_page_range_relation', <String, Object?>{
            'relation': _PageTargetRelation.unknown.name,
            'currentPage': currentPage,
            ..._detailSummary(detail),
          });
          if (direction == null) {
            return null;
          }
          break;
      }

      final nextPage = currentPage + direction;
      if (nextPage < 1 || nextPage > totalPages) {
        trace?.addStep(
          'scan_by_page_range_next_page_out_of_bounds',
          <String, Object?>{
            'currentPage': currentPage,
            'nextPage': nextPage,
            'totalPages': totalPages,
          },
        );
        return null;
      }
      currentPage = nextPage;
    }

    return null;
  }

  Future<ReplyPageLocateResult?> _scanDirectionalByFirstPid({
    required int seedPage,
    required int? seedFirstPid,
    required String targetPid,
    required int? targetPidNumber,
    required int totalPages,
    required int probeBudget,
    required int Function() currentProbesUsed,
    required Map<int, ThreadDetail> visitedPages,
    required Future<_ProbeOutcome> Function(int page, {bool evaluate})
    probePage,
    _LocateTrace? trace,
  }) async {
    if (targetPidNumber == null) {
      trace?.addStep('scan_by_first_pid_skipped', <String, Object?>{
        'reason': 'target_pid_not_numeric',
      });
      return null;
    }

    ThreadDetail? seedDetail = visitedPages[seedPage];
    if (seedDetail == null) {
      final seedOutcome = await probePage(seedPage, evaluate: false);
      if (seedOutcome.terminal != null) {
        _traceResult(
          trace,
          'scan_by_first_pid_seed_terminal',
          seedOutcome.terminal!,
        );
        return seedOutcome.terminal;
      }
      seedDetail = seedOutcome.detail;
      if (seedDetail == null) {
        return null;
      }
    }

    final resolvedSeedFirstPid =
        seedFirstPid ?? _parsePidNumber(_firstReplyPid(seedDetail));
    if (resolvedSeedFirstPid == null) {
      trace?.addStep('scan_by_first_pid_seed_missing', <String, Object?>{
        'seedPage': seedPage,
      });
      return null;
    }

    trace?.addStep('scan_by_first_pid_seed', <String, Object?>{
      'seedPage': seedPage,
      'resolvedSeedFirstPid': resolvedSeedFirstPid,
      'targetPidNumber': targetPidNumber,
      'totalPages': totalPages,
    });

    if (resolvedSeedFirstPid == targetPidNumber) {
      return ReplyPageLocateResult.exact(
        page: seedPage,
        probesUsed: currentProbesUsed(),
        probeBudget: probeBudget,
      );
    }

    final step = resolvedSeedFirstPid < targetPidNumber ? 1 : -1;
    var previousPage = seedPage;
    var previousFirstPid = resolvedSeedFirstPid;
    var edgePage = seedPage;

    for (
      var page = seedPage + step;
      page >= 1 && page <= totalPages;
      page += step
    ) {
      trace?.addStep('scan_by_first_pid_iteration', <String, Object?>{
        'page': page,
        'step': step,
        'targetPidNumber': targetPidNumber,
      });
      final outcome = await probePage(page, evaluate: false);
      if (outcome.terminal != null) {
        _traceResult(
          trace,
          'scan_by_first_pid_probe_terminal',
          outcome.terminal!,
        );
        return outcome.terminal;
      }

      final detail = outcome.detail;
      if (detail == null) {
        continue;
      }

      edgePage = page;
      final currentFirstPid = _parsePidNumber(_firstReplyPid(detail));
      if (currentFirstPid == null) {
        trace?.addStep('scan_by_first_pid_current_missing', <String, Object?>{
          'page': page,
        });
        continue;
      }

      trace?.addStep('scan_by_first_pid_compare', <String, Object?>{
        'page': page,
        'previousFirstPid': previousFirstPid,
        'currentFirstPid': currentFirstPid,
        'targetPidNumber': targetPidNumber,
      });

      if (currentFirstPid == targetPidNumber) {
        return ReplyPageLocateResult.exact(
          page: page,
          probesUsed: currentProbesUsed(),
          probeBudget: probeBudget,
        );
      }

      final crossedBoundary = step > 0
          ? previousFirstPid < targetPidNumber &&
                targetPidNumber < currentFirstPid
          : currentFirstPid < targetPidNumber &&
                targetPidNumber < previousFirstPid;
      if (crossedBoundary) {
        final fineScanPage = step > 0 ? previousPage : page;
        final fineScanDetail = visitedPages[fineScanPage];
        if (fineScanDetail == null) {
          return ReplyPageLocateResult.fallbackPage1(
            probesUsed: currentProbesUsed(),
            probeBudget: probeBudget,
          );
        }

        final fineScanResult = _evaluatePage(
          detail: fineScanDetail,
          targetPid: targetPid,
          targetPidNumber: targetPidNumber,
          probesUsed: currentProbesUsed(),
          probeBudget: probeBudget,
          trace: trace,
          stage: 'scan_by_first_pid_fine_scan',
        );
        return fineScanResult ??
            ReplyPageLocateResult.fallbackPage1(
              probesUsed: currentProbesUsed(),
              probeBudget: probeBudget,
            );
      }

      previousPage = page;
      previousFirstPid = currentFirstPid;
    }

    final edgeDetail = visitedPages[edgePage];
    if (edgeDetail != null) {
      return _evaluatePage(
        detail: edgeDetail,
        targetPid: targetPid,
        targetPidNumber: targetPidNumber,
        probesUsed: currentProbesUsed(),
        probeBudget: probeBudget,
        trace: trace,
        stage: 'scan_by_first_pid_edge',
      );
    }

    return null;
  }

  List<int> _buildDirectionalCandidates({
    required int seedPage,
    required int? seedFirstPid,
    required int? targetPidNumber,
    required int totalPages,
    required Set<int> visitedPages,
  }) {
    final candidates = <int>[];

    if (seedFirstPid != null && targetPidNumber != null) {
      if (seedFirstPid < targetPidNumber) {
        for (var page = seedPage + 1; page <= totalPages; page += 1) {
          if (!visitedPages.contains(page)) {
            candidates.add(page);
          }
        }
        return candidates;
      }

      if (seedFirstPid > targetPidNumber) {
        for (var page = seedPage - 1; page >= 1; page -= 1) {
          if (!visitedPages.contains(page)) {
            candidates.add(page);
          }
        }
        return candidates;
      }
    }

    final remaining = [
      for (var page = 1; page <= totalPages; page += 1)
        if (!visitedPages.contains(page)) page,
    ];

    remaining.sort((left, right) {
      final leftDistance = (left - seedPage).abs();
      final rightDistance = (right - seedPage).abs();
      if (leftDistance != rightDistance) {
        return leftDistance.compareTo(rightDistance);
      }
      return left.compareTo(right);
    });

    return remaining;
  }

  List<int> _buildCoarseProbePages(int totalPages, int coarseProbeStride) {
    if (totalPages < 1) {
      return const <int>[];
    }

    final normalizedStride = coarseProbeStride < 1
        ? AppSettings.defaultReplyLocateCoarseProbeStride
        : coarseProbeStride;

    final pages = <int>[1];
    for (
      var page = 1 + normalizedStride;
      page <= totalPages;
      page += normalizedStride
    ) {
      pages.add(page);
    }

    if (pages.last != totalPages) {
      pages.add(totalPages);
    }

    return pages;
  }

  Future<_CoarseIntervalOutcome> _resolveCoarseInterpolationInterval({
    required int totalPages,
    required int? targetPidNumber,
    required int coarseProbeStride,
    required Future<_ProbeOutcome> Function(int page) probePage,
    _LocateTrace? trace,
    String? stage,
  }) async {
    if (targetPidNumber == null || totalPages <= 1) {
      trace?.addStep('coarse_probe_skipped', <String, Object?>{
        'stage': stage,
        'reason': targetPidNumber == null
            ? 'target_pid_not_numeric'
            : 'single_page_thread',
        'totalPages': totalPages,
      });
      return const _CoarseIntervalOutcome();
    }

    final coarsePages = _buildCoarseProbePages(totalPages, coarseProbeStride);
    trace?.addStep('coarse_probe_start', <String, Object?>{
      'stage': stage,
      'targetPidNumber': targetPidNumber,
      'totalPages': totalPages,
      'coarseProbeStride': coarseProbeStride,
      'pages': coarsePages,
    });

    final anchors = <_CoarseProbeAnchor>[];
    _CoarseProbeAnchor? lowerAnchor;
    _CoarseProbeAnchor? upperAnchor;

    for (final page in coarsePages) {
      final outcome = await probePage(page);
      if (outcome.terminal != null) {
        _traceResult(trace, 'coarse_probe_terminal', outcome.terminal!);
        return _CoarseIntervalOutcome(terminal: outcome.terminal);
      }

      final detail = outcome.detail;
      if (detail == null) {
        trace?.addStep('coarse_probe_missing_detail', <String, Object?>{
          'stage': stage,
          'page': page,
        });
        continue;
      }

      final firstPidNumber = _parsePidNumber(_firstReplyPid(detail));
      trace?.addStep('coarse_probe_anchor', <String, Object?>{
        'stage': stage,
        'page': detail.currentPage,
        'firstPidNumber': firstPidNumber,
        ..._detailSummary(detail),
      });
      if (firstPidNumber == null) {
        continue;
      }

      anchors.add(
        _CoarseProbeAnchor(
          page: detail.currentPage,
          firstPidNumber: firstPidNumber,
          detail: detail,
        ),
      );

      if (anchors.length < 2) {
        continue;
      }

      final previous = anchors[anchors.length - 2];
      final current = anchors[anchors.length - 1];

      if (current.firstPidNumber <= previous.firstPidNumber) {
        continue;
      }

      if (targetPidNumber == current.firstPidNumber) {
        lowerAnchor = current;
        upperAnchor = current;
        trace
            ?.addStep('coarse_probe_early_exit_exact_anchor', <String, Object?>{
              'stage': stage,
              'matchedPage': current.page,
              'matchedFirstPid': current.firstPidNumber,
              'anchorsProbed': anchors.length,
            });
        break;
      }

      if (previous.firstPidNumber < targetPidNumber &&
          targetPidNumber < current.firstPidNumber) {
        lowerAnchor = previous;
        upperAnchor = current;
        trace?.addStep('coarse_probe_early_exit_interval', <String, Object?>{
          'stage': stage,
          'targetPidNumber': targetPidNumber,
          'lowerPage': previous.page,
          'upperPage': current.page,
          'lowerFirstPid': previous.firstPidNumber,
          'upperFirstPid': current.firstPidNumber,
          'anchorsProbed': anchors.length,
        });
        break;
      }
    }

    if (anchors.length < 2) {
      trace?.addStep('coarse_probe_interval_unavailable', <String, Object?>{
        'stage': stage,
        'reason': 'insufficient_anchors',
        'anchorsCount': anchors.length,
      });
      return const _CoarseIntervalOutcome();
    }

    if (lowerAnchor == null || upperAnchor == null) {
      if (targetPidNumber <= anchors.first.firstPidNumber) {
        lowerAnchor = anchors.first;
        upperAnchor = anchors[1];
      } else {
        for (var index = 1; index < anchors.length; index += 1) {
          final previous = anchors[index - 1];
          final current = anchors[index];

          if (current.firstPidNumber <= previous.firstPidNumber) {
            trace?.addStep('coarse_probe_non_monotonic_pair', <String, Object?>{
              'stage': stage,
              'leftPage': previous.page,
              'leftFirstPid': previous.firstPidNumber,
              'rightPage': current.page,
              'rightFirstPid': current.firstPidNumber,
            });
            continue;
          }

          if (targetPidNumber == current.firstPidNumber) {
            lowerAnchor = current;
            upperAnchor = current;
            break;
          }

          if (previous.firstPidNumber < targetPidNumber &&
              targetPidNumber < current.firstPidNumber) {
            lowerAnchor = previous;
            upperAnchor = current;
            break;
          }
        }
      }
    }

    if (lowerAnchor == null || upperAnchor == null) {
      if (targetPidNumber > anchors.last.firstPidNumber) {
        lowerAnchor = anchors[anchors.length - 2];
        upperAnchor = anchors.last;
      } else {
        trace?.addStep('coarse_probe_interval_unavailable', <String, Object?>{
          'stage': stage,
          'reason': 'target_not_bracketed_by_anchors',
          'targetPidNumber': targetPidNumber,
          'anchorsCount': anchors.length,
        });
        return const _CoarseIntervalOutcome();
      }
    }

    final interval = _CoarseInterpolationInterval(
      lowerBoundDetail: lowerAnchor.detail,
      upperBoundDetail: upperAnchor.detail,
    );
    trace?.addStep('coarse_probe_interval_selected', <String, Object?>{
      'stage': stage,
      'targetPidNumber': targetPidNumber,
      'lowerPage': interval.lowerBoundDetail.currentPage,
      'upperPage': interval.upperBoundDetail.currentPage,
      'lowerFirstPid': lowerAnchor.firstPidNumber,
      'upperFirstPid': upperAnchor.firstPidNumber,
    });
    return _CoarseIntervalOutcome(interval: interval);
  }

  Future<int?> _fetchOfficialHintPage({
    required String tid,
    required String pid,
  }) async {
    final uri = Uri.parse(
      _officialHintBaseUrl,
    ).replace(queryParameters: <String, String>{'tid': tid, 'pid': pid});

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map) {
        return null;
      }

      final page = parseNullableInt(payload['data']);
      if (page == null || page < 1) {
        return null;
      }
      return page;
    } catch (_) {
      return null;
    }
  }

  int? _normalizeOfficialHint({
    required int? officialHintRaw,
    required int totalPages,
  }) {
    if (officialHintRaw == null) {
      return null;
    }
    if (officialHintRaw < 1 || officialHintRaw > totalPages) {
      return null;
    }
    return officialHintRaw;
  }

  int _normalizeBudget(int rawBudget) {
    if (rawBudget < 1) {
      return 1;
    }
    if (rawBudget > _internalMaxProbeBudget) {
      return _internalMaxProbeBudget;
    }
    return rawBudget;
  }

  int _normalizeCoarseProbeStride(int rawStride) {
    return rawStride
        .clamp(
          AppSettings.minReplyLocateCoarseProbeStride,
          AppSettings.maxReplyLocateCoarseProbeStride,
        )
        .toInt();
  }

  String? _firstReplyPid(ThreadDetail detail) {
    if (detail.replies.isNotEmpty) {
      return detail.replies.first.pid;
    }
    return null;
  }

  String? _lastReplyPid(ThreadDetail detail) {
    if (detail.replies.isNotEmpty) {
      return detail.replies.last.pid;
    }
    return null;
  }

  _PageTargetRelation _classifyPageRange(
    ThreadDetail detail,
    int targetPidNumber,
  ) {
    final firstPidNumber = _parsePidNumber(_firstReplyPid(detail));
    final lastPidNumber = _parsePidNumber(_lastReplyPid(detail));
    if (firstPidNumber == null || lastPidNumber == null) {
      return _PageTargetRelation.unknown;
    }
    if (firstPidNumber > targetPidNumber) {
      return _PageTargetRelation.before;
    }
    if (lastPidNumber < targetPidNumber) {
      return _PageTargetRelation.after;
    }
    return _PageTargetRelation.within;
  }

  int? _parsePidNumber(String? rawPid) {
    if (rawPid == null || rawPid.isEmpty) {
      return null;
    }
    return int.tryParse(rawPid);
  }

  Map<String, Object?> _detailSummary(ThreadDetail detail) {
    return <String, Object?>{
      'currentPage': detail.currentPage,
      'totalPages': detail.totalPagesNum,
      'repliesCount': detail.replies.length,
      'firstReplyPid': _firstReplyPid(detail),
      'lastReplyPid': _lastReplyPid(detail),
    };
  }

  void _traceResult(
    _LocateTrace? trace,
    String stage,
    ReplyPageLocateResult result,
  ) {
    trace?.addStep(stage, <String, Object?>{
      'resolutionType': result.resolutionType.name,
      'resolvedPage': result.resolvedPage,
      'probesUsed': result.probesUsed,
      'probeBudget': result.probeBudget,
      'shouldNavigate': result.shouldNavigate,
      'message': result.message,
    });
  }

  Future<void> _persistTraceRecord(ReplyPageLocatorLogRecord record) async {
    if (!_shouldWriteJumpLogs()) {
      return;
    }

    try {
      await _logWriter.writeRecord(record);
    } catch (error, stackTrace) {
      debugPrint('Reply page locator log persistence failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool _isCanceled(bool Function()? isCanceled) {
    return isCanceled?.call() == true;
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

class _CoarseProbeAnchor {
  final int page;
  final int firstPidNumber;
  final ThreadDetail detail;

  const _CoarseProbeAnchor({
    required this.page,
    required this.firstPidNumber,
    required this.detail,
  });
}

class _CoarseInterpolationInterval {
  final ThreadDetail lowerBoundDetail;
  final ThreadDetail upperBoundDetail;

  const _CoarseInterpolationInterval({
    required this.lowerBoundDetail,
    required this.upperBoundDetail,
  });
}

class _CoarseIntervalOutcome {
  final _CoarseInterpolationInterval? interval;
  final ReplyPageLocateResult? terminal;

  const _CoarseIntervalOutcome({this.interval, this.terminal});
}

class _ProbeOutcome {
  final ThreadDetail? detail;
  final ReplyPageLocateResult? terminal;

  const _ProbeOutcome({this.detail, this.terminal});
}

enum _PageTargetRelation { before, after, within, unknown }

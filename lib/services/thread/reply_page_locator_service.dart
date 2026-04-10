import 'dart:async';
import 'dart:convert';

import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/thread/single_reply_floor.dart';
import 'package:bluefish/models/thread/thread_detail.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_log_models.dart';
import 'package:bluefish/services/thread/reply_page_locator_log_sink.dart';
import 'package:bluefish/services/thread/reply_page_locator_models.dart';
import 'package:bluefish/services/thread/thread_detail_service.dart';
import 'package:bluefish/userdata/reply_page_locator_cache_store.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

export 'reply_page_locator_models.dart';

part 'reply_page_locator_algorithms.dart';
part 'reply_page_locator_hint_strategy.dart';
part 'reply_page_locator_legacy_strategy.dart';
part 'reply_page_locator_probe_session.dart';

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
    required http.Client client,
    required ThreadDetailService threadDetailService,
    ReplyPageLocatorCacheService? cacheService,
    ReplyPageLocatorLogWriter? logWriter,
    bool Function()? shouldWriteJumpLogs,
  }) : _client = client,
       _threadDetailService = threadDetailService,
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

      final hintDrivenResult = await _ReplyPageLocatorHintStrategy(
        service: this,
        normalizedTid: normalizedTid,
        normalizedPid: normalizedPid,
        targetPidNumber: targetPidNumber,
        normalizedBudget: normalizedBudget,
        coarseProbeStride: normalizedCoarseProbeStride,
        useCache: useCache,
        officialHintRaw: officialHintRaw,
        isCanceled: isCanceled,
        trace: trace,
      ).locate();

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
      final legacyResult = await _ReplyPageLocatorLegacyStrategy(
        service: this,
        normalizedTid: normalizedTid,
        normalizedPid: normalizedPid,
        targetPidNumber: targetPidNumber,
        normalizedBudget: normalizedBudget,
        coarseProbeStride: normalizedCoarseProbeStride,
        useCache: useCache,
        officialHintRaw: officialHintRaw,
        isCanceled: isCanceled,
        trace: trace,
      ).locate();
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
    return ReplyPageLocateResult.internal(
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

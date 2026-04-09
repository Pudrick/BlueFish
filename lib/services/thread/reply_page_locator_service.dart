import 'dart:async';
import 'dart:convert';

import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/thread/single_reply_floor.dart';
import 'package:bluefish/models/thread/thread_detail.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/services/thread/thread_detail_service.dart';
import 'package:bluefish/userdata/reply_page_locator_cache_store.dart';
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

  ReplyPageLocatorService({
    http.Client? client,
    ThreadDetailService? threadDetailService,
    ReplyPageLocatorCacheService? cacheService,
  }) : _client = client ?? httpClient,
       _threadDetailService = threadDetailService ?? ThreadDetailService(),
       _cacheService = cacheService ?? ReplyPageLocatorCacheService();

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

    if (_isCanceled(isCanceled)) {
      _canceled += 1;
      return ReplyPageLocateResult.canceled(
        probesUsed: 0,
        probeBudget: normalizedBudget,
      );
    }

    if (useCache) {
      await _cacheService.ensureInitialized();
      await _cacheService.configureMaxEntries(normalizedCacheMaxEntries);
      final cached = await _cacheService.findExact(
        tid: normalizedTid,
        targetPid: normalizedPid,
      );
      if (cached != null) {
        return _resultFromCacheEntry(cached, normalizedBudget);
      }
    }

    final targetPidNumber = _parsePidNumber(normalizedPid);
    final officialHintRaw = await _fetchOfficialHintPage(
      tid: normalizedTid,
      pid: normalizedPid,
    );

    final Map<int, ThreadDetail> visitedPages = <int, ThreadDetail>{};
    int probesUsed = 0;
    bool budgetExhausted = false;

    Future<_ProbeOutcome> probePage(int page, {bool evaluate = true}) async {
      if (_isCanceled(isCanceled)) {
        return _ProbeOutcome(
          terminal: ReplyPageLocateResult.canceled(
            probesUsed: probesUsed,
            probeBudget: normalizedBudget,
          ),
        );
      }

      final existing = visitedPages[page];
      if (existing != null) {
        return _ProbeOutcome(detail: existing);
      }

      if (probesUsed >= normalizedBudget) {
        budgetExhausted = true;
        return const _ProbeOutcome();
      }

      probesUsed += 1;
      final detailResult = await _threadDetailService.getThreadDetail(
        normalizedTid,
        page,
      );

      if (_isCanceled(isCanceled)) {
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
        return const _ProbeOutcome();
      }

      visitedPages[page] = detail!;
      final terminal = evaluate
          ? _evaluatePage(
              detail: detail!,
              targetPid: normalizedPid,
              targetPidNumber: targetPidNumber,
              probesUsed: probesUsed,
              probeBudget: normalizedBudget,
            )
          : null;

      return _ProbeOutcome(detail: detail, terminal: terminal);
    }

    final firstPageOutcome = await probePage(1);
    final firstPageTerminal = firstPageOutcome.terminal;
    if (firstPageTerminal != null) {
      return _finalize(
        tid: normalizedTid,
        pid: normalizedPid,
        result: firstPageTerminal,
        useCache: useCache,
      );
    }

    final firstPageDetail = firstPageOutcome.detail;
    if (firstPageDetail == null) {
      if (budgetExhausted) {
        _budgetExhausted += 1;
      }
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

    ThreadDetail? officialHintDetail;
    if (officialHint != null) {
      final officialOutcome = await probePage(officialHint);
      final officialTerminal = officialOutcome.terminal;
      if (officialTerminal != null) {
        if (officialTerminal.resolutionType == ReplyPageResolutionType.exact) {
          _officialHintHits += 1;
        }
        return _finalize(
          tid: normalizedTid,
          pid: normalizedPid,
          result: officialTerminal,
          useCache: useCache,
        );
      }
      officialHintDetail = officialOutcome.detail;
    }

    ThreadDetail? lastPageDetail = visitedPages[totalPages];
    if (lastPageDetail == null && totalPages > 1) {
      final lastPageOutcome = await probePage(totalPages);
      final lastPageTerminal = lastPageOutcome.terminal;
      if (lastPageTerminal != null) {
        return _finalize(
          tid: normalizedTid,
          pid: normalizedPid,
          result: lastPageTerminal,
          useCache: useCache,
        );
      }
      lastPageDetail = lastPageOutcome.detail;
    }

    ThreadDetail? interpolationDetail;
    final interpolationPage = _computeInterpolatedPage(
      totalPages: totalPages,
      targetPidNumber: targetPidNumber,
      firstPageDetail: firstPageDetail,
      lastPageDetail: lastPageDetail,
    );

    if (interpolationPage != null) {
      final interpolationOutcome = await probePage(interpolationPage);
      final interpolationTerminal = interpolationOutcome.terminal;
      if (interpolationTerminal != null) {
        if (interpolationTerminal.resolutionType ==
            ReplyPageResolutionType.exact) {
          _interpolationHits += 1;
        }
        return _finalize(
          tid: normalizedTid,
          pid: normalizedPid,
          result: interpolationTerminal,
          useCache: useCache,
        );
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

      if (hintFirstPid != null && hintFirstPid == targetPidNumber) {
        return _finalize(
          tid: normalizedTid,
          pid: normalizedPid,
          result: ReplyPageLocateResult.exact(
            page: officialHintDetail.currentPage,
            probesUsed: probesUsed,
            probeBudget: normalizedBudget,
          ),
          useCache: useCache,
        );
      }

      if (nearestCacheEntry != null &&
          cachePid != null &&
          cachePid == targetPidNumber) {
        return _resultFromCacheEntry(nearestCacheEntry, normalizedBudget);
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
    );

    if (firstPidDirectionalTerminal != null) {
      return _finalize(
        tid: normalizedTid,
        pid: normalizedPid,
        result: firstPidDirectionalTerminal,
        useCache: useCache,
      );
    }

    final directionalCandidates = _buildDirectionalCandidates(
      seedPage: seedPage,
      seedFirstPid: seedFirstPid,
      targetPidNumber: targetPidNumber,
      totalPages: totalPages,
      visitedPages: visitedPages.keys.toSet(),
    );

    for (final page in directionalCandidates) {
      final outcome = await probePage(page);
      final terminal = outcome.terminal;
      if (terminal != null) {
        return _finalize(
          tid: normalizedTid,
          pid: normalizedPid,
          result: terminal,
          useCache: useCache,
        );
      }
      if (_isCanceled(isCanceled)) {
        return _finalize(
          tid: normalizedTid,
          pid: normalizedPid,
          result: ReplyPageLocateResult.canceled(
            probesUsed: probesUsed,
            probeBudget: normalizedBudget,
          ),
          useCache: useCache,
        );
      }
      if (probesUsed >= normalizedBudget) {
        budgetExhausted = true;
        break;
      }
    }

    if (budgetExhausted) {
      _budgetExhausted += 1;
    }
    return _finalize(
      tid: normalizedTid,
      pid: normalizedPid,
      result: ReplyPageLocateResult.fallbackPage1(
        probesUsed: probesUsed,
        probeBudget: normalizedBudget,
      ),
      useCache: useCache,
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

  ReplyPageLocateResult? _evaluatePage({
    required ThreadDetail detail,
    required String targetPid,
    required int? targetPidNumber,
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

    if (targetPidNumber != null &&
        _containsBracket(detail.replies, targetPidNumber)) {
      return ReplyPageLocateResult.bracket(
        page: detail.currentPage,
        probesUsed: probesUsed,
        probeBudget: probeBudget,
      );
    }

    final firstReplyPidNumber = _parsePidNumber(_firstReplyPid(detail));
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
    for (final reply in detail.lightedReplies) {
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
    required ThreadDetail firstPageDetail,
    ThreadDetail? lastPageDetail,
  }) {
    if (targetPidNumber == null || totalPages <= 1) {
      return null;
    }

    final firstPidNumber = _parsePidNumber(_firstReplyPid(firstPageDetail));
    final lastPidNumber = _parsePidNumber(
      _firstReplyPid(lastPageDetail ?? firstPageDetail),
    );

    if (firstPidNumber == null || lastPidNumber == null) {
      return null;
    }

    final denominator = lastPidNumber - firstPidNumber;
    if (denominator <= 0) {
      return null;
    }

    final ratio = (targetPidNumber - firstPidNumber) / denominator;
    if (!ratio.isFinite) {
      return null;
    }

    final interpolated = 1 + (ratio * (totalPages - 1)).floor();
    return interpolated.clamp(1, totalPages).toInt();
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
  }) async {
    if (targetPidNumber == null) {
      return null;
    }

    ThreadDetail? seedDetail = visitedPages[seedPage];
    if (seedDetail == null) {
      final seedOutcome = await probePage(seedPage, evaluate: false);
      if (seedOutcome.terminal != null) {
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
      return null;
    }

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
      final outcome = await probePage(page, evaluate: false);
      if (outcome.terminal != null) {
        return outcome.terminal;
      }

      final detail = outcome.detail;
      if (detail == null) {
        continue;
      }

      edgePage = page;
      final currentFirstPid = _parsePidNumber(_firstReplyPid(detail));
      if (currentFirstPid == null) {
        continue;
      }

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

  String? _firstReplyPid(ThreadDetail detail) {
    if (detail.replies.isNotEmpty) {
      return detail.replies.first.pid;
    }
    return null;
  }

  int? _parsePidNumber(String? rawPid) {
    if (rawPid == null || rawPid.isEmpty) {
      return null;
    }
    return int.tryParse(rawPid);
  }

  bool _isCanceled(bool Function()? isCanceled) {
    return isCanceled?.call() == true;
  }
}

class _ProbeOutcome {
  final ThreadDetail? detail;
  final ReplyPageLocateResult? terminal;

  const _ProbeOutcome({this.detail, this.terminal});
}

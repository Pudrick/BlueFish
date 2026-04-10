part of 'reply_page_locator_service.dart';

class _ReplyPageLocatorLegacyStrategy {
  final ReplyPageLocatorService service;
  final String normalizedTid;
  final String normalizedPid;
  final int? targetPidNumber;
  final int normalizedBudget;
  final int coarseProbeStride;
  final bool useCache;
  final int? officialHintRaw;
  final bool Function()? isCanceled;
  final _LocateTrace trace;

  const _ReplyPageLocatorLegacyStrategy({
    required this.service,
    required this.normalizedTid,
    required this.normalizedPid,
    required this.targetPidNumber,
    required this.normalizedBudget,
    required this.coarseProbeStride,
    required this.useCache,
    required this.officialHintRaw,
    required this.isCanceled,
    required this.trace,
  });

  Future<ReplyPageLocateResult> locate() async {
    trace.addStep('legacy_start', <String, Object?>{
      'targetPidNumber': targetPidNumber,
      'officialHintRaw': officialHintRaw,
      'normalizedBudget': normalizedBudget,
      'coarseProbeStride': coarseProbeStride,
      'useCache': useCache,
    });
    final session = _ReplyPageLocatorProbeSession(
      service: service,
      normalizedTid: normalizedTid,
      normalizedBudget: normalizedBudget,
      isCanceled: isCanceled,
      trace: trace,
    );

    Future<_ProbeOutcome> probePage(
      int page, {
      bool evaluate = true,
      bool countAgainstBudget = true,
    }) async {
      final outcome = await session.fetchPage(
        page,
        tracePrefix: 'legacy_probe',
        countAgainstBudget: countAgainstBudget,
      );
      if (outcome.terminal != null || !evaluate) {
        return outcome;
      }

      final detail = outcome.detail;
      if (detail == null) {
        return outcome;
      }

      final terminal = _evaluatePage(
        detail: detail,
        targetPid: normalizedPid,
        targetPidNumber: targetPidNumber,
        probesUsed: session.probesUsed,
        probeBudget: normalizedBudget,
        trace: trace,
        stage: outcome.reused ? 'legacy_probe_reuse' : 'legacy_probe_evaluate',
      );
      if (terminal != null) {
        _traceResult(
          trace,
          outcome.reused
              ? 'legacy_probe_reuse_terminal'
              : 'legacy_probe_terminal',
          terminal,
        );
      }

      return _ProbeOutcome(
        detail: detail,
        terminal: terminal,
        reused: outcome.reused,
      );
    }

    final firstPageOutcome = await probePage(1);
    final firstPageTerminal = firstPageOutcome.terminal;
    if (firstPageTerminal != null) {
      _traceResult(trace, 'legacy_first_page_terminal', firstPageTerminal);
      return firstPageTerminal;
    }

    final firstPageDetail = firstPageOutcome.detail;
    if (firstPageDetail == null) {
      if (session.budgetExhausted) {
        session.recordBudgetExhausted();
      }
      trace.addStep('legacy_first_page_missing_fallback', <String, Object?>{
        'budgetExhausted': session.budgetExhausted,
        'probesUsed': session.probesUsed,
      });
      return session.fallbackPage1Result();
    }

    final totalPages = firstPageDetail.totalPagesNum;
    final officialHint = service._normalizeOfficialHint(
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
          ReplyPageLocatorService._officialHintHits += 1;
        }
        _traceResult(trace, 'legacy_official_terminal', officialTerminal);
        return officialTerminal;
      }
      officialHintDetail = officialOutcome.detail;
    }

    ThreadDetail? lastPageDetail = session.visitedPages[totalPages];
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
          ReplyPageLocatorService._interpolationHits += 1;
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

    var seedPage =
        (interpolationDetail ?? officialHintDetail ?? firstPageDetail)
            .currentPage;
    int? seedFirstPid = _parsePidNumber(
      _firstReplyPid(
        interpolationDetail ?? officialHintDetail ?? firstPageDetail,
      ),
    );

    if (useCache && officialHintDetail != null && targetPidNumber != null) {
      final targetPidNumber = this.targetPidNumber!;
      final nearestCacheEntry = await service._cacheService.findNearestInThread(
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
          probesUsed: session.probesUsed,
          probeBudget: normalizedBudget,
        );
        _traceResult(trace, 'legacy_seed_exact_from_hint_first_pid', result);
        return result;
      }

      if (nearestCacheEntry != null &&
          cachePid != null &&
          cachePid == targetPidNumber) {
        final result = service._resultFromCacheEntry(
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
        final selectedSeedDetail = session.visitedPages[seedPage];
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
      currentProbesUsed: () => session.probesUsed,
      visitedPages: session.visitedPages,
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
      visitedPages: session.visitedPages.keys.toSet(),
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
      if (service._isCanceled(isCanceled)) {
        final canceledResult = session.canceledResult();
        _traceResult(trace, 'legacy_directional_canceled', canceledResult);
        return canceledResult;
      }
      if (session.probesUsed >= normalizedBudget) {
        session.budgetExhausted = true;
        trace.addStep('legacy_directional_budget_reached', <String, Object?>{
          'probesUsed': session.probesUsed,
          'probeBudget': normalizedBudget,
        });
        break;
      }
    }

    session.recordBudgetExhausted(
      'legacy_budget_exhausted_counter_incremented',
    );
    trace.addStep('legacy_fallback_page1', <String, Object?>{
      'probesUsed': session.probesUsed,
      'probeBudget': normalizedBudget,
    });
    return session.fallbackPage1Result();
  }
}

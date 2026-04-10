part of 'reply_page_locator_service.dart';

class _ReplyPageLocatorHintStrategy {
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

  const _ReplyPageLocatorHintStrategy({
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

  Future<ReplyPageLocateResult?> locate() async {
    final targetPidNumber = this.targetPidNumber;

    trace.addStep('hint_range_start', <String, Object?>{
      'targetPidNumber': targetPidNumber,
      'officialHintRaw': officialHintRaw,
      'normalizedBudget': normalizedBudget,
      'coarseProbeStride': coarseProbeStride,
      'useCache': useCache,
    });
    if (targetPidNumber == null ||
        officialHintRaw == null ||
        officialHintRaw! < 1) {
      trace.addStep('hint_range_skipped', <String, Object?>{
        'reason': 'missing_target_or_invalid_hint',
      });
      return null;
    }

    final session = _ReplyPageLocatorProbeSession(
      service: service,
      normalizedTid: normalizedTid,
      normalizedBudget: normalizedBudget,
      isCanceled: isCanceled,
      trace: trace,
    );

    ReplyPageLocateResult fallbackPage1() {
      trace.addStep('hint_fallback_page1', <String, Object?>{
        'probesUsed': session.probesUsed,
        'probeBudget': normalizedBudget,
      });
      session.recordBudgetExhausted(
        'hint_budget_exhausted_counter_incremented',
      );
      return session.fallbackPage1Result();
    }

    final officialOutcome = await session.fetchPage(
      officialHintRaw!,
      tracePrefix: 'hint_probe',
    );
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
    final officialHint = service._normalizeOfficialHint(
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
      probesUsed: session.probesUsed,
      probeBudget: normalizedBudget,
      trace: trace,
      stage: 'hint_official',
    );
    if (officialHintResult != null) {
      if (officialHintResult.resolutionType == ReplyPageResolutionType.exact) {
        ReplyPageLocatorService._officialHintHits += 1;
      }
      _traceResult(
        trace,
        'hint_official_candidate_terminal',
        officialHintResult,
      );
      return officialHintResult;
    }

    final firstPageOutcome = await session.fetchPage(
      1,
      tracePrefix: 'hint_probe',
    );
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
      probesUsed: session.probesUsed,
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
      final lastPageOutcome = await session.fetchPage(
        totalPages,
        tracePrefix: 'hint_probe',
      );
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
          probesUsed: session.probesUsed,
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
          probesUsed: session.probesUsed,
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
        probePage: (int page) => session.fetchPage(
          page,
          tracePrefix: 'hint_probe',
          countAgainstBudget: false,
        ),
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
        final interpolationOutcome = await session.fetchPage(
          interpolatedPage,
          tracePrefix: 'hint_probe',
        );
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
            probesUsed: session.probesUsed,
            probeBudget: normalizedBudget,
            trace: trace,
            stage: 'hint_interpolation_candidate',
          );
          if (interpolationResult != null) {
            if (interpolationResult.resolutionType ==
                ReplyPageResolutionType.exact) {
              ReplyPageLocatorService._interpolationHits += 1;
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

    var seedPage = currentHintDetail.currentPage;
    final currentHintFirstPid = _parsePidNumber(
      _firstReplyPid(currentHintDetail),
    );
    trace.addStep('hint_seed_base', <String, Object?>{
      'seedPage': seedPage,
      'currentHintFirstPid': currentHintFirstPid,
      'targetPidNumber': targetPidNumber,
    });

    if (useCache) {
      final nearestCacheEntry = await service._cacheService.findNearestInThread(
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
          probesUsed: session.probesUsed,
          probeBudget: normalizedBudget,
        );
        _traceResult(trace, 'hint_seed_exact_from_first_pid', result);
        return result;
      }

      if (nearestCacheEntry != null &&
          cachePid != null &&
          cachePid == targetPidNumber) {
        final result = service._resultFromCacheEntry(
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
      currentProbesUsed: () => session.probesUsed,
      probePage: (int page) =>
          session.fetchPage(page, tracePrefix: 'hint_probe'),
      trace: trace,
    );
    if (directionalResult != null) {
      _traceResult(trace, 'hint_directional_terminal', directionalResult);
      return directionalResult;
    }

    return fallbackPage1();
  }
}

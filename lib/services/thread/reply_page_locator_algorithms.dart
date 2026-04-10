part of 'reply_page_locator_service.dart';

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
    trace?.addStep('evaluate_page_exact_without_numeric_pid', <String, Object?>{
      'stage': stage,
      'targetPid': targetPid,
      ..._detailSummary(detail),
    });
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
  required Future<_ProbeOutcome> Function(int page, {bool evaluate}) probePage,
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
  if (totalPages <= normalizedStride) {
    return const <int>[];
  }

  final pages = <int>[];
  final seenPages = <int>{};

  void addPage(int page) {
    if (page < 1 || page > totalPages) {
      return;
    }
    if (seenPages.add(page)) {
      pages.add(page);
    }
  }

  addPage(totalPages);

  final alignedTailPage = totalPages - (totalPages % normalizedStride);
  for (var page = alignedTailPage; page >= 1; page -= normalizedStride) {
    addPage(page);
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
  final normalizedStride = coarseProbeStride < 1
      ? AppSettings.defaultReplyLocateCoarseProbeStride
      : coarseProbeStride;

  if (targetPidNumber == null || totalPages <= normalizedStride) {
    trace?.addStep('coarse_probe_skipped', <String, Object?>{
      'stage': stage,
      'reason': targetPidNumber == null
          ? 'target_pid_not_numeric'
          : 'total_pages_within_stride',
      'totalPages': totalPages,
      'coarseProbeStride': normalizedStride,
    });
    return const _CoarseIntervalOutcome();
  }

  final coarsePages = _buildCoarseProbePages(totalPages, normalizedStride);
  trace?.addStep('coarse_probe_start', <String, Object?>{
    'stage': stage,
    'targetPidNumber': targetPidNumber,
    'totalPages': totalPages,
    'coarseProbeStride': normalizedStride,
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

    if (current.firstPidNumber == previous.firstPidNumber) {
      continue;
    }

    if (targetPidNumber == current.firstPidNumber) {
      lowerAnchor = current;
      upperAnchor = current;
      trace?.addStep('coarse_probe_early_exit_exact_anchor', <String, Object?>{
        'stage': stage,
        'matchedPage': current.page,
        'matchedFirstPid': current.firstPidNumber,
        'anchorsProbed': anchors.length,
      });
      break;
    }

    final pair = _matchCoarseProbePair(
      left: previous,
      right: current,
      targetPidNumber: targetPidNumber,
    );
    if (pair != null) {
      lowerAnchor = pair.lowerAnchor;
      upperAnchor = pair.upperAnchor;
      trace?.addStep('coarse_probe_early_exit_interval', <String, Object?>{
        'stage': stage,
        'targetPidNumber': targetPidNumber,
        'lowerPage': pair.lowerAnchor.page,
        'upperPage': pair.upperAnchor.page,
        'lowerFirstPid': pair.lowerAnchor.firstPidNumber,
        'upperFirstPid': pair.upperAnchor.firstPidNumber,
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

  final orderedAnchors = anchors.toList()
    ..sort((left, right) {
      final pidCompare = left.firstPidNumber.compareTo(right.firstPidNumber);
      if (pidCompare != 0) {
        return pidCompare;
      }
      return left.page.compareTo(right.page);
    });

  if (lowerAnchor == null || upperAnchor == null) {
    if (targetPidNumber <= orderedAnchors.first.firstPidNumber) {
      lowerAnchor = orderedAnchors.first;
      upperAnchor = orderedAnchors[1];
    } else {
      for (var index = 1; index < orderedAnchors.length; index += 1) {
        final previous = orderedAnchors[index - 1];
        final current = orderedAnchors[index];

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

        final pair = _matchCoarseProbePair(
          left: previous,
          right: current,
          targetPidNumber: targetPidNumber,
        );
        if (pair != null) {
          lowerAnchor = pair.lowerAnchor;
          upperAnchor = pair.upperAnchor;
          break;
        }
      }
    }
  }

  if (lowerAnchor == null || upperAnchor == null) {
    if (targetPidNumber > orderedAnchors.last.firstPidNumber) {
      lowerAnchor = orderedAnchors[orderedAnchors.length - 2];
      upperAnchor = orderedAnchors.last;
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

_CoarseProbePair? _matchCoarseProbePair({
  required _CoarseProbeAnchor left,
  required _CoarseProbeAnchor right,
  required int targetPidNumber,
}) {
  if (left.firstPidNumber == right.firstPidNumber) {
    return null;
  }

  final lowerAnchor = left.firstPidNumber < right.firstPidNumber ? left : right;
  final upperAnchor = identical(lowerAnchor, left) ? right : left;
  if (lowerAnchor.firstPidNumber < targetPidNumber &&
      targetPidNumber < upperAnchor.firstPidNumber) {
    return _CoarseProbePair(lowerAnchor: lowerAnchor, upperAnchor: upperAnchor);
  }

  return null;
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

class _CoarseProbePair {
  final _CoarseProbeAnchor lowerAnchor;
  final _CoarseProbeAnchor upperAnchor;

  const _CoarseProbePair({
    required this.lowerAnchor,
    required this.upperAnchor,
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

enum _PageTargetRelation { before, after, within, unknown }

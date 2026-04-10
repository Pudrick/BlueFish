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

  const ReplyPageLocateResult.internal({
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
    return ReplyPageLocateResult.internal(
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
    return ReplyPageLocateResult.internal(
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
    return ReplyPageLocateResult.internal(
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
    return ReplyPageLocateResult.internal(
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
    return ReplyPageLocateResult.internal(
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
    return ReplyPageLocateResult.internal(
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

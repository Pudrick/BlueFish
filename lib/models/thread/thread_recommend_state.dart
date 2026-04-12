enum ThreadRecommendState {
  unknown,
  checking,
  recommended,
  notRecommended;

  String get storageValue => switch (this) {
    ThreadRecommendState.unknown => 'unknown',
    ThreadRecommendState.checking => 'checking',
    ThreadRecommendState.recommended => 'recommended',
    ThreadRecommendState.notRecommended => 'not_recommended',
  };

  bool get isKnown =>
      this == ThreadRecommendState.recommended ||
      this == ThreadRecommendState.notRecommended;

  bool get isRecommended => this == ThreadRecommendState.recommended;

  bool get isChecking => this == ThreadRecommendState.checking;

  static ThreadRecommendState? fromStorage(String? rawValue) {
    return switch (rawValue?.trim()) {
      'unknown' => ThreadRecommendState.unknown,
      'checking' => ThreadRecommendState.checking,
      'recommended' => ThreadRecommendState.recommended,
      'not_recommended' => ThreadRecommendState.notRecommended,
      _ => null,
    };
  }
}

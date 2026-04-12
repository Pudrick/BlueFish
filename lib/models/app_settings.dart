import 'package:flutter/material.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  String get storageValue => switch (this) {
    AppThemePreference.system => 'system',
    AppThemePreference.light => 'light',
    AppThemePreference.dark => 'dark',
  };

  String get label => switch (this) {
    AppThemePreference.system => '跟随系统',
    AppThemePreference.light => '浅色',
    AppThemePreference.dark => '深色',
  };

  static AppThemePreference fromStorage(String? rawValue) {
    return switch (rawValue?.trim()) {
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }
}

@immutable
class AppSettings {
  static const double minFontScale = 0.85;
  static const double maxFontScale = 1.35;
  static const double minImageShrinkTriggerWidthFactor = 0.6;
  static const double maxImageShrinkTriggerWidthFactor = 1.8;
  static const double defaultImageShrinkTriggerWidthFactor = 1.4;
  static const double minImageShrinkTargetWidthFactor = 0.35;
  static const double maxImageShrinkTargetWidthFactor = 0.7;
  static const double defaultImageShrinkTargetWidthFactor = 0.5;
  static const int minReplyLocateTotalProbeBudget = 3;
  static const int maxReplyLocateTotalProbeBudget = 40;
  static const int defaultReplyLocateTotalProbeBudget = 15;
  static const int minReplyLocateCacheMaxEntries = 64;
  static const int maxReplyLocateCacheMaxEntries = 4096;
  static const int defaultReplyLocateCacheMaxEntries = 1024;
  static const int minReplyLocateCoarseProbeStride = 20;
  static const int maxReplyLocateCoarseProbeStride = 300;
  static const int defaultReplyLocateCoarseProbeStride = 100;
  static const bool defaultGenerateJumpLogs = true;
  static const bool defaultCollapseLightedRepliesEnabled = false;
  static const bool defaultAutoProbeThreadRecommendStatus = false;
  static const int defaultSeedColorValue = 0xFF0B6E4F;
  static const double _imageWidthFactorStep = 0.05;
  static const Object _unset = Object();
  static const AppSettings defaults = AppSettings._(
    themePreference: AppThemePreference.system,
    seedColorValue: defaultSeedColorValue,
    contentFontScale: 1,
    titleFontScale: 1,
    metaFontScale: 1,
    imageShrinkTriggerWidthFactor: defaultImageShrinkTriggerWidthFactor,
    imageShrinkTargetWidthFactor: defaultImageShrinkTargetWidthFactor,
    replyLocateTotalProbeBudget: defaultReplyLocateTotalProbeBudget,
    replyLocateCacheMaxEntries: defaultReplyLocateCacheMaxEntries,
    replyLocateCoarseProbeStride: defaultReplyLocateCoarseProbeStride,
    generateJumpLogs: defaultGenerateJumpLogs,
    defaultCollapseLightedReplies: defaultCollapseLightedRepliesEnabled,
    autoProbeThreadRecommendStatus: defaultAutoProbeThreadRecommendStatus,
    imageSaveDirectoryPath: null,
    videoSaveDirectoryPath: null,
    apiVersionOverride: null,
  );

  final AppThemePreference themePreference;
  final int seedColorValue;
  final double contentFontScale;
  final double titleFontScale;
  final double metaFontScale;
  final double imageShrinkTriggerWidthFactor;
  final double imageShrinkTargetWidthFactor;
  final int replyLocateTotalProbeBudget;
  final int replyLocateCacheMaxEntries;
  final int replyLocateCoarseProbeStride;
  final bool generateJumpLogs;
  final bool defaultCollapseLightedReplies;
  final bool autoProbeThreadRecommendStatus;
  final String? imageSaveDirectoryPath;
  final String? videoSaveDirectoryPath;
  final String? apiVersionOverride;

  const AppSettings._({
    required this.themePreference,
    required this.seedColorValue,
    required this.contentFontScale,
    required this.titleFontScale,
    required this.metaFontScale,
    required this.imageShrinkTriggerWidthFactor,
    required this.imageShrinkTargetWidthFactor,
    required this.replyLocateTotalProbeBudget,
    required this.replyLocateCacheMaxEntries,
    required this.replyLocateCoarseProbeStride,
    required this.generateJumpLogs,
    required this.defaultCollapseLightedReplies,
    required this.autoProbeThreadRecommendStatus,
    required this.imageSaveDirectoryPath,
    required this.videoSaveDirectoryPath,
    required this.apiVersionOverride,
  });

  factory AppSettings({
    required AppThemePreference themePreference,
    required int seedColorValue,
    required double contentFontScale,
    required double titleFontScale,
    required double metaFontScale,
    required double imageShrinkTriggerWidthFactor,
    required double imageShrinkTargetWidthFactor,
    required int replyLocateTotalProbeBudget,
    required int replyLocateCacheMaxEntries,
    required int replyLocateCoarseProbeStride,
    bool generateJumpLogs = defaultGenerateJumpLogs,
    bool defaultCollapseLightedReplies =
        AppSettings.defaultCollapseLightedRepliesEnabled,
    bool autoProbeThreadRecommendStatus =
        AppSettings.defaultAutoProbeThreadRecommendStatus,
    String? imageSaveDirectoryPath,
    String? videoSaveDirectoryPath,
    String? apiVersionOverride,
  }) {
    final normalizedTrigger = normalizeImageShrinkTriggerWidthFactor(
      imageShrinkTriggerWidthFactor,
    );
    final normalizedTarget = normalizeImageShrinkTargetWidthFactor(
      imageShrinkTargetWidthFactor,
    );

    return AppSettings._(
      themePreference: themePreference,
      seedColorValue: _normalizeSeedColorValue(seedColorValue),
      contentFontScale: _normalizeFontScale(contentFontScale),
      titleFontScale: _normalizeFontScale(titleFontScale),
      metaFontScale: _normalizeFontScale(metaFontScale),
      imageShrinkTriggerWidthFactor: normalizedTrigger,
      imageShrinkTargetWidthFactor: normalizedTarget > normalizedTrigger
          ? normalizedTrigger
          : normalizedTarget,
      replyLocateTotalProbeBudget: _normalizeReplyLocateTotalProbeBudget(
        replyLocateTotalProbeBudget,
      ),
      replyLocateCacheMaxEntries: _normalizeReplyLocateCacheMaxEntries(
        replyLocateCacheMaxEntries,
      ),
      replyLocateCoarseProbeStride: _normalizeReplyLocateCoarseProbeStride(
        replyLocateCoarseProbeStride,
      ),
      generateJumpLogs: generateJumpLogs,
      defaultCollapseLightedReplies: defaultCollapseLightedReplies,
      autoProbeThreadRecommendStatus: autoProbeThreadRecommendStatus,
      imageSaveDirectoryPath: _normalizeDirectoryPath(imageSaveDirectoryPath),
      videoSaveDirectoryPath: _normalizeDirectoryPath(videoSaveDirectoryPath),
      apiVersionOverride: _normalizeApiVersionOverride(apiVersionOverride),
    );
  }

  ThemeMode get themeMode => themePreference.themeMode;

  Color get seedColor => Color(seedColorValue);

  AppSettings copyWith({
    AppThemePreference? themePreference,
    int? seedColorValue,
    double? contentFontScale,
    double? titleFontScale,
    double? metaFontScale,
    double? imageShrinkTriggerWidthFactor,
    double? imageShrinkTargetWidthFactor,
    int? replyLocateTotalProbeBudget,
    int? replyLocateCacheMaxEntries,
    int? replyLocateCoarseProbeStride,
    bool? generateJumpLogs,
    bool? defaultCollapseLightedReplies,
    bool? autoProbeThreadRecommendStatus,
    Object? imageSaveDirectoryPath = _unset,
    Object? videoSaveDirectoryPath = _unset,
    Object? apiVersionOverride = _unset,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      seedColorValue: seedColorValue ?? this.seedColorValue,
      contentFontScale: contentFontScale ?? this.contentFontScale,
      titleFontScale: titleFontScale ?? this.titleFontScale,
      metaFontScale: metaFontScale ?? this.metaFontScale,
      imageShrinkTriggerWidthFactor:
          imageShrinkTriggerWidthFactor ?? this.imageShrinkTriggerWidthFactor,
      imageShrinkTargetWidthFactor:
          imageShrinkTargetWidthFactor ?? this.imageShrinkTargetWidthFactor,
      replyLocateTotalProbeBudget:
          replyLocateTotalProbeBudget ?? this.replyLocateTotalProbeBudget,
      replyLocateCacheMaxEntries:
          replyLocateCacheMaxEntries ?? this.replyLocateCacheMaxEntries,
      replyLocateCoarseProbeStride:
          replyLocateCoarseProbeStride ?? this.replyLocateCoarseProbeStride,
      generateJumpLogs: generateJumpLogs ?? this.generateJumpLogs,
      defaultCollapseLightedReplies:
          defaultCollapseLightedReplies ?? this.defaultCollapseLightedReplies,
      autoProbeThreadRecommendStatus:
          autoProbeThreadRecommendStatus ?? this.autoProbeThreadRecommendStatus,
      imageSaveDirectoryPath: identical(imageSaveDirectoryPath, _unset)
          ? this.imageSaveDirectoryPath
          : imageSaveDirectoryPath as String?,
      videoSaveDirectoryPath: identical(videoSaveDirectoryPath, _unset)
          ? this.videoSaveDirectoryPath
          : videoSaveDirectoryPath as String?,
      apiVersionOverride: identical(apiVersionOverride, _unset)
          ? this.apiVersionOverride
          : apiVersionOverride as String?,
    );
  }

  static double _normalizeFontScale(double value) {
    final normalizedValue = value.isFinite ? value : 1;
    return normalizedValue.clamp(minFontScale, maxFontScale).toDouble();
  }

  static int _normalizeSeedColorValue(int value) {
    return value | 0xFF000000;
  }

  static double normalizeImageShrinkTriggerWidthFactor(double value) {
    return _normalizeImageWidthFactor(
      value: value,
      min: minImageShrinkTriggerWidthFactor,
      max: maxImageShrinkTriggerWidthFactor,
    );
  }

  static double normalizeImageShrinkTargetWidthFactor(double value) {
    return _normalizeImageWidthFactor(
      value: value,
      min: minImageShrinkTargetWidthFactor,
      max: maxImageShrinkTargetWidthFactor,
    );
  }

  static int _normalizeReplyLocateTotalProbeBudget(int value) {
    return value
        .clamp(minReplyLocateTotalProbeBudget, maxReplyLocateTotalProbeBudget)
        .toInt();
  }

  static int _normalizeReplyLocateCacheMaxEntries(int value) {
    return value
        .clamp(minReplyLocateCacheMaxEntries, maxReplyLocateCacheMaxEntries)
        .toInt();
  }

  static int _normalizeReplyLocateCoarseProbeStride(int value) {
    return value
        .clamp(minReplyLocateCoarseProbeStride, maxReplyLocateCoarseProbeStride)
        .toInt();
  }

  static double _normalizeImageWidthFactor({
    required double value,
    required double min,
    required double max,
  }) {
    final normalizedValue = value.isFinite ? value : min;
    final clampedValue = normalizedValue.clamp(min, max).toDouble();
    final steppedValue =
        (clampedValue / _imageWidthFactorStep).roundToDouble() *
        _imageWidthFactorStep;
    return double.parse(steppedValue.toStringAsFixed(2));
  }

  static String? _normalizeApiVersionOverride(String? value) {
    final normalizedValue = value?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }
    return normalizedValue;
  }

  static String? _normalizeDirectoryPath(String? value) {
    final normalizedValue = value?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }
    return normalizedValue;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppSettings &&
        other.themePreference == themePreference &&
        other.seedColorValue == seedColorValue &&
        other.contentFontScale == contentFontScale &&
        other.titleFontScale == titleFontScale &&
        other.metaFontScale == metaFontScale &&
        other.imageShrinkTriggerWidthFactor == imageShrinkTriggerWidthFactor &&
        other.imageShrinkTargetWidthFactor == imageShrinkTargetWidthFactor &&
        other.replyLocateTotalProbeBudget == replyLocateTotalProbeBudget &&
        other.replyLocateCacheMaxEntries == replyLocateCacheMaxEntries &&
        other.replyLocateCoarseProbeStride == replyLocateCoarseProbeStride &&
        other.generateJumpLogs == generateJumpLogs &&
        other.defaultCollapseLightedReplies == defaultCollapseLightedReplies &&
        other.autoProbeThreadRecommendStatus ==
            autoProbeThreadRecommendStatus &&
        other.imageSaveDirectoryPath == imageSaveDirectoryPath &&
        other.videoSaveDirectoryPath == videoSaveDirectoryPath &&
        other.apiVersionOverride == apiVersionOverride;
  }

  @override
  int get hashCode => Object.hash(
    themePreference,
    seedColorValue,
    contentFontScale,
    titleFontScale,
    metaFontScale,
    imageShrinkTriggerWidthFactor,
    imageShrinkTargetWidthFactor,
    replyLocateTotalProbeBudget,
    replyLocateCacheMaxEntries,
    replyLocateCoarseProbeStride,
    generateJumpLogs,
    defaultCollapseLightedReplies,
    autoProbeThreadRecommendStatus,
    imageSaveDirectoryPath,
    videoSaveDirectoryPath,
    apiVersionOverride,
  );
}

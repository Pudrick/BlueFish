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
  static const double minImageShrinkTriggerMaxEdgeDp = 400;
  static const double maxImageShrinkTriggerMaxEdgeDp = 1200;
  static const double defaultImageShrinkTriggerMaxEdgeDp = 640;
  static const double minImageShrinkTargetMaxEdgeDp = 240;
  static const double maxImageShrinkTargetMaxEdgeDp = 640;
  static const double defaultImageShrinkTargetMaxEdgeDp = 360;
  static const int minReplyLocateTotalProbeBudget = 3;
  static const int maxReplyLocateTotalProbeBudget = 40;
  static const int defaultReplyLocateTotalProbeBudget = 15;
  static const int minReplyLocateCacheMaxEntries = 64;
  static const int maxReplyLocateCacheMaxEntries = 4096;
  static const int defaultReplyLocateCacheMaxEntries = 1024;
  static const int defaultSeedColorValue = 0xFF0B6E4F;
  static const double _imageEdgeStepDp = 10;
  static const Object _unset = Object();
  static const AppSettings defaults = AppSettings._(
    themePreference: AppThemePreference.system,
    seedColorValue: defaultSeedColorValue,
    contentFontScale: 1,
    titleFontScale: 1,
    metaFontScale: 1,
    imageShrinkTriggerMaxEdgeDp: defaultImageShrinkTriggerMaxEdgeDp,
    imageShrinkTargetMaxEdgeDp: defaultImageShrinkTargetMaxEdgeDp,
    replyLocateTotalProbeBudget: defaultReplyLocateTotalProbeBudget,
    replyLocateCacheMaxEntries: defaultReplyLocateCacheMaxEntries,
    imageSaveDirectoryPath: null,
    videoSaveDirectoryPath: null,
    apiVersionOverride: null,
  );

  final AppThemePreference themePreference;
  final int seedColorValue;
  final double contentFontScale;
  final double titleFontScale;
  final double metaFontScale;
  final double imageShrinkTriggerMaxEdgeDp;
  final double imageShrinkTargetMaxEdgeDp;
  final int replyLocateTotalProbeBudget;
  final int replyLocateCacheMaxEntries;
  final String? imageSaveDirectoryPath;
  final String? videoSaveDirectoryPath;
  final String? apiVersionOverride;

  const AppSettings._({
    required this.themePreference,
    required this.seedColorValue,
    required this.contentFontScale,
    required this.titleFontScale,
    required this.metaFontScale,
    required this.imageShrinkTriggerMaxEdgeDp,
    required this.imageShrinkTargetMaxEdgeDp,
    required this.replyLocateTotalProbeBudget,
    required this.replyLocateCacheMaxEntries,
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
    required double imageShrinkTriggerMaxEdgeDp,
    required double imageShrinkTargetMaxEdgeDp,
    required int replyLocateTotalProbeBudget,
    required int replyLocateCacheMaxEntries,
    String? imageSaveDirectoryPath,
    String? videoSaveDirectoryPath,
    String? apiVersionOverride,
  }) {
    final normalizedTrigger = _normalizeImageEdgeDp(
      value: imageShrinkTriggerMaxEdgeDp,
      min: minImageShrinkTriggerMaxEdgeDp,
      max: maxImageShrinkTriggerMaxEdgeDp,
    );
    final normalizedTarget = _normalizeImageEdgeDp(
      value: imageShrinkTargetMaxEdgeDp,
      min: minImageShrinkTargetMaxEdgeDp,
      max: maxImageShrinkTargetMaxEdgeDp,
    );

    return AppSettings._(
      themePreference: themePreference,
      seedColorValue: _normalizeSeedColorValue(seedColorValue),
      contentFontScale: _normalizeFontScale(contentFontScale),
      titleFontScale: _normalizeFontScale(titleFontScale),
      metaFontScale: _normalizeFontScale(metaFontScale),
      imageShrinkTriggerMaxEdgeDp: normalizedTrigger,
      imageShrinkTargetMaxEdgeDp: normalizedTarget > normalizedTrigger
          ? normalizedTrigger
          : normalizedTarget,
      replyLocateTotalProbeBudget: _normalizeReplyLocateTotalProbeBudget(
        replyLocateTotalProbeBudget,
      ),
      replyLocateCacheMaxEntries: _normalizeReplyLocateCacheMaxEntries(
        replyLocateCacheMaxEntries,
      ),
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
    double? imageShrinkTriggerMaxEdgeDp,
    double? imageShrinkTargetMaxEdgeDp,
    int? replyLocateTotalProbeBudget,
    int? replyLocateCacheMaxEntries,
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
      imageShrinkTriggerMaxEdgeDp:
          imageShrinkTriggerMaxEdgeDp ?? this.imageShrinkTriggerMaxEdgeDp,
      imageShrinkTargetMaxEdgeDp:
          imageShrinkTargetMaxEdgeDp ?? this.imageShrinkTargetMaxEdgeDp,
      replyLocateTotalProbeBudget:
          replyLocateTotalProbeBudget ?? this.replyLocateTotalProbeBudget,
      replyLocateCacheMaxEntries:
          replyLocateCacheMaxEntries ?? this.replyLocateCacheMaxEntries,
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

  static double _normalizeImageEdgeDp({
    required double value,
    required double min,
    required double max,
  }) {
    final normalizedValue = value.isFinite ? value : min;
    final clampedValue = normalizedValue.clamp(min, max).toDouble();
    return (clampedValue / _imageEdgeStepDp).roundToDouble() * _imageEdgeStepDp;
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
        other.imageShrinkTriggerMaxEdgeDp == imageShrinkTriggerMaxEdgeDp &&
        other.imageShrinkTargetMaxEdgeDp == imageShrinkTargetMaxEdgeDp &&
        other.replyLocateTotalProbeBudget == replyLocateTotalProbeBudget &&
        other.replyLocateCacheMaxEntries == replyLocateCacheMaxEntries &&
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
    imageShrinkTriggerMaxEdgeDp,
    imageShrinkTargetMaxEdgeDp,
    replyLocateTotalProbeBudget,
    replyLocateCacheMaxEntries,
    imageSaveDirectoryPath,
    videoSaveDirectoryPath,
    apiVersionOverride,
  );
}

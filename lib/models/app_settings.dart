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
  static const int defaultSeedColorValue = 0xFF0B6E4F;
  static const AppSettings defaults = AppSettings._(
    themePreference: AppThemePreference.system,
    seedColorValue: defaultSeedColorValue,
    contentFontScale: 1,
    titleFontScale: 1,
    metaFontScale: 1,
  );

  final AppThemePreference themePreference;
  final int seedColorValue;
  final double contentFontScale;
  final double titleFontScale;
  final double metaFontScale;

  const AppSettings._({
    required this.themePreference,
    required this.seedColorValue,
    required this.contentFontScale,
    required this.titleFontScale,
    required this.metaFontScale,
  });

  factory AppSettings({
    required AppThemePreference themePreference,
    required int seedColorValue,
    required double contentFontScale,
    required double titleFontScale,
    required double metaFontScale,
  }) {
    return AppSettings._(
      themePreference: themePreference,
      seedColorValue: _normalizeSeedColorValue(seedColorValue),
      contentFontScale: _normalizeFontScale(contentFontScale),
      titleFontScale: _normalizeFontScale(titleFontScale),
      metaFontScale: _normalizeFontScale(metaFontScale),
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
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      seedColorValue: seedColorValue ?? this.seedColorValue,
      contentFontScale: contentFontScale ?? this.contentFontScale,
      titleFontScale: titleFontScale ?? this.titleFontScale,
      metaFontScale: metaFontScale ?? this.metaFontScale,
    );
  }

  static double _normalizeFontScale(double value) {
    final normalizedValue = value.isFinite ? value : 1;
    return normalizedValue.clamp(minFontScale, maxFontScale).toDouble();
  }

  static int _normalizeSeedColorValue(int value) {
    return value | 0xFF000000;
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
        other.metaFontScale == metaFontScale;
  }

  @override
  int get hashCode => Object.hash(
    themePreference,
    seedColorValue,
    contentFontScale,
    titleFontScale,
    metaFontScale,
  );
}

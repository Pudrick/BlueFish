import 'package:bluefish/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData initUserThemeSettings() {
  return buildAppTheme(AppSettings.defaults, brightness: Brightness.light);
}

ThemeData buildAppTheme(
  AppSettings settings, {
  required Brightness brightness,
}) {
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: GoogleFonts.notoSansSc().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: settings.seedColor,
      brightness: brightness,
    ),
  );
  final scaledTextTheme = _scaleTextTheme(
    GoogleFonts.notoSansScTextTheme(baseTheme.textTheme),
    settings,
  );

  return baseTheme.copyWith(
    textTheme: scaledTextTheme,
    primaryTextTheme: _scaleTextTheme(
      GoogleFonts.notoSansScTextTheme(baseTheme.primaryTextTheme),
      settings,
    ),
  );
}

TextTheme _scaleTextTheme(TextTheme textTheme, AppSettings settings) {
  return textTheme.copyWith(
    displayLarge: _scale(textTheme.displayLarge, settings.titleFontScale),
    displayMedium: _scale(textTheme.displayMedium, settings.titleFontScale),
    displaySmall: _scale(textTheme.displaySmall, settings.titleFontScale),
    headlineLarge: _scale(textTheme.headlineLarge, settings.titleFontScale),
    headlineMedium: _scale(textTheme.headlineMedium, settings.titleFontScale),
    headlineSmall: _scale(textTheme.headlineSmall, settings.titleFontScale),
    titleLarge: _scale(textTheme.titleLarge, settings.titleFontScale),
    titleMedium: _scale(textTheme.titleMedium, settings.titleFontScale),
    titleSmall: _scale(textTheme.titleSmall, settings.titleFontScale),
    bodyLarge: _scale(textTheme.bodyLarge, settings.contentFontScale),
    bodyMedium: _scale(textTheme.bodyMedium, settings.contentFontScale),
    bodySmall: _scale(textTheme.bodySmall, settings.contentFontScale),
    labelLarge: _scale(textTheme.labelLarge, settings.metaFontScale),
    labelMedium: _scale(textTheme.labelMedium, settings.metaFontScale),
    labelSmall: _scale(textTheme.labelSmall, settings.metaFontScale),
  );
}

TextStyle? _scale(TextStyle? style, double scale) {
  if (style == null || style.fontSize == null) {
    return style;
  }

  return style.copyWith(fontSize: style.fontSize! * scale);
}

import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/theme/bluefish_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData initUserThemeSettings() {
  return buildAppTheme(AppSettings.defaults, brightness: Brightness.light);
}

ThemeData buildAppTheme(
  AppSettings settings, {
  required Brightness brightness,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: settings.seedColor,
    brightness: brightness,
  );
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: GoogleFonts.notoSansSc().fontFamily,
    colorScheme: colorScheme,
  );
  final scaledTextTheme = _scaleTextTheme(baseTheme.textTheme, settings);

  return baseTheme.copyWith(
    textTheme: scaledTextTheme,
    primaryTextTheme: _scaleTextTheme(baseTheme.primaryTextTheme, settings),
    extensions: <ThemeExtension<dynamic>>[
      BluefishSemanticColors.fromScheme(colorScheme),
    ],
  );
}

TextTheme _scaleTextTheme(TextTheme textTheme, AppSettings settings) {
  return textTheme.copyWith(
    displayLarge: _scale(textTheme.displayLarge, 57, settings.titleFontScale),
    displayMedium: _scale(textTheme.displayMedium, 45, settings.titleFontScale),
    displaySmall: _scale(textTheme.displaySmall, 36, settings.titleFontScale),
    headlineLarge: _scale(textTheme.headlineLarge, 32, settings.titleFontScale),
    headlineMedium: _scale(
      textTheme.headlineMedium,
      28,
      settings.titleFontScale,
    ),
    headlineSmall: _scale(textTheme.headlineSmall, 24, settings.titleFontScale),
    titleLarge: _scale(textTheme.titleLarge, 22, settings.titleFontScale),
    titleMedium: _scale(textTheme.titleMedium, 16, settings.titleFontScale),
    titleSmall: _scale(textTheme.titleSmall, 14, settings.titleFontScale),
    bodyLarge: _scale(textTheme.bodyLarge, 16, settings.contentFontScale),
    bodyMedium: _scale(textTheme.bodyMedium, 14, settings.contentFontScale),
    bodySmall: _scale(textTheme.bodySmall, 12, settings.contentFontScale),
    labelLarge: _scale(textTheme.labelLarge, 14, settings.metaFontScale),
    labelMedium: _scale(textTheme.labelMedium, 12, settings.metaFontScale),
    labelSmall: _scale(textTheme.labelSmall, 11, settings.metaFontScale),
  );
}

TextStyle? _scale(TextStyle? style, double baseSize, double scale) {
  if (style == null) {
    return null;
  }

  return style.copyWith(fontSize: baseSize * scale);
}

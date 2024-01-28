import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserThemeSettings {
  var globalFontFamily = GoogleFonts.notoSansSc().fontFamily;
  var globalTextTheme = GoogleFonts.notoSansScTextTheme();
  int titleFontSize = 18;
}

ThemeData initUserThemeSettings() {
  var userTheme = UserThemeSettings();
  // TODO:
  // var userTheme = loadUserThemeSettings();
  ThemeData userThemeData = ThemeData(
    useMaterial3: true,
    fontFamily: userTheme.globalFontFamily,
    textTheme: userTheme.globalTextTheme,
  );
  return userThemeData;
}

// TODO:
// UserThemeSettings? loadUserThemeSettings() {
// }

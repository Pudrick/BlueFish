import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'title_list_page.dart';
import 'theme_settings.dart';

void main() {
  launchApp();
}

void launchApp() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],

      // TODO: theme: userThemeData,
      theme: initUserThemeSettings(),

      home: ThreadListPage(),
    ),
  );
}

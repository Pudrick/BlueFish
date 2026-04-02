import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/router/app_router.dart';
import 'package:bluefish/userdata/theme_settings.dart';

void main() {
  launchApp();
}

Future<void> launchApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize HTTP client with cookie manager
  await initializeHttpClient();

  runApp(
    MaterialApp.router(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      routerConfig: appRouter,
      theme: initUserThemeSettings(),
    ),
  );
}

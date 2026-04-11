import 'package:bluefish/app/app_provider_scope.dart';
import 'package:bluefish/app/app_services.dart';
import 'package:bluefish/app/app_session.dart';
import 'package:bluefish/router/app_router.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/userdata/theme_settings.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Future<void> main() async => launchApp();

Future<void> launchApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appSession = await AppSession.bootstrap();
  final replyPageLocatorCacheService = ReplyPageLocatorCacheService();
  await replyPageLocatorCacheService.ensureInitialized();
  final settingsViewModel = await AppSettingsViewModel.create(
    replyPageLocatorCacheService: replyPageLocatorCacheService,
  );
  final appServices = await AppServices.bootstrap(
    httpClient: appSession.httpClient,
    settingsViewModel: settingsViewModel,
    replyPageLocatorCacheService: replyPageLocatorCacheService,
  );
  final router = buildAppRouter();

  runApp(
    BluefishApp(
      appSession: appSession,
      appServices: appServices,
      settingsViewModel: settingsViewModel,
      router: router,
    ),
  );
}

class BluefishApp extends StatelessWidget {
  final AppSession appSession;
  final AppServices appServices;
  final AppSettingsViewModel settingsViewModel;
  final GoRouter router;

  const BluefishApp({
    super.key,
    required this.appSession,
    required this.appServices,
    required this.settingsViewModel,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return AppProviderScope(
      appSession: appSession,
      appServices: appServices,
      settingsViewModel: settingsViewModel,
      child: Consumer<AppSettingsViewModel>(
        builder: (context, appSettings, _) {
          return MaterialApp.router(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh'), Locale('en')],
            routerConfig: router,
            theme: buildAppTheme(
              appSettings.settings,
              brightness: Brightness.light,
            ),
            darkTheme: buildAppTheme(
              appSettings.settings,
              brightness: Brightness.dark,
            ),
            themeMode: appSettings.settings.themeMode,
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/router/app_router.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_service.dart';
import 'package:bluefish/userdata/theme_settings.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:bluefish/viewModels/current_user_profile_view_model.dart';
import 'package:provider/provider.dart';

Future<void> main() async => launchApp();

Future<void> launchApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  final replyPageLocatorCacheService = ReplyPageLocatorCacheService();
  await replyPageLocatorCacheService.ensureInitialized();
  final settingsViewModel = await AppSettingsViewModel.create(
    replyPageLocatorCacheService: replyPageLocatorCacheService,
  );
  final replyPageLocatorService = ReplyPageLocatorService(
    cacheService: replyPageLocatorCacheService,
  );

  // Initialize the auth-aware HTTP client before the widget tree mounts.
  await initializeHttpClient();
  runApp(
    BluefishApp(
      settingsViewModel: settingsViewModel,
      replyPageLocatorCacheService: replyPageLocatorCacheService,
      replyPageLocatorService: replyPageLocatorService,
    ),
  );
}

class BluefishApp extends StatelessWidget {
  final AppSettingsViewModel settingsViewModel;
  final ReplyPageLocatorCacheService replyPageLocatorCacheService;
  final ReplyPageLocatorService replyPageLocatorService;

  const BluefishApp({
    super.key,
    required this.settingsViewModel,
    required this.replyPageLocatorCacheService,
    required this.replyPageLocatorService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsViewModel>.value(
          value: settingsViewModel,
        ),
        Provider<ReplyPageLocatorCacheService>.value(
          value: replyPageLocatorCacheService,
        ),
        Provider<ReplyPageLocatorService>.value(value: replyPageLocatorService),
        ChangeNotifierProvider<AuthSessionManager>.value(
          value: authSessionManager,
        ),
        ChangeNotifierProvider<CurrentUserProfileViewModel>(
          create: (_) {
            final viewModel = CurrentUserProfileViewModel(
              authSessionManager: authSessionManager,
            );
            unawaited(viewModel.initialize());
            return viewModel;
          },
        ),
      ],
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
            routerConfig: appRouter,
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

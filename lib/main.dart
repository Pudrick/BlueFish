import 'dart:async';

import 'package:bluefish/app/app_session.dart';
import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/auth/current_user_identity_controller.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/router/app_router.dart';
import 'package:bluefish/services/media/media_save_service.dart';
import 'package:bluefish/services/mention/mention_light_service.dart';
import 'package:bluefish/services/mention/mention_reply_service.dart';
import 'package:bluefish/services/private_message/private_message_detail_service.dart';
import 'package:bluefish/services/private_message/private_message_list_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_service.dart';
import 'package:bluefish/services/thread/thread_detail_service.dart';
import 'package:bluefish/services/thread/thread_list_service.dart';
import 'package:bluefish/services/thread/thread_reply_service.dart';
import 'package:bluefish/services/user_home/current_user_profile_service.dart';
import 'package:bluefish/services/user_home/user_home_service.dart';
import 'package:bluefish/services/vote/vote_service.dart';
import 'package:bluefish/userdata/theme_settings.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:bluefish/viewModels/current_user_profile_view_model.dart';
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
  final threadDetailService = ThreadDetailService(
    client: appSession.httpClient,
  );
  final replyPageLocatorService = ReplyPageLocatorService(
    client: appSession.httpClient,
    threadDetailService: threadDetailService,
    cacheService: replyPageLocatorCacheService,
    shouldWriteJumpLogs: () => settingsViewModel.settings.generateJumpLogs,
  );
  final router = buildAppRouter();

  runApp(
    BluefishApp(
      appSession: appSession,
      settingsViewModel: settingsViewModel,
      replyPageLocatorCacheService: replyPageLocatorCacheService,
      threadDetailService: threadDetailService,
      replyPageLocatorService: replyPageLocatorService,
      router: router,
    ),
  );
}

class BluefishApp extends StatelessWidget {
  final AppSession appSession;
  final AppSettingsViewModel settingsViewModel;
  final ReplyPageLocatorCacheService replyPageLocatorCacheService;
  final ThreadDetailService threadDetailService;
  final ReplyPageLocatorService replyPageLocatorService;
  final GoRouter router;

  const BluefishApp({
    super.key,
    required this.appSession,
    required this.settingsViewModel,
    required this.replyPageLocatorCacheService,
    required this.threadDetailService,
    required this.replyPageLocatorService,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsViewModel>.value(
          value: settingsViewModel,
        ),
        Provider<AppSession>.value(value: appSession),
        Provider<AppHttpClient>.value(value: appSession.httpClient),
        ChangeNotifierProvider<AuthSessionManager>.value(
          value: appSession.authSessionManager,
        ),
        Provider<ThreadDetailService>.value(value: threadDetailService),
        Provider<ReplyPageLocatorCacheService>.value(
          value: replyPageLocatorCacheService,
        ),
        Provider<ReplyPageLocatorService>.value(value: replyPageLocatorService),
        Provider<ThreadListService>(
          create: (context) =>
              ThreadListService(client: context.read<AppHttpClient>()),
        ),
        Provider<ThreadReplyService>(
          create: (context) =>
              ThreadReplyService(client: context.read<AppHttpClient>()),
        ),
        Provider<UserHomeService>(
          create: (context) =>
              UserHomeService(client: context.read<AppHttpClient>()),
        ),
        Provider<CurrentUserProfileHttpService>(
          create: (context) => CurrentUserProfileHttpService(
            client: context.read<AppHttpClient>(),
          ),
        ),
        Provider<PrivateMessageListService>(
          create: (context) =>
              PrivateMessageListService(client: context.read<AppHttpClient>()),
        ),
        Provider<PrivateMessageDetailService>(
          create: (context) => PrivateMessageDetailService(
            client: context.read<AppHttpClient>(),
          ),
        ),
        Provider<MentionReplyService>(
          create: (context) =>
              MentionReplyService(client: context.read<AppHttpClient>()),
        ),
        Provider<MentionLightService>(
          create: (context) =>
              MentionLightService(client: context.read<AppHttpClient>()),
        ),
        Provider<VoteService>(
          create: (context) =>
              VoteService(client: context.read<AppHttpClient>()),
        ),
        Provider<MediaSaveService>(
          create: (context) =>
              MediaSaveService(client: context.read<AppHttpClient>()),
        ),
        ChangeNotifierProvider<CurrentUserProfileViewModel>(
          create: (context) {
            final viewModel = CurrentUserProfileViewModel(
              authSessionManager: context.read<AuthSessionManager>(),
              service: context.read<CurrentUserProfileHttpService>(),
            );
            unawaited(viewModel.initialize());
            return viewModel;
          },
        ),
        ChangeNotifierProxyProvider2<
          AuthSessionManager,
          CurrentUserProfileViewModel,
          CurrentUserIdentityController
        >(
          create: (_) => CurrentUserIdentityController(),
          update:
              (_, authSessionManager, currentUserProfileViewModel, controller) {
                final resolvedController =
                    controller ?? CurrentUserIdentityController();
                resolvedController.update(
                  authSessionManager: authSessionManager,
                  currentUserProfileViewModel: currentUserProfileViewModel,
                );
                return resolvedController;
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

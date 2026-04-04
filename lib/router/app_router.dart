import 'package:bluefish/pages/advanced_settings_page.dart';
import 'package:bluefish/pages/me_page.dart';
import 'package:bluefish/pages/messages_page.dart';
import 'package:bluefish/pages/create_thread_page.dart';
import 'package:bluefish/pages/settings_page.dart';
import 'package:bluefish/pages/thread_list_page.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/router/route_error_page.dart';
import 'package:bluefish/router/routes/media_routes.dart';
import 'package:bluefish/router/routes/mention_routes.dart';
import 'package:bluefish/router/routes/message_routes.dart';
import 'package:bluefish/router/routes/thread_routes.dart';
import 'package:bluefish/router/routes/user_routes.dart';
import 'package:bluefish/widgets/navigation/main_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);
final GlobalKey<NavigatorState> _threadListNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'threadListBranchNavigator');
final GlobalKey<NavigatorState> _messagesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'messagesBranchNavigator');
final GlobalKey<NavigatorState> _meNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'meBranchNavigator',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  errorBuilder: (context, state) => RouteErrorPage(
    message: '当前页面无法打开，请稍后再试。',
    details: state.error?.toString(),
  ),
  routes: [
    // Main shell with bottom/side navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        // Branch 0: Thread List (贴子列表)
        StatefulShellBranch(
          navigatorKey: _threadListNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.threadListPath,
              name: AppRouteNames.threadList,
              builder: (context, state) => const ThreadListPage(),
            ),
          ],
        ),
        // Branch 1: Messages (消息)
        StatefulShellBranch(
          navigatorKey: _messagesNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.messagesPath,
              name: AppRouteNames.messages,
              builder: (context, state) => MessagesPage(
                initialTab: AppRoutes.parseMessagesTab(
                  state.uri.queryParameters[AppRoutes
                      .messagesTabQueryParameter],
                ),
              ),
              routes: [
                buildPrivateMessageDetailRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                ),
              ],
            ),
          ],
        ),
        // Branch 2: Me (我)
        StatefulShellBranch(
          navigatorKey: _meNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.mePath,
              name: AppRouteNames.me,
              builder: (context, state) => const MePage(),
              routes: [
                GoRoute(
                  path: AppRoutes.settingsPathSegment,
                  name: AppRouteNames.settings,
                  builder: (context, state) => const SettingsPage(),
                  routes: [
                    GoRoute(
                      path: AppRoutes.advancedSettingsPathSegment,
                      name: AppRouteNames.advancedSettings,
                      builder: (context, state) => const AdvancedSettingsPage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Independent routes (without navigation shell)
    GoRoute(
      path: AppRoutes.createThreadPath,
      name: AppRouteNames.createThread,
      builder: (context, state) => const CreateThreadPage(),
    ),
    ...threadRoutes,
    ...userRoutes,
    ...mentionRoutes,
    ...legacyMessageRoutes,
    ...mediaRoutes,
  ],
);

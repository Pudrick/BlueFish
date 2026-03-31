import 'package:bluefish/pages/me_page.dart';
import 'package:bluefish/pages/messages_page.dart';
import 'package:bluefish/pages/thread_list_page.dart';
import 'package:bluefish/router/route_names.dart';
import 'package:bluefish/router/routes/media_routes.dart';
import 'package:bluefish/router/routes/mention_routes.dart';
import 'package:bluefish/router/routes/message_routes.dart';
import 'package:bluefish/router/routes/thread_routes.dart';
import 'package:bluefish/router/routes/user_routes.dart';
import 'package:bluefish/widgets/navigation/main_shell.dart';
import 'package:go_router/go_router.dart';

// Re-export route names for convenient imports
export 'package:bluefish/router/route_names.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    // Main shell with bottom/side navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(
        navigationShell: navigationShell,
      ),
      branches: [
        // Branch 0: Thread List (贴子列表)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: AppRouteNames.threadList,
              builder: (context, state) => const ThreadListPage(),
            ),
          ],
        ),
        // Branch 1: Messages (消息)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/messages',
              name: AppRouteNames.messages,
              builder: (context, state) => const MessagesPage(),
            ),
          ],
        ),
        // Branch 2: Me (我)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/me',
              name: AppRouteNames.me,
              builder: (context, state) => const MePage(),
            ),
          ],
        ),
      ],
    ),
    // Independent routes (without navigation shell)
    ...threadRoutes,
    ...userRoutes,
    ...mentionRoutes,
    ...messageRoutes,
    ...mediaRoutes,
  ],
);

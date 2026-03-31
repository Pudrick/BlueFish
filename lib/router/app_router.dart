import 'package:bluefish/pages/thread_list_page.dart';
import 'package:bluefish/router/routes/media_routes.dart';
import 'package:bluefish/router/routes/mention_routes.dart';
import 'package:bluefish/router/routes/message_routes.dart';
import 'package:bluefish/router/routes/thread_routes.dart';
import 'package:bluefish/router/routes/user_routes.dart';
import 'package:go_router/go_router.dart';

// Re-export route names for convenient imports
export 'package:bluefish/router/route_names.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ThreadListPage(),
      routes: [
        ...threadRoutes,
        ...userRoutes,
        ...mentionRoutes,
        ...messageRoutes,
        ...mediaRoutes,
      ],
    ),
  ],
);

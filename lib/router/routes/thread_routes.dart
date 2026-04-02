import 'package:bluefish/pages/thread_page.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/router/route_error_page.dart';
import 'package:go_router/go_router.dart';

final threadRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.threadDetailPath,
    name: AppRouteNames.threadDetail,
    builder: (context, state) {
      final tid = state.pathParameters[AppRoutes.threadIdParameter]?.trim();
      if (tid == null || tid.isEmpty) {
        return const RouteErrorPage(message: '帖子参数无效，无法打开详情页。');
      }

      final page = AppRoutes.parseThreadPage(
        state.uri.queryParameters[AppRoutes.threadPageQueryParameter],
      );
      return ThreadPage(tid: tid, page: page);
    },
  ),
];

import 'package:bluefish/pages/thread_page.dart';
import 'package:bluefish/router/route_names.dart';
import 'package:go_router/go_router.dart';

final threadRoutes = <RouteBase>[
  GoRoute(
    path: '/thread/:tid',
    name: AppRouteNames.threadDetail,
    builder: (context, state) {
      final tid = state.pathParameters['tid']!;
      final page =
          int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 1;
      return ThreadPage(tid: tid, page: page);
    },
  ),
];

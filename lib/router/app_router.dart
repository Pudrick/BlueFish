import 'package:bluefish/pages/thread_list_page.dart';
import 'package:bluefish/pages/thread_page.dart';
import 'package:go_router/go_router.dart';

class AppRouteNames {
  static const String threadDetail = 'threadDetail';
}

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ThreadListPage(),
      routes: [
        GoRoute(
          path: 'thread/:tid',
          name: AppRouteNames.threadDetail,
          builder: (context, state) {
            final tid = state.pathParameters['tid']!;
            final page =
                int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 1;
            return ThreadPage(tid: tid, page: page);
          },
        ),
      ],
    ),
  ],
);

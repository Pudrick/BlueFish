import 'package:bluefish/pages/mention_page.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:go_router/go_router.dart';

final mentionRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.mentionPath,
    name: AppRouteNames.mention,
    builder: (context, state) {
      final initialTab = MentionTab.fromQueryValue(
        state.uri.queryParameters[AppRoutes.mentionTabQueryParameter],
      );
      return MentionPage(initialTab: initialTab);
    },
  ),
];

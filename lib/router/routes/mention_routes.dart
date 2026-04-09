import 'package:bluefish/router/app_route_contracts.dart';
import 'package:go_router/go_router.dart';

final mentionRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.mentionPath,
    name: AppRouteNames.mention,
    redirect: (context, state) {
      final initialTab = MentionTab.fromQueryValue(
        state.uri.queryParameters[AppRoutes.mentionTabQueryParameter],
      );
      return AppRoutes.messagesLocation(tab: initialTab);
    },
  ),
];

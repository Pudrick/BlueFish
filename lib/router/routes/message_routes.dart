import 'package:bluefish/pages/private_message_detail_page.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/router/route_error_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

RouteBase buildPrivateMessageDetailRoute({
  required GlobalKey<NavigatorState> parentNavigatorKey,
}) {
  return GoRoute(
    path: AppRoutes.privateMessageDetailPathSegment,
    name: AppRouteNames.privateMessageDetail,
    parentNavigatorKey: parentNavigatorKey,
    builder: _buildPrivateMessageDetailPage,
  );
}

final legacyMessageRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.privateMessageLegacyPath,
    redirect: (context, state) {
      final puid = AppRoutes.parsePositiveInt(
        state.pathParameters[AppRoutes.privateMessageUserIdParameter],
      );
      if (puid == null) {
        return null;
      }

      final title = state
          .uri
          .queryParameters[AppRoutes.privateMessageTitleQueryParameter];
      final avatarUrl = state
          .uri
          .queryParameters[AppRoutes.privateMessageAvatarQueryParameter];
      return AppRoutes.privateMessageDetailLocation(
        puid: puid,
        title: title,
        avatarUrl: avatarUrl,
      );
    },
    builder: _buildPrivateMessageDetailPage,
  ),
];

Widget _buildPrivateMessageDetailPage(
  BuildContext context,
  GoRouterState state,
) {
  final puid = AppRoutes.parsePositiveInt(
    state.pathParameters[AppRoutes.privateMessageUserIdParameter],
  );
  if (puid == null) {
    return const RouteErrorPage(message: '私信参数无效，无法打开会话。');
  }

  final title =
      state.uri.queryParameters[AppRoutes.privateMessageTitleQueryParameter];
  final avatarUrl =
      state.uri.queryParameters[AppRoutes.privateMessageAvatarQueryParameter];
  return PrivateMessageDetailPage(
    puid: puid,
    initialTitle: title,
    initialAvatarUrl: avatarUrl,
  );
}

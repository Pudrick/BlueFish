import 'package:bluefish/pages/private_message_detail_page.dart';
import 'package:bluefish/router/route_names.dart';
import 'package:go_router/go_router.dart';

final messageRoutes = <RouteBase>[
  GoRoute(
    path: '/message/:puid',
    name: AppRouteNames.privateMessageDetail,
    builder: (context, state) {
      final puid = int.parse(state.pathParameters['puid']!);
      final title = state.uri.queryParameters['title'];
      final avatarUrl = state.uri.queryParameters['avatar'];
      return PrivateMessageDetailPage(
        puid: puid,
        initialTitle: title,
        initialAvatarUrl: avatarUrl,
      );
    },
  ),
];

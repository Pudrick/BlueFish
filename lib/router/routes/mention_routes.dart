import 'package:bluefish/pages/mention_light_page.dart';
import 'package:bluefish/pages/mention_page.dart';
import 'package:bluefish/pages/mention_reply_page.dart';
import 'package:bluefish/router/route_names.dart';
import 'package:go_router/go_router.dart';

final mentionRoutes = <RouteBase>[
  GoRoute(
    path: 'mention',
    name: AppRouteNames.mention,
    builder: (context, state) {
      final tabParam = state.uri.queryParameters['tab'];
      final initialTab = tabParam == 'light' ? MentionTab.light : MentionTab.reply;
      return MentionPage(initialTab: initialTab);
    },
    routes: [
      GoRoute(
        path: 'reply',
        name: AppRouteNames.mentionReply,
        builder: (context, state) => const MentionReplyPage(),
      ),
      GoRoute(
        path: 'light',
        name: AppRouteNames.mentionLight,
        builder: (context, state) => const MentionLightPage(),
      ),
    ],
  ),
];

import 'package:bluefish/models/composer/reply_draft.dart';
import 'package:bluefish/widgets/composer/reply_composer_sheet.dart';
import 'package:flutter/material.dart';
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
      final onlyEuid = AppRoutes.parseThreadOnlyEuid(
        state.uri.queryParameters[AppRoutes.threadOnlyEuidQueryParameter],
      );
      final onlyPuid = AppRoutes.parseThreadOnlyPuid(
        state.uri.queryParameters[AppRoutes.threadOnlyPuidQueryParameter],
      );
      return ThreadPage(
        tid: tid,
        page: page,
        onlyEuid: onlyEuid,
        onlyPuid: onlyPuid,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.threadReplyComposerPathSegment,
        name: AppRouteNames.threadReplyComposer,
        pageBuilder: (context, state) {
          final routeData = ThreadReplyComposerRouteData.tryParse(state.extra);
          final contextLabel = routeData?.contextLabel;
          final contextPreview = routeData?.contextPreview;

          return CustomTransitionPage<void>(
            key: state.pageKey,
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.black54,
            barrierLabel: MaterialLocalizations.of(
              context,
            ).modalBarrierDismissLabel,
            transitionDuration: replyComposerSheetTransitionDuration,
            reverseTransitionDuration:
                replyComposerSheetReverseTransitionDuration,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return buildReplyComposerSheetTransition(
                    animation: animation,
                    child: child,
                  );
                },
            child: ReplyComposerSheet(
              title: '发送回复',
              submitLabel: '发送',
              contextLabel: contextLabel == null || contextLabel.isEmpty
                  ? '回复该内容'
                  : contextLabel,
              contextPreview: contextPreview,
              initialDraft: ReplyDraft.empty(),
              onSubmit: (_) async {},
            ),
          );
        },
      ),
    ],
  ),
];

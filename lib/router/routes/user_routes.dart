import 'package:bluefish/models/author_identity.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/pages/user_home_page.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/router/auth_guard.dart';
import 'package:bluefish/router/route_error_page.dart';
import 'package:bluefish/widgets/common/auth_required_gate_page.dart';
import 'package:go_router/go_router.dart';

final userRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.userHomePath,
    name: AppRouteNames.userHome,
    builder: (context, state) {
      final AuthorIdentity? userIdentity = AppRoutes.parseUserHomeIdentity(
        state.pathParameters[AppRoutes.userIdParameter],
        rawType: state.uri.queryParameters[AppRoutes.userIdTypeQueryParameter],
      );
      if (userIdentity == null) {
        return const RouteErrorPage(message: '用户参数无效，无法打开主页。');
      }

      if (!authSessionManager.isLoggedIn) {
        return AuthRequiredGatePage(
          policy: AuthGuardPolicies.userHome,
          isLoggedIn: authSessionManager.isLoggedIn,
          onBackPressed: () => context.popOrGoThreadList(),
          onGoToLogin: (context) async {
            await context.pushLogin<void>();
          },
          blockedHint: '登录后可访问用户主页。',
        );
      }

      return UserHomePage(userIdentity: userIdentity);
    },
  ),
];

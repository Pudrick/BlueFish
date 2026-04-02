import 'package:bluefish/pages/user_home_page.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/router/route_error_page.dart';
import 'package:go_router/go_router.dart';

final userRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.userHomePath,
    name: AppRouteNames.userHome,
    builder: (context, state) {
      final euid = AppRoutes.parsePositiveInt(
        state.pathParameters[AppRoutes.userIdParameter],
      );
      if (euid == null) {
        return const RouteErrorPage(message: '用户参数无效，无法打开主页。');
      }

      return UserHomePage(euid: euid);
    },
  ),
];

import 'package:bluefish/pages/user_home_page.dart';
import 'package:bluefish/router/route_names.dart';
import 'package:go_router/go_router.dart';

final userRoutes = <RouteBase>[
  GoRoute(
    path: '/user/:euid',
    name: AppRouteNames.userHome,
    builder: (context, state) {
      final euid = int.parse(state.pathParameters['euid']!);
      return UserHomePage(euid: euid);
    },
  ),
];

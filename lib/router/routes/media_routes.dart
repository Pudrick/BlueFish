import 'package:bluefish/pages/photo_gallery_page.dart';
import 'package:bluefish/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final mediaRoutes = <RouteBase>[
  GoRoute(
    path: '/gallery',
    name: AppRouteNames.photoGallery,
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final imageUrls = extra?['imageUrls'] as List<String>? ?? [];
      final initialIndex = extra?['initialIndex'] as int? ?? 0;
      final heroTags = extra?['heroTags'] as List<Object>?;

      return CustomTransitionPage(
        key: state.pageKey,
        child: PhotoGalleryPage(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          heroTags: heroTags,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
  ),
];

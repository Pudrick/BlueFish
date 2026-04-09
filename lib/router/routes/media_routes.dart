import 'package:bluefish/pages/media/photo_gallery_page.dart';
import 'package:bluefish/router/app_navigation_extensions.dart';
import 'package:bluefish/router/app_route_contracts.dart';
import 'package:bluefish/router/models/photo_gallery_route_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final mediaRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.photoGalleryPath,
    name: AppRouteNames.photoGallery,
    pageBuilder: (context, state) {
      final routeData = PhotoGalleryRouteData.tryParse(state.extra);
      if (routeData == null) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const _InvalidPhotoGalleryPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      }

      return CustomTransitionPage(
        key: state.pageKey,
        child: PhotoGalleryPage(
          imageUrls: routeData.imageUrls,
          initialIndex: routeData.initialIndex,
          heroTags: routeData.heroTags,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
  ),
];

class _InvalidPhotoGalleryPage extends StatelessWidget {
  const _InvalidPhotoGalleryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('图片预览')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, size: 40),
              const SizedBox(height: 12),
              const Text('缺少可预览的图片，无法打开图库。', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: context.goThreadList,
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

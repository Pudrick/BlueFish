import 'package:bluefish/pages/photo_gallery_page.dart';
import 'package:bluefish/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final mediaRoutes = <RouteBase>[
  GoRoute(
    path: '/gallery',
    name: AppRouteNames.photoGallery,
    pageBuilder: (context, state) {
      final routeData = _PhotoGalleryRouteData.tryParse(state.extra);
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

class _PhotoGalleryRouteData {
  final List<String> imageUrls;
  final int initialIndex;
  final List<Object>? heroTags;

  const _PhotoGalleryRouteData({
    required this.imageUrls,
    required this.initialIndex,
    required this.heroTags,
  });

  static _PhotoGalleryRouteData? tryParse(Object? extra) {
    if (extra is! Map) {
      return null;
    }

    final rawImageUrls = extra['imageUrls'];
    if (rawImageUrls is! List || rawImageUrls.isEmpty) {
      return null;
    }

    late final List<String> imageUrls;
    try {
      imageUrls = rawImageUrls
          .cast<String>()
          .map((url) => url.trim())
          .toList(growable: false);
    } catch (_) {
      return null;
    }

    if (imageUrls.any((url) => url.isEmpty)) {
      return null;
    }

    final rawInitialIndex = extra['initialIndex'];
    final initialIndex = rawInitialIndex is int ? rawInitialIndex : 0;
    if (initialIndex < 0 || initialIndex >= imageUrls.length) {
      return null;
    }

    final rawHeroTags = extra['heroTags'];
    List<Object>? heroTags;
    if (rawHeroTags != null) {
      if (rawHeroTags is! List) {
        return null;
      }

      try {
        heroTags = rawHeroTags.cast<Object>().toList(growable: false);
      } catch (_) {
        return null;
      }
    }

    return _PhotoGalleryRouteData(
      imageUrls: imageUrls,
      initialIndex: initialIndex,
      heroTags: heroTags,
    );
  }
}

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
                onPressed: () => context.go('/'),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

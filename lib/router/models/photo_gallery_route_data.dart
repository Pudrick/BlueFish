import 'package:flutter/foundation.dart';

@immutable
class PhotoGalleryRouteData {
  static const String _imageUrlsKey = 'imageUrls';
  static const String _initialIndexKey = 'initialIndex';
  static const String _heroTagsKey = 'heroTags';

  final List<String> imageUrls;
  final int initialIndex;
  final List<Object>? heroTags;

  const PhotoGalleryRouteData({
    required this.imageUrls,
    required this.initialIndex,
    this.heroTags,
  });

  Map<String, Object?> toExtra() {
    return <String, Object?>{
      _imageUrlsKey: imageUrls,
      _initialIndexKey: initialIndex,
      if (heroTags != null) _heroTagsKey: heroTags,
    };
  }

  static PhotoGalleryRouteData? tryParse(Object? extra) {
    if (extra is! Map) {
      return null;
    }

    final rawImageUrls = extra[_imageUrlsKey];
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

    final rawInitialIndex = extra[_initialIndexKey];
    final initialIndex = rawInitialIndex is int ? rawInitialIndex : 0;
    if (initialIndex < 0 || initialIndex >= imageUrls.length) {
      return null;
    }

    final rawHeroTags = extra[_heroTagsKey];
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

    return PhotoGalleryRouteData(
      imageUrls: imageUrls,
      initialIndex: initialIndex,
      heroTags: heroTags,
    );
  }
}

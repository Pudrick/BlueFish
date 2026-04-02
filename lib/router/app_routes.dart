import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

enum MentionTab {
  reply,
  light,
  privateMessage;

  static MentionTab fromQueryValue(String? value) {
    return switch (value?.trim()) {
      'light' => MentionTab.light,
      'private' => MentionTab.privateMessage,
      _ => MentionTab.reply,
    };
  }

  String get queryValue => switch (this) {
    MentionTab.reply => 'reply',
    MentionTab.light => 'light',
    MentionTab.privateMessage => 'private',
  };
}

/// Centralized route name constants for application pages.
class AppRouteNames {
  AppRouteNames._();

  static const String threadList = 'threadList';
  static const String messages = 'messages';
  static const String me = 'me';
  static const String threadDetail = 'threadDetail';
  static const String userHome = 'userHome';
  static const String mention = 'mention';
  static const String privateMessageDetail = 'privateMessageDetail';
  static const String photoGallery = 'photoGallery';
}

/// Canonical route paths and parameter contracts.
class AppRoutes {
  AppRoutes._();

  static const String threadListPath = '/';
  static const String messagesPath = '/messages';
  static const String mePath = '/me';

  static const String threadIdParameter = 'tid';
  static const String threadPageQueryParameter = 'page';
  static const String threadDetailPath = '/thread/:$threadIdParameter';

  static const String userIdParameter = 'euid';
  static const String userHomePath = '/user/:$userIdParameter';

  static const String messagesTabQueryParameter = 'tab';
  static const String mentionTabQueryParameter = 'tab';
  static const String mentionPath = '/mention';

  static const String privateMessageUserIdParameter = 'puid';
  static const String privateMessageTitleQueryParameter = 'title';
  static const String privateMessageAvatarQueryParameter = 'avatar';
  static const String privateMessageDetailPath =
      '$messagesPath/:$privateMessageUserIdParameter';
  static const String privateMessageDetailPathSegment =
      ':$privateMessageUserIdParameter';
  static const String privateMessageLegacyPath =
      '/message/:$privateMessageUserIdParameter';

  static const String photoGalleryPath = '/gallery';

  static int parseThreadPage(String? rawValue) {
    final parsed = int.tryParse(rawValue ?? '');
    if (parsed == null || parsed < 1) {
      return 1;
    }
    return parsed;
  }

  static int? parsePositiveInt(String? rawValue) {
    final parsed = int.tryParse(rawValue ?? '');
    if (parsed == null || parsed < 1) {
      return null;
    }
    return parsed;
  }

  static String threadDetailLocation({required String tid, int page = 1}) {
    return Uri(
      path: '/thread/${tid.trim()}',
      queryParameters: _threadQueryParameters(page),
    ).toString();
  }

  static String userHomeLocation({required String euid}) {
    return '/user/${euid.trim()}';
  }

  static String mentionLocation({MentionTab tab = MentionTab.reply}) {
    return Uri(
      path: mentionPath,
      queryParameters: _mentionQueryParameters(tab),
    ).toString();
  }

  static MentionTab parseMessagesTab(String? rawValue) {
    return switch (rawValue?.trim()) {
      'reply' => MentionTab.reply,
      'light' => MentionTab.light,
      'private' => MentionTab.privateMessage,
      _ => MentionTab.privateMessage,
    };
  }

  static String messagesLocation({MentionTab tab = MentionTab.privateMessage}) {
    return Uri(
      path: messagesPath,
      queryParameters: _messagesQueryParameters(tab),
    ).toString();
  }

  static String privateMessageDetailLocation({
    required int puid,
    String? title,
    String? avatarUrl,
  }) {
    return Uri(
      path: '$messagesPath/$puid',
      queryParameters: _privateMessageQueryParameters(
        title: title,
        avatarUrl: avatarUrl,
      ),
    ).toString();
  }

  static Map<String, String>? _threadQueryParameters(int page) {
    if (page <= 1) {
      return null;
    }
    return <String, String>{threadPageQueryParameter: '$page'};
  }

  static Map<String, String>? _mentionQueryParameters(MentionTab tab) {
    if (tab == MentionTab.reply) {
      return null;
    }
    return <String, String>{mentionTabQueryParameter: tab.queryValue};
  }

  static Map<String, String>? _messagesQueryParameters(MentionTab tab) {
    if (tab == MentionTab.privateMessage) {
      return null;
    }

    return <String, String>{messagesTabQueryParameter: tab.queryValue};
  }

  static Map<String, String>? _privateMessageQueryParameters({
    String? title,
    String? avatarUrl,
  }) {
    final queryParameters = <String, String>{};
    final trimmedTitle = title?.trim();
    final trimmedAvatarUrl = avatarUrl?.trim();

    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      queryParameters[privateMessageTitleQueryParameter] = trimmedTitle;
    }
    if (trimmedAvatarUrl != null && trimmedAvatarUrl.isNotEmpty) {
      queryParameters[privateMessageAvatarQueryParameter] = trimmedAvatarUrl;
    }

    if (queryParameters.isEmpty) {
      return null;
    }
    return queryParameters;
  }
}

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

extension AppNavigationExtensions on BuildContext {
  GoRouter? get maybeGoRouter => GoRouter.maybeOf(this);

  Uri? get maybeGoRouterUri => maybeGoRouter?.state.uri;

  void goThreadList() {
    final router = maybeGoRouter;
    if (router == null) {
      return;
    }

    router.go(AppRoutes.threadListPath);
  }

  void popOrGoThreadList() {
    final router = maybeGoRouter;
    if (router == null) {
      Navigator.maybePop(this);
      return;
    }

    if (router.canPop()) {
      router.pop();
      return;
    }

    goThreadList();
  }

  Future<T?> pushThreadDetail<T>({required Object tid, int page = 1}) {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(
      AppRoutes.threadDetailLocation(tid: tid.toString(), page: page),
    );
  }

  void replaceThreadDetail({required Object tid, int page = 1}) {
    final router = maybeGoRouter;
    if (router == null) {
      return;
    }

    router.replace(
      AppRoutes.threadDetailLocation(tid: tid.toString(), page: page),
    );
  }

  Future<T?> pushUserHome<T>({required Object euid}) {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(AppRoutes.userHomeLocation(euid: euid.toString()));
  }

  Future<T?> pushMention<T>({MentionTab tab = MentionTab.reply}) {
    return pushMessages(tab: tab);
  }

  Future<T?> pushMessages<T>({MentionTab tab = MentionTab.privateMessage}) {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(AppRoutes.messagesLocation(tab: tab));
  }

  void replaceMention({MentionTab tab = MentionTab.reply}) {
    replaceMessages(tab: tab);
  }

  void replaceMessages({MentionTab tab = MentionTab.privateMessage}) {
    final router = maybeGoRouter;
    if (router == null) {
      return;
    }

    router.replace(AppRoutes.messagesLocation(tab: tab));
  }

  Future<T?> pushPrivateMessageDetail<T>({
    required int puid,
    String? title,
    String? avatarUrl,
  }) {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(
      AppRoutes.privateMessageDetailLocation(
        puid: puid,
        title: title,
        avatarUrl: avatarUrl,
      ),
    );
  }

  Future<T?> pushPhotoGallery<T>({
    required List<String> imageUrls,
    required int initialIndex,
    List<Object>? heroTags,
  }) {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(
      AppRoutes.photoGalleryPath,
      extra: PhotoGalleryRouteData(
        imageUrls: List<String>.unmodifiable(imageUrls),
        initialIndex: initialIndex,
        heroTags: heroTags == null ? null : List<Object>.unmodifiable(heroTags),
      ).toExtra(),
    );
  }
}

import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/router/auth_guard.dart';
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
  static const String createThread = 'createThread';
  static const String login = 'login';
  static const String messages = 'messages';
  static const String me = 'me';
  static const String settings = 'settings';
  static const String advancedSettings = 'advancedSettings';
  static const String threadDetail = 'threadDetail';
  static const String threadReplyComposer = 'threadReplyComposer';
  static const String userHome = 'userHome';
  static const String mention = 'mention';
  static const String privateMessageDetail = 'privateMessageDetail';
  static const String photoGallery = 'photoGallery';
}

/// Canonical route paths and parameter contracts.
class AppRoutes {
  AppRoutes._();

  static const String threadListPath = '/';
  static const String createThreadPath = '/compose/thread';
  static const String loginPath = '/login';
  static const String messagesPath = '/messages';
  static const String mePath = '/me';
  static const String settingsPathSegment = 'settings';
  static const String settingsPath = '$mePath/$settingsPathSegment';
  static const String advancedSettingsPathSegment = 'advanced';
  static const String advancedSettingsPath =
      '$settingsPath/$advancedSettingsPathSegment';

  static const String threadIdParameter = 'tid';
  static const String threadReplyIdParameter = 'pid';
  static const String threadPageQueryParameter = 'page';
  static const String threadOnlyEuidQueryParameter = 'onlyEuid';
  static const String threadDetailPath = '/thread/:$threadIdParameter';
  static const String threadReplyComposerPathSegment =
      'reply/:$threadReplyIdParameter';

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

  static String? parseThreadOnlyEuid(String? rawValue) {
    final normalized = rawValue?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static int? parsePositiveInt(String? rawValue) {
    final parsed = int.tryParse(rawValue ?? '');
    if (parsed == null || parsed < 1) {
      return null;
    }
    return parsed;
  }

  static String threadDetailPathForTid(String tid) => '/thread/${tid.trim()}';

  static String threadDetailLocation({
    required String tid,
    int page = 1,
    String? onlyEuid,
  }) {
    return Uri(
      path: threadDetailPathForTid(tid),
      queryParameters: _threadQueryParameters(page, onlyEuid: onlyEuid),
    ).toString();
  }

  static String threadReplyComposerLocation({
    required String tid,
    required String pid,
    int page = 1,
    String? onlyEuid,
  }) {
    return Uri(
      path: '${threadDetailPathForTid(tid)}/reply/${pid.trim()}',
      queryParameters: _threadQueryParameters(page, onlyEuid: onlyEuid),
    ).toString();
  }

  static String createThreadLocation() {
    return createThreadPath;
  }

  static String loginLocation() {
    return loginPath;
  }

  static String settingsLocation() {
    return settingsPath;
  }

  static String advancedSettingsLocation() {
    return advancedSettingsPath;
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

  static Map<String, String>? _threadQueryParameters(
    int page, {
    String? onlyEuid,
  }) {
    final queryParameters = <String, String>{};

    if (page > 1) {
      queryParameters[threadPageQueryParameter] = '$page';
    }

    final normalizedOnlyEuid = parseThreadOnlyEuid(onlyEuid);
    if (normalizedOnlyEuid != null) {
      queryParameters[threadOnlyEuidQueryParameter] = normalizedOnlyEuid;
    }

    if (queryParameters.isEmpty) {
      return null;
    }

    return queryParameters;
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

@immutable
class ThreadReplyComposerRouteData {
  static const String _contextLabelKey = 'contextLabel';
  static const String _contextPreviewKey = 'contextPreview';

  final String? contextLabel;
  final String? contextPreview;

  const ThreadReplyComposerRouteData({this.contextLabel, this.contextPreview});

  Object? toExtra() {
    final extra = <String, Object?>{};
    final trimmedContextLabel = contextLabel?.trim();
    final trimmedContextPreview = contextPreview?.trim();

    if (trimmedContextLabel != null && trimmedContextLabel.isNotEmpty) {
      extra[_contextLabelKey] = trimmedContextLabel;
    }
    if (trimmedContextPreview != null && trimmedContextPreview.isNotEmpty) {
      extra[_contextPreviewKey] = trimmedContextPreview;
    }

    if (extra.isEmpty) {
      return null;
    }
    return extra;
  }

  static ThreadReplyComposerRouteData? tryParse(Object? extra) {
    if (extra == null) {
      return const ThreadReplyComposerRouteData();
    }
    if (extra is! Map) {
      return null;
    }

    final rawContextLabel = extra[_contextLabelKey];
    final rawContextPreview = extra[_contextPreviewKey];

    if ((rawContextLabel != null && rawContextLabel is! String) ||
        (rawContextPreview != null && rawContextPreview is! String)) {
      return null;
    }

    return ThreadReplyComposerRouteData(
      contextLabel: (rawContextLabel as String?)?.trim(),
      contextPreview: (rawContextPreview as String?)?.trim(),
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

  Future<T?> pushCreateThread<T>() {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(AppRoutes.createThreadLocation());
  }

  Future<T?> pushLogin<T>() {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(AppRoutes.loginLocation());
  }

  Future<T?> pushSettings<T>() {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(AppRoutes.settingsLocation());
  }

  Future<T?> pushAdvancedSettings<T>() {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(AppRoutes.advancedSettingsLocation());
  }

  Future<T?> pushThreadDetail<T>({
    required Object tid,
    int page = 1,
    String? onlyEuid,
  }) {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(
      AppRoutes.threadDetailLocation(
        tid: tid.toString(),
        page: page,
        onlyEuid: onlyEuid,
      ),
    );
  }

  void replaceThreadDetail({
    required Object tid,
    int page = 1,
    String? onlyEuid,
  }) {
    final router = maybeGoRouter;
    if (router == null) {
      return;
    }

    router.replace(
      AppRoutes.threadDetailLocation(
        tid: tid.toString(),
        page: page,
        onlyEuid: onlyEuid,
      ),
    );
  }

  Future<T?> pushThreadReplyComposer<T>({
    required Object tid,
    required Object pid,
    int page = 1,
    String? onlyEuid,
    String? contextLabel,
    String? contextPreview,
  }) {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    return router.push<T>(
      AppRoutes.threadReplyComposerLocation(
        tid: tid.toString(),
        pid: pid.toString(),
        page: page,
        onlyEuid: onlyEuid,
      ),
      extra: ThreadReplyComposerRouteData(
        contextLabel: contextLabel,
        contextPreview: contextPreview,
      ).toExtra(),
    );
  }

  Future<T?> pushUserHome<T>({required Object euid}) async {
    final router = maybeGoRouter;
    if (router == null) {
      return Future<T?>.value(null);
    }

    final guardDecision = await AuthNavigationGuard.checkAccess(
      context: this,
      isLoggedIn: authSessionManager.isLoggedIn,
      policy: AuthGuardPolicies.userHome,
    );

    if (guardDecision == AuthGuardDecision.goToLogin) {
      await router.push<void>(AppRoutes.loginLocation());
      return null;
    }
    if (guardDecision == AuthGuardDecision.stay) {
      return null;
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

  void popOrGoMessages({MentionTab tab = MentionTab.privateMessage}) {
    final router = maybeGoRouter;
    if (router == null) {
      Navigator.maybePop(this);
      return;
    }

    if (router.canPop()) {
      router.pop();
      return;
    }

    router.go(AppRoutes.messagesLocation(tab: tab));
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

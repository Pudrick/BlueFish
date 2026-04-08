import 'package:bluefish/models/author_identity.dart';

export 'app_navigation_extensions.dart';
export 'models/photo_gallery_route_data.dart';
export 'models/thread_reply_composer_route_data.dart';

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
  static const String threadOnlyPuidQueryParameter = 'onlyPuid';
  static const String threadDetailPath = '/thread/:$threadIdParameter';
  static const String threadReplyComposerPathSegment =
      'reply/:$threadReplyIdParameter';

  static const String userIdParameter = 'userId';
  static const String userIdTypeQueryParameter = 'idType';
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
    return _normalizeAuthorId(rawValue);
  }

  static String? parseThreadOnlyPuid(String? rawValue) {
    return _normalizeAuthorId(rawValue);
  }

  static AuthorIdentity? parseThreadAuthorIdentity({
    String? onlyEuid,
    String? onlyPuid,
  }) {
    return AuthorIdentity.fromTyped(
      euid: parseThreadOnlyEuid(onlyEuid),
      puid: parseThreadOnlyPuid(onlyPuid),
    );
  }

  static AuthorIdentity? parseUserHomeIdentity(
    String? rawValue, {
    String? rawType,
  }) {
    final normalizedValue = _normalizeAuthorId(rawValue);
    if (normalizedValue == null) {
      return null;
    }

    return switch (rawType?.trim()) {
      'euid' => AuthorIdentity.fromTyped(euid: normalizedValue),
      'puid' => AuthorIdentity.fromTyped(puid: normalizedValue),
      null || '' => AuthorIdentity.infer(normalizedValue),
      _ => null,
    };
  }

  static String? _normalizeAuthorId(String? rawValue) {
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
    String? onlyPuid,
  }) {
    return Uri(
      path: threadDetailPathForTid(tid),
      queryParameters: _threadQueryParameters(
        page,
        onlyEuid: onlyEuid,
        onlyPuid: onlyPuid,
      ),
    ).toString();
  }

  static String threadReplyComposerLocation({
    required String tid,
    required String pid,
    int page = 1,
    String? onlyEuid,
    String? onlyPuid,
  }) {
    return Uri(
      path: '${threadDetailPathForTid(tid)}/reply/${pid.trim()}',
      queryParameters: _threadQueryParameters(
        page,
        onlyEuid: onlyEuid,
        onlyPuid: onlyPuid,
      ),
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

  static String userHomeLocation({Object? euid, Object? puid, Object? userId}) {
    final resolvedIdentity = _resolveExplicitOrInferredAuthorIdentity(
      euid: euid?.toString(),
      puid: puid?.toString(),
      rawId: userId?.toString(),
    );
    if (resolvedIdentity == null) {
      throw ArgumentError('User home identity must be a valid euid or puid.');
    }

    return Uri(
      path: '/user/${resolvedIdentity.id}',
      queryParameters: <String, String>{
        userIdTypeQueryParameter: resolvedIdentity.kind.name,
      },
    ).toString();
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
    String? onlyPuid,
  }) {
    final queryParameters = <String, String>{};

    if (page > 1) {
      queryParameters[threadPageQueryParameter] = '$page';
    }

    final normalizedOnlyEuid = parseThreadOnlyEuid(onlyEuid);
    final normalizedOnlyPuid = parseThreadOnlyPuid(onlyPuid);
    if (normalizedOnlyEuid != null && normalizedOnlyPuid != null) {
      throw ArgumentError('onlyEuid and onlyPuid are mutually exclusive.');
    }
    if (normalizedOnlyEuid != null) {
      queryParameters[threadOnlyEuidQueryParameter] = normalizedOnlyEuid;
    }
    if (normalizedOnlyPuid != null) {
      queryParameters[threadOnlyPuidQueryParameter] = normalizedOnlyPuid;
    }

    if (queryParameters.isEmpty) {
      return null;
    }

    return queryParameters;
  }

  static AuthorIdentity? _resolveExplicitOrInferredAuthorIdentity({
    String? euid,
    String? puid,
    String? rawId,
  }) {
    final normalizedEuid = _normalizeAuthorId(euid);
    final normalizedPuid = _normalizeAuthorId(puid);
    final normalizedRawId = _normalizeAuthorId(rawId);

    final explicitIdentity = AuthorIdentity.fromTyped(
      euid: normalizedEuid,
      puid: normalizedPuid,
    );
    if (explicitIdentity != null) {
      return explicitIdentity;
    }

    if (normalizedEuid != null && normalizedPuid != null) {
      return null;
    }

    return AuthorIdentity.infer(normalizedRawId);
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

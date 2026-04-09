import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/router/auth_guard.dart';
import 'package:bluefish/router/models/photo_gallery_route_data.dart';
import 'package:bluefish/router/models/thread_reply_composer_route_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_route_contracts.dart' show AppRoutes, MentionTab;

@immutable
class ThreadDetailBlockedNavigationResult {
  final String message;

  const ThreadDetailBlockedNavigationResult(this.message);
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
    String? onlyPuid,
  }) async {
    final router = maybeGoRouter;
    if (router == null) {
      return null;
    }

    final result = await router.push<Object?>(
      AppRoutes.threadDetailLocation(
        tid: tid.toString(),
        page: page,
        onlyEuid: onlyEuid,
        onlyPuid: onlyPuid,
      ),
    );

    if (result is ThreadDetailBlockedNavigationResult) {
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(this);
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(result.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return null;
    }

    if (result is T) {
      return result;
    }
    return null;
  }

  void replaceThreadDetail({
    required Object tid,
    int page = 1,
    String? onlyEuid,
    String? onlyPuid,
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
        onlyPuid: onlyPuid,
      ),
    );
  }

  Future<T?> pushThreadReplyComposer<T>({
    required Object tid,
    required Object pid,
    int page = 1,
    String? onlyEuid,
    String? onlyPuid,
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
        onlyPuid: onlyPuid,
      ),
      extra: ThreadReplyComposerRouteData(
        contextLabel: contextLabel,
        contextPreview: contextPreview,
      ).toExtra(),
    );
  }

  Future<T?> pushUserHome<T>({
    Object? euid,
    Object? puid,
    Object? userId,
  }) async {
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

    return router.push<T>(
      AppRoutes.userHomeLocation(euid: euid, puid: puid, userId: userId),
    );
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

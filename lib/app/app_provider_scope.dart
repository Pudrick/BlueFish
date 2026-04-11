import 'dart:async';

import 'package:bluefish/app/app_services.dart';
import 'package:bluefish/app/app_session.dart';
import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/auth/current_user_identity_controller.dart';
import 'package:bluefish/auth/current_user_identity_resolver.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/services/media/media_save_service.dart';
import 'package:bluefish/services/mention/mention_light_service.dart';
import 'package:bluefish/services/mention/mention_reply_service.dart';
import 'package:bluefish/services/private_message/private_message_detail_service.dart';
import 'package:bluefish/services/private_message/private_message_list_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_service.dart';
import 'package:bluefish/services/thread/thread_detail_service.dart';
import 'package:bluefish/services/thread/thread_list_service.dart';
import 'package:bluefish/services/thread/thread_reply_service.dart';
import 'package:bluefish/services/user_home/current_user_profile_service.dart';
import 'package:bluefish/services/user_home/user_home_service.dart';
import 'package:bluefish/services/vote/vote_service.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:bluefish/viewModels/current_user_profile_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class AppProviderScope extends StatelessWidget {
  final AppSession appSession;
  final AppServices appServices;
  final AppSettingsViewModel settingsViewModel;
  final Widget child;

  const AppProviderScope({
    super.key,
    required this.appSession,
    required this.appServices,
    required this.settingsViewModel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppSession>.value(value: appSession),
        ChangeNotifierProvider<AuthSessionManager>.value(
          value: appSession.authSessionManager,
        ),
        Provider<AppHttpClient>.value(value: appSession.httpClient),
        Provider<ReplyPageLocatorCacheService>.value(
          value: appServices.replyPageLocatorCacheService,
        ),
        Provider<ThreadDetailService>.value(
          value: appServices.threadDetailService,
        ),
        Provider<ReplyPageLocatorService>.value(
          value: appServices.replyPageLocatorService,
        ),
        Provider<ThreadListService>.value(value: appServices.threadListService),
        Provider<ThreadReplyService>.value(
          value: appServices.threadReplyService,
        ),
        Provider<UserHomeService>.value(value: appServices.userHomeService),
        Provider<CurrentUserProfileHttpService>.value(
          value: appServices.currentUserProfileHttpService,
        ),
        Provider<PrivateMessageListService>.value(
          value: appServices.privateMessageListService,
        ),
        Provider<PrivateMessageDetailService>.value(
          value: appServices.privateMessageDetailService,
        ),
        Provider<MentionReplyService>.value(
          value: appServices.mentionReplyService,
        ),
        Provider<MentionLightService>.value(
          value: appServices.mentionLightService,
        ),
        Provider<VoteService>.value(value: appServices.voteService),
        Provider<MediaSaveService>.value(value: appServices.mediaSaveService),
        ChangeNotifierProvider<AppSettingsViewModel>.value(
          value: settingsViewModel,
        ),
        ChangeNotifierProvider<CurrentUserProfileViewModel>(
          create: (context) {
            final viewModel = CurrentUserProfileViewModel(
              authSessionManager: context.read<AuthSessionManager>(),
              service: context.read<CurrentUserProfileHttpService>(),
            );
            unawaited(viewModel.initialize());
            return viewModel;
          },
        ),
        Provider<CurrentUserIdentityResolver>.value(
          value: const CurrentUserIdentityResolver(),
        ),
        ChangeNotifierProxyProvider3<
          AuthSessionManager,
          CurrentUserProfileViewModel,
          CurrentUserIdentityResolver,
          CurrentUserIdentityController
        >(
          create: (_) => CurrentUserIdentityController(),
          update:
              (
                _,
                authSessionManager,
                currentUserProfileViewModel,
                resolver,
                controller,
              ) {
                final resolvedController =
                    controller ?? CurrentUserIdentityController();
                resolvedController.update(
                  authSessionManager: authSessionManager,
                  currentUserProfileViewModel: currentUserProfileViewModel,
                  resolver: resolver,
                );
                return resolvedController;
              },
        ),
      ],
      child: child,
    );
  }
}

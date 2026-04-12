import 'package:bluefish/data/local/app_database.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/services/media/media_save_service.dart';
import 'package:bluefish/services/mention/mention_light_service.dart';
import 'package:bluefish/services/mention/mention_reply_service.dart';
import 'package:bluefish/services/private_message/private_message_detail_service.dart';
import 'package:bluefish/services/private_message/private_message_list_service.dart';
import 'package:bluefish/services/thread/reply_light_action_service.dart';
import 'package:bluefish/services/thread/reply_light_record_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_cache_service.dart';
import 'package:bluefish/services/thread/reply_page_locator_service.dart';
import 'package:bluefish/services/thread/thread_detail_service.dart';
import 'package:bluefish/services/thread/thread_gift_service.dart';
import 'package:bluefish/services/thread/thread_list_service.dart';
import 'package:bluefish/services/thread/thread_reply_service.dart';
import 'package:bluefish/services/user_home/current_user_profile_service.dart';
import 'package:bluefish/services/user_home/user_home_service.dart';
import 'package:bluefish/services/vote/vote_service.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';

class AppServices {
  final AppDatabase appDatabase;
  final ReplyLightActionService replyLightActionService;
  final ReplyLightRecordService replyLightRecordService;
  final ReplyPageLocatorCacheService replyPageLocatorCacheService;
  final ThreadDetailService threadDetailService;
  final ThreadGiftService threadGiftService;
  final ReplyPageLocatorService replyPageLocatorService;
  final ThreadListService threadListService;
  final ThreadReplyService threadReplyService;
  final UserHomeService userHomeService;
  final CurrentUserProfileHttpService currentUserProfileHttpService;
  final PrivateMessageListService privateMessageListService;
  final PrivateMessageDetailService privateMessageDetailService;
  final MentionReplyService mentionReplyService;
  final MentionLightService mentionLightService;
  final VoteService voteService;
  final MediaSaveService mediaSaveService;

  const AppServices._({
    required this.appDatabase,
    required this.replyLightActionService,
    required this.replyLightRecordService,
    required this.replyPageLocatorCacheService,
    required this.threadDetailService,
    required this.threadGiftService,
    required this.replyPageLocatorService,
    required this.threadListService,
    required this.threadReplyService,
    required this.userHomeService,
    required this.currentUserProfileHttpService,
    required this.privateMessageListService,
    required this.privateMessageDetailService,
    required this.mentionReplyService,
    required this.mentionLightService,
    required this.voteService,
    required this.mediaSaveService,
  });

  static Future<AppServices> bootstrap({
    required AppHttpClient httpClient,
    required AppSettingsViewModel settingsViewModel,
    ReplyPageLocatorCacheService? replyPageLocatorCacheService,
  }) async {
    final cacheService =
        replyPageLocatorCacheService ?? ReplyPageLocatorCacheService();
    if (!cacheService.isInitialized) {
      await cacheService.ensureInitialized();
    }

    final appDatabase = AppDatabase();
    final threadDetailService = ThreadDetailService(client: httpClient);

    return AppServices._(
      appDatabase: appDatabase,
      replyLightActionService: ReplyLightActionService(client: httpClient),
      replyLightRecordService: ReplyLightRecordService(
        dao: appDatabase.replyLightRecordDao,
      ),
      replyPageLocatorCacheService: cacheService,
      threadDetailService: threadDetailService,
      threadGiftService: ThreadGiftService(client: httpClient),
      replyPageLocatorService: ReplyPageLocatorService(
        client: httpClient,
        threadDetailService: threadDetailService,
        cacheService: cacheService,
        shouldWriteJumpLogs: () => settingsViewModel.settings.generateJumpLogs,
      ),
      threadListService: ThreadListService(client: httpClient),
      threadReplyService: ThreadReplyService(client: httpClient),
      userHomeService: UserHomeService(client: httpClient),
      currentUserProfileHttpService: CurrentUserProfileHttpService(
        client: httpClient,
      ),
      privateMessageListService: PrivateMessageListService(client: httpClient),
      privateMessageDetailService: PrivateMessageDetailService(
        client: httpClient,
      ),
      mentionReplyService: MentionReplyService(client: httpClient),
      mentionLightService: MentionLightService(client: httpClient),
      voteService: VoteService(client: httpClient),
      mediaSaveService: MediaSaveService(client: httpClient),
    );
  }
}

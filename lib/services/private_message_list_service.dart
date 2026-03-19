import 'package:bluefish/models/private_message_list.dart';
import 'package:bluefish/services/private_message_service_helper.dart';
import 'package:bluefish/utils/http_with_ua_coke.dart';

class PrivateMessageListService {
  static final Uri _baseUrl = Uri.parse(
    'https://my.hupu.com/pcmapi/pc/space/v1/pm/getPmList',
  );

  final HttpwithUA _client;

  PrivateMessageListService({HttpwithUA? client})
    : _client = client ?? HttpwithUA();

  Future<PrivateMessageList> getList({
    bool unreadOnly = false,
    required int pageNum,
    required int pageSize,
  }) async {
    final data = await postPrivateMessageData(
      client: _client,
      url: _baseUrl,
      body: {
        'unreadList': unreadOnly ? 1 : 0,
        'page': {'pageNum': pageNum, 'pageSize': pageSize},
      },
      requestErrorMessage: 'Failed to fetch private message list',
      payloadErrorMessage: 'Invalid private message list payload',
    );

    return PrivateMessageList.fromJson(data);
  }
}

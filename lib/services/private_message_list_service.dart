import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/models/private_message_list.dart';
import 'package:bluefish/services/private_message_service_helper.dart';
import 'package:http/http.dart' as http;

class PrivateMessageListService {
  static final Uri _baseUrl = Uri.parse(
    'https://my.hupu.com/pcmapi/pc/space/v1/pm/getPmList',
  );

  final http.Client _client;

  PrivateMessageListService({http.Client? client})
    : _client = client ?? httpClient;

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

import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/models/private_message/private_message_detail.dart';
import 'package:bluefish/services/private_message_service_helper.dart';
import 'package:http/http.dart' as http;

class PrivateMessageDetailService {
  static final Uri _baseUrl = Uri.parse(
    'https://my.hupu.com/pcmapi/pc/space/v1/pm/getPmDetail',
  );

  final http.Client _client;

  PrivateMessageDetailService({http.Client? client})
    : _client = client ?? httpClient;

  Future<PrivateMessageDetail> getDetail({
    required int puid,
    required int pageNum,
    required int pageSize,
  }) async {
    final data = await postPrivateMessageData(
      client: _client,
      url: _baseUrl,
      body: {
        'fromPuid': puid,
        'page': {'pageNum': pageNum, 'pageSize': pageSize},
      },
      requestErrorMessage: 'Failed to fetch private message detail',
      payloadErrorMessage: 'Invalid private message detail payload',
    );

    return PrivateMessageDetail.fromJson(data);
  }
}

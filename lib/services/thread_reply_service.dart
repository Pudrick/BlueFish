import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/thread_reply_page.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:http/http.dart' as http;

class ThreadReplyService {
  final http.Client _client;

  ThreadReplyService({http.Client? client}) : _client = client ?? httpClient;

  Future<ThreadReplyPage> getReplyPage({
    required String tid,
    required String pid,
    int page = 1,
  }) async {
    final uri = Uri.parse('https://bbs.hupu.com/api/v2/reply/reply').replace(
      queryParameters: {
        'tid': tid,
        'pid': pid,
        if (page > 1) 'page': page.toString(),
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw const HttpException('加载回复列表失败。');
    }

    final json = parseMap(jsonDecode(response.body));
    final code = parseInt(json['code']);
    if (code != 200) {
      final message = parseString(json['message'], fallback: '加载回复列表失败。');
      throw HttpException(message);
    }

    return ThreadReplyPage.fromJson(json);
  }
}

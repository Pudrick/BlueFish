import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/single_thread_title.dart';
import 'package:bluefish/userdata/user_settings.dart';
import 'package:bluefish/utils/http_with_ua_coke.dart';

class ThreadListService {
  final HttpwithUA _client;

  ThreadListService({HttpwithUA? client}) : _client = client ?? HttpwithUA();

  Uri topicThreadsBaseUrl() {
    return Uri.parse(
      'https://bbs.mobileapi.hupu.com/1/$appVersionNumber/topics/getTopicThreads?',
    );
  }

  Uri pinnedThreadsUrl({required int topicID}) {
    return Uri.parse(
      'https://bbs.mobileapi.hupu.com/1/$appVersionNumber/topics/$topicID',
    );
  }

  Uri threadListUrl({
    required int topicID,
    required int tabType,
    int? zoneID,
  }) {
    final query = <String, String>{
      'topic_id': topicID.toString(),
      'tab_type': tabType.toString(),
    };
    if (zoneID != null) {
      query['zoneId'] = zoneID.toString();
    }

    return Uri.parse(
      'https://bbs.mobileapi.hupu.com/1/$appVersionNumber/topics/getTopicThreads',
    ).replace(queryParameters: query);
  }

  Future<List<SingleThreadTitle>> getPinnedThreads({required int topicID}) async {
    final response = await _client.get(pinnedThreadsUrl(topicID: topicID));
    if (response.statusCode != 200) {
      throw const HttpException('failed to load pinned threads.');
    }

    final mappedThreads = jsonDecode(response.body) as Map<String, dynamic>;
    final pinnedList = mappedThreads['data']?['topicTopList'] as List? ?? const [];

    return [
      for (final thread in pinnedList)
        SingleThreadTitle.fromJson({
          ...Map<String, dynamic>.from(thread as Map),
          'isPinned': true,
        }),
    ];
  }

  Future<List<SingleThreadTitle>> getNormalThreads({required Uri url}) async {
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw const HttpException('failed to load thread list.');
    }

    final mappedThreads = jsonDecode(response.body) as Map<String, dynamic>;
    final threadList = mappedThreads['data']?['list'] as List? ?? const [];

    return [
      for (final thread in threadList)
        SingleThreadTitle.fromJson(
          Map<String, dynamic>.from(thread as Map),
        ),
    ];
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/internal_settings.dart';
import 'package:bluefish/network/http_client.dart';
import 'package:bluefish/models/user_homepage/user_home.dart';
import 'package:bluefish/models/user_homepage/user_home_reply.dart';
import 'package:bluefish/models/user_homepage/user_home_thread_title.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

class UserHomeService {
  final http.Client _client;

  UserHomeService({http.Client? client}) : _client = client ?? httpClient;

  String getAuthorDataFromScripts(List<Element> scripts) {
    for (final script in scripts) {
      final text = script.text.trim();
      if (!text.startsWith('window.\$\$data')) continue;
      final eqIndex = text.indexOf('=');
      if (eqIndex == -1) continue;

      var value = text.substring(eqIndex + 1).trim();

      // remove ';' in the tail.
      if (value.endsWith(';')) {
        value = value.substring(0, value.length - 1);
      }

      return value;
    }
    throw const FormatException('window.\$\$data not found in <script>');
  }

  Future<UserHome> getAuthorHomeByEuid(dynamic euid) async {
    if (euid is int) euid = euid.toString();
    Uri homepageUrl = Uri.parse("https://my.hupu.com/$euid");
    var response = await _client.get(homepageUrl);
    if (response.statusCode != 200) {
      throw const HttpException("Failed to get http response.");
    }

    final threadHTML = parse(response.body);
    final scripts = threadHTML.getElementsByTagName('script');
    final authorInfoStr = getAuthorDataFromScripts(scripts);

    // now the threads in authorHome is empty, need implement later.
    final rawJson = jsonDecode(authorInfoStr);
    final userData = rawJson['cardInfoData'] as Map<String, dynamic>;

    final bool isLogin = rawJson['isLogin'] as bool;
    final String euidInJson = rawJson['euid'] as String;

    // make the json can be read directly.
    userData['isLogin'] = isLogin;
    userData['euid'] = euidInJson;

    userData['nextPage'] = rawJson['nextPage'] as bool;
    userData['env'] = rawJson['env'] as String;
    userData['tabKey'] = rawJson['tabKey'] as String;

    userData['euid'] = rawJson['euid'] as String;
    final authorHome = UserHome.fromJson(userData);
    return authorHome;
  }

  Future<({List<UserHomeThreadTitle> threads, int rawCount})> loadThreadsPage({
    required String authorEuid,
    required ThreadListType type,
    required int page,
  }) async {
    final baseUrl = Uri.parse(
      "https://bbs.hupu.com/pcmapi/pc/space/v1/${type.apiType}",
    );
    final threadAPI = baseUrl.replace(
      queryParameters: {
        'euid': authorEuid,
        'page': page.toString(),
        'pageSize': UserHome.threadPageSize.toString(),
      },
    );

    final response = await _client.get(threadAPI);
    if (response.statusCode != 200) {
      throw const HttpException('failed to load threads.');
    }

    // strong type constraints, emit problems as early as possible.
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> threadsData = switch (type) {
      ThreadListType.post => (json['data'] as List<dynamic>? ?? []),
      ThreadListType.recommend =>
        (json['data']['content'] as List<dynamic>? ?? []),
    };
    final parsedThreads = threadsData
        .map(
          (e) =>
              UserHomeThreadTitle.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    return (
      threads: parsedThreads
          .where((thread) => thread.topicId == mainTopicID)
          .toList(),
      rawCount: threadsData.length,
    );
  }

  Future<({List<UserHomeReply> replies, String lastMaxTime, int rawCount})>
  loadRepliesPage({
    required String authorEuid,
    required int page,
    required String lastMaxTime,
  }) async {
    final baseUrl = Uri.parse(
      "https://my.hupu.com/pcmapi/pc/space/v1/getReplyList",
    );
    final threadAPI = baseUrl.replace(
      queryParameters: {
        'euid': authorEuid,
        'maxTime': lastMaxTime,
        'page': page.toString(),
        'pageSize': UserHome.replyPageSize.toString(),
      },
    );

    final response = await _client.get(threadAPI);
    if (response.statusCode != 200) {
      throw const HttpException('failed to load replies.');
    }

    // strong type constraints, emit problems as early as possible.
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> repliesData =
        json['data']['replyWithQuoteDtoList'] as List<dynamic>? ?? [];
    final String maxTime = json['data']['maxTime'].toString();
    final parsedReplies = repliesData
        .map((e) => UserHomeReply.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return (
      replies: parsedReplies
          .where((reply) => reply.topicId == mainTopicID)
          .toList(),
      lastMaxTime: maxTime,
      rawCount: repliesData.length,
    );
  }
}

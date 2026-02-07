import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/user_homepage/user_home.dart';
import 'package:bluefish/models/user_homepage/user_home_reply.dart';
import 'package:bluefish/models/user_homepage/user_home_thread_title.dart';
import 'package:html/dom.dart';

// TODO: change it to w/o coke.
import 'package:bluefish/utils/http_with_ua_coke.dart';
import 'package:html/parser.dart';

class UserHomeService {
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
    var response = await HttpwithUA().get(homepageUrl);
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

  // TODO: add a tid filter of bengban.
  Future<List<UserHomeThreadTitle>> loadThreadsPage({
    required String authorEuid,
    required ThreadListType type,
    required int page,
  }) async {
    final Uri threadAPI = Uri.parse(
      "https://bbs.hupu.com/pcmapi/pc/space/v1/${type.apiType}?euid=$authorEuid&page=$page&pageSize=${UserHome.threadPageSize}",
    );

    final response = await HttpwithUA().get(threadAPI);
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
    return threadsData
        .map((e) => UserHomeThreadTitle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserHomeReply>> loadRepliesPage({
    required String authorEuid,
    required int page,
  }) async {
    final Uri threadAPI = Uri.parse(
      "https://my.hupu.com/pcmapi/pc/space/v1/getReplyList?euid=$authorEuid&maxTime=0&page=$page&pageSize=${UserHome.replyPageSize}",
    );

    final response = await HttpwithUA().get(threadAPI);
    if (response.statusCode != 200) {
      throw const HttpException('failed to load replies.');
    }

    // strong type constraints, emit problems as early as possible.
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> repliesData =
        json['data']['replyWithQuoteDtoList'] as List<dynamic>? ?? [];
    return repliesData
        .map((e) => UserHomeReply.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

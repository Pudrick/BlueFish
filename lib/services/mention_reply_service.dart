import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/mention_reply.dart';
import 'package:bluefish/utils/http_with_ua_coke.dart';

class MentionReplyService {
  Future<
    ({
      List<MentionReply> newReplyList,
      List<MentionReply> oldReplyList,
      String pageStr,
      bool hasNextPage,
    })
  >
  getReplyList({String? currentPageStr}) async {
    final baseUrl = Uri.parse(
      "https://bbs.hupu.com/pcmapi/pc/space/v1/getMentionedRemindList",
    );
    final latestUrl = baseUrl.replace(
      queryParameters: {if (currentPageStr != null) 'pageStr': currentPageStr},
    );
    var response = await HttpwithUA().get(latestUrl);
    if (response.statusCode != 200) {
      throw const HttpException("Failed to get http response.");
    }
    final rawJson = jsonDecode(response.body);

    List<MentionReply> parseList(dynamic list) {
      return (list as List?)
              ?.map((json) => MentionReply.fromJson(json))
              .toList() ??
          [];
    }

    final String pageStr = rawJson['data']['pageStr'];
    final bool hasNextPage = rawJson['data']['hasNextPage'];
    return (
      newReplyList: parseList(rawJson['data']['newList']),
      oldReplyList: parseList(rawJson['data']['hisList']),
      pageStr: pageStr,
      hasNextPage: hasNextPage,
    );
  }
}

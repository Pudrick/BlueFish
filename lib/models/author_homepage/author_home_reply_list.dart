import 'dart:convert';
import 'dart:io';

import 'package:bluefish/models/author_homepage/author_home_reply.dart';
import 'package:bluefish/utils/http_with_ua_coke.dart' show HttpwithUA;

class AuthorHomeReplyList {
  final List<AuthorHomeReply> replyList = [];

  final String authorEuid;
  bool isLastPage = false;
  int currentReplyListPage = 1;
  bool isLoadingReplies = false;
  static const int replyPageSize = 20;

  AuthorHomeReplyList({required this.authorEuid});

  Future<void> loadNextPageReplies() async {
  if (isLastPage || isLoadingReplies) return;
  isLoadingReplies = true;

  try {
    final Uri threadAPI = Uri.parse(
    "https://my.hupu.com/pcmapi/pc/space/v1/getReplyList?euid=$authorEuid&maxTime=0&page=$currentReplyListPage&pageSize=${AuthorHomeReplyList.replyPageSize}"
    );

    final response = await HttpwithUA().get(threadAPI);
    if (response.statusCode != 200) {
      throw const HttpException('failed to load replies.');
    }

    // strong type constraints, emit problems as early as possible.
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> repliesData = json['data']['replyWithQuoteDtoList'] as List<dynamic>? ?? [];
    final newRepliesList = repliesData
        .map((e) => AuthorHomeReply.fromJson(e as Map<String, dynamic>))
        .toList();
    replyList.addAll(newRepliesList);

    isLastPage = !(json["data"]["nextPage"]);
    if(!isLastPage) {
      currentReplyListPage++;
    }
  } finally {
    isLoadingReplies = false;
  }
}
}
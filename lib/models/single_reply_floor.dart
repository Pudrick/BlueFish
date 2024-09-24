import 'dart:convert';

import 'package:bluefish/models/author.dart';

class Quote {
  late String pid;
  late String authorId;
  late String content;
  String? quoteVideo;
  String? quoteVideoCover;
  late bool isAudit; // what's this?

  late Author quoteAuthor;

  Quote.fromMap(Map quoteMap) {
    pid = quoteMap["pid"];
    authorId = quoteMap["authorId"];
    content = quoteMap["content"];
    quoteVideo = quoteMap["video"];
    quoteVideoCover = quoteMap["videoCover"];
    isAudit = quoteMap["isAudit"];
    quoteAuthor = Author.createQuoteAuthor(quoteMap["author"]);
  }

  Quote(); // just for the reply floor constructor
}

class SingleReplyFloor extends Quote {
  late int lightCount;
  late String client;

  // not sure whether exist, just null it anyway
  String? replyVideo;
  String? replyVideoCover;

  late bool isOP; // json 'isStarter' means OP.

  late bool isDelete;
  late bool idSelfDelete;
  late bool isHidden;

  late DateTime postTime;
  late String postTimeReadable; // can be infer from postTime
  late Author replyAuthor;

  Quote? quote;

  late int replyNum;

  // null in lights list
  late int? userBanned; // what's this?

  late int hidePost;
  String? postLocation;

  SingleReplyFloor.fromReplyMap(Map jsonReplyMap) {
    pid = jsonReplyMap["pid"];
    authorId = jsonReplyMap["authorId"];
    content = jsonReplyMap["content"];
    lightCount = jsonReplyMap["count"];
    client = jsonReplyMap["client"];
    isAudit = jsonReplyMap["isAudit"];
    isHidden = jsonReplyMap["isHidden"];
    isDelete = jsonReplyMap["isDelete"];
    isOP = jsonReplyMap["isStarter"];
    postTime = DateTime.fromMillisecondsSinceEpoch(jsonReplyMap["createdAt"]);
    postTimeReadable = jsonReplyMap["createdAtFormat"];
    replyAuthor = Author.createReplyAuthor(jsonReplyMap["author"]);
    if (jsonReplyMap["quote"].containsKey("pid")) {
      quote = Quote.fromMap(jsonReplyMap["quote"]);
    } else {
      quote = null;
    }
    replyNum = jsonReplyMap["replyNum"];
    if (jsonReplyMap.containsKey("userBanned")) {
      userBanned = jsonReplyMap["userBanned"];
    }
    if (jsonReplyMap.containsKey("hidePost")) {
      hidePost = jsonReplyMap["hidePost"];
    }
    postLocation = jsonReplyMap["location"];
  }

  /// need to send fid pid puid tid to server.
  /// PC API target address : https://bbs.hupu.com/pcmapi/pc/bbs/v1/reply/light
  /// due to lack of cookie, will be instanced later.
  void likeFloor() {
    //TODO:
  }

  void commentTo(String replyContent) {}

  void getComments() {}

  void dislike() {}

  void onlyAuthor() {}

  void reportReply() {}
}

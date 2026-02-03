import 'dart:convert';

import 'package:bluefish/models/author.dart';
import 'package:bluefish/models/abstract_floor_content.dart';

class SingleReplyFloor extends FloorContent {
  late String pid;
  late String authorId;

  late int lightCount;
  // late String client;

  String? replyVideo;
  String? replyVideoCover;

  late bool isOP; // json 'isStarter' means OP.

  late bool isDelete;
  late bool isSelfDelete;
  late bool isHidden;
  late bool isAudit;

  // TODO: make use of this arg.
  // only appear in Quote part.
  late bool? isBlacked;
  late bool? isAdmin;

  // late DateTime postTime;
  // late String postTimeReadable; // can be infer from postTime
  // late Author replyAuthor;

  // Quote? quote;
  SingleReplyFloor? quote;
  bool hasQuote = false;

  late int replyNum;

  // null in lights list
  late int? userBanned; // what's this?

  late int? hidePost;
  // String? postLocation;

  SingleReplyFloor.fromReplyMap(Map jsonReplyMap) {
    pid = jsonReplyMap["pid"];
    authorId = jsonReplyMap["authorId"];
    contentHTML = jsonReplyMap["content"];
    lightCount = jsonReplyMap["count"];
    client = jsonReplyMap["client"];
    isAudit = jsonReplyMap["isAudit"];
    isHidden = jsonReplyMap["isHidden"];
    isDelete = jsonReplyMap["isDelete"];
    isSelfDelete = jsonReplyMap["isSelfDelete"];
    isOP = jsonReplyMap["isStarter"];
    postTime = DateTime.fromMillisecondsSinceEpoch(jsonReplyMap["createdAt"]);
    postTimeReadable = jsonReplyMap["createdAtFormat"];
    author = Author.forReply(jsonReplyMap["author"]);
    if (jsonReplyMap.containsKey("quote") &&
        jsonReplyMap["quote"].containsKey("pid")) {
      quote = SingleReplyFloor.fromReplyMap(jsonReplyMap["quote"]);
      hasQuote = true;
    } else {
      quote = null;
    }
    replyNum = jsonReplyMap["replyNum"];

    // these field may be null: jsonReplyMap may not contains these keys.
      userBanned = jsonReplyMap["userBanned"];
      hidePost = jsonReplyMap["hidePost"];
      replyVideo = jsonReplyMap["video"];
      replyVideoCover = jsonReplyMap["videoCover"];
      isBlacked = jsonReplyMap["isBlacked"];
      isAdmin = jsonReplyMap["isAdmin"];

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

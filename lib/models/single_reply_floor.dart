import 'package:bluefish/models/author.dart';
import 'package:bluefish/models/abstract_floor_content.dart';

import "quote.dart";

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

  // late DateTime postTime;
  // late String postTimeReadable; // can be infer from postTime
  // late Author replyAuthor;

  Quote? quote;

  late int replyNum;

  // null in lights list
  late int? userBanned; // what's this?

  late int hidePost;
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
    author = Author.createReplyAuthor(jsonReplyMap["author"]);
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
    if (jsonReplyMap.containsKey("video")) {
      replyVideo = jsonReplyMap["video"];
    }
    if (jsonReplyMap.containsKey("videoCover")) {
      replyVideoCover = jsonReplyMap["videoCover"];
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

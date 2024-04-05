import 'content.dart';

class ReplyAuthor {
  late Uri avatarURL;
  late String authorName;
  String? adminInfo;
  late bool isOP;
  late String puid;
}

class SingleReply {
  late ReplyAuthor author;

  List<Content> content = List.empty(growable: true);

  late String pid;

  late String tid;
  late String fid;

  /// need to send fid pid puid tid to server.
  /// PC API target address : https://bbs.hupu.com/pcmapi/pc/bbs/v1/reply/light
  /// due to lack of cookie, will be instanced later.
  void like() {
    //TODO:
  }

  void commentTo(String replyContent) {}

  void getComments() {}

  void dislike() {}

  void onlyAuthor() {}

  void reportReply() {}
}

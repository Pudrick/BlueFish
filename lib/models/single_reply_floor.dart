class SingleReplyFloor {
  late String floorContent;
  late bool isOP;
  late int lightCount;
  late int pid;
  late bool isAudit; // what's this?
  late bool isHidden;
  late bool isDelete;
  late bool idSelfDelete;
  late bool isStarter; // and what is this?

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

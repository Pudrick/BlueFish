class Author {
  late Uri avatarURL;
  late String authorName;
  late bool isOP;
  // late String puid;
  late Uri profileURL;
}

class SingleFloor {
  late Author author;
  late String postDateTime;
  late String postLocation;

  late String contentHTML;
}

class SingleReplyFloor extends SingleFloor {
  late bool isOP;

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

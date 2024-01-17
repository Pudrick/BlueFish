abstract class ReplyContent {}

class TextReply implements ReplyContent {
  late String content;
}

class ImageReply implements ReplyContent {
  late Uri imageURL;

  ImageReply(String URL) {
    imageURL = Uri.parse(URL);
  }
}

class SingleReply {
  List<ReplyContent> content = List.empty(growable: true);

  void like() {}

  void commentTo(String replyContent) {}

  void getComments() {}

  void dislike() {}

  void onlyAuthor() {}

  void reportReply() {}
}

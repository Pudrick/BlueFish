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

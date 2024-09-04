import 'package:html/dom.dart';

import 'single_floor.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import '../utils/thread_html_parser.dart';

// Why the name is so awkward……
String threadMainClassName = ".post-content_bbs-post-content__cy7vN";

class ThreadDetail {
  late String tid;

  late SingleFloor mainFloor;

  List<SingleReplyFloor> replyHtmlList = List.empty(growable: true);
  List<SingleReplyFloor> lightedReplyHtmlList = List.empty(growable: true);

  ThreadDetail._privateConstructor(
      this.mainFloor, this.replyHtmlList, this.lightedReplyHtmlList);

  Future<ThreadDetail> fromTid(String tid) async {
    var threadHTML = await getHTMLFromTid(tid);
    mainFloor = getMainFloor(threadHTML);
  }

  void likeThread() {}

  void commentToThread() {}

  void collectThread() {}

  void shareThread() {}

  void reportThread() {}

  void onlyAuthor() {}
}

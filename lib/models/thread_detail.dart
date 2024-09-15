import 'package:bluefish/models/thread_main.dart';

import 'single_reply_floor.dart';
import '../utils/thread_parser.dart';

class ThreadDetail {
  late String tid;

  late ThreadMain mainFloor;

  List<SingleReplyFloor> replyHtmlList = List.empty(growable: true);
  List<SingleReplyFloor> lightedReplyHtmlList = List.empty(growable: true);

  ThreadDetail._privateConstructor(
      this.mainFloor, this.replyHtmlList, this.lightedReplyHtmlList);

  Future<ThreadDetail> fromTid(String tid) async {
    // TODO: change to get json from TID
    var threadInfo = await getThreadInfoMapFromTid(tid);
    mainFloor = getMainFloor(threadInfo);
  }

  void likeThread() {}

  void commentToThread() {}

  void collectThread() {}

  void shareThread() {}

  void reportThread() {}

  void onlyAuthor() {}
}

import 'package:bluefish/models/thread_main.dart';

import 'single_reply_floor.dart';
import '../utils/thread_parser.dart';

class ThreadDetail {
  late String tid;

  late bool hasLiked;

  late ThreadMain mainFloor;
  late List<SingleReplyFloor> lightedReplies;
  late List<SingleReplyFloor> replies;

  int currentPage = 0;
  int totalRepliesNum = 0;
  int repliesPerPage = 20;
  late int totalPagesNum;

  ThreadDetail(dynamic userTid, int page) {
    currentPage = page;
    if (userTid is int) {
      tid = userTid.toString();
    } else {
      tid = userTid;
    }
  }

  Future<void> refresh() async {
    // TODO: change to get json from TID
    var threadInfo = await getThreadInfoMapFromTid(tid, currentPage);
    mainFloor = ThreadMain(threadInfo["thread"]);
    totalRepliesNum = threadInfo["replies"]["count"];
    totalPagesNum = (totalRepliesNum / repliesPerPage).ceil();
    lightedReplies = getReplyListFromWholeMap("lights", threadInfo);
    replies = getReplyListFromWholeMap("replies", threadInfo);
  }

  void likeThread() {}

  void commentToThread() {}

  void collectThread() {}

  void shareThread() {}

  void reportThread() {}

  void onlyAuthor() {}
}

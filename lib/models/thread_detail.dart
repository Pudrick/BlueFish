import 'package:bluefish/models/thread_main.dart';
import 'package:bluefish/models/vote.dart';
import 'package:html/parser.dart';

import 'package:bluefish/models/single_reply_floor.dart';
import 'package:bluefish/utils/get_thread_info.dart';

class ThreadDetail {
  late String tid;

  late bool hasLiked;

  late ThreadMain mainFloor;
  late List<SingleReplyFloor> lightedReplies;
  late List<SingleReplyFloor> replies;
  bool mainFloorInited = false;

  int currentPage = 1;
  int totalRepliesNum = 0;
  final repliesPerPage = 20;
  late int totalPagesNum;

  ThreadDetail(dynamic tid, {int page = 1}) {
    currentPage = page;
    // mainFloor.hasVote = hasVote;
    if (tid is int) {
      this.tid = tid.toString();
    } else {
      this.tid = tid;
    }
  }

  Future<void> refresh() async {
    // TODO: change to get json from TID
    var threadInfo = await getThreadInfoMapFromTid(tid, currentPage);
    if (mainFloorInited == false) {
      mainFloor = ThreadMain(threadInfo["thread"]);
      mainFloorInited = true;
    }

    totalRepliesNum = threadInfo["replies"]["count"];
    totalPagesNum = (totalRepliesNum / repliesPerPage).ceil();
    lightedReplies = getReplyListFromWholeMap("lights", threadInfo);
    replies = getReplyListFromWholeMap("replies", threadInfo);
  }

  //TODO: Handle reply floor video

  void likeThread() {}

  void editThread() {}

  void deleteThread() {}

  void commentToThread() {}

  void collectThread() {}

  void shareThread() {}

  void reportThread() {}

  void onlyAuthor() {}
}

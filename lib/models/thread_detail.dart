import 'package:bluefish/models/thread_main.dart';
import 'package:bluefish/models/vote.dart';
import 'package:html/parser.dart';

import './single_reply_floor.dart';
import '../utils/get_thread_info.dart';

class ThreadDetail {
  late String tid;

  late bool hasLiked;

  late ThreadMain mainFloor;
  late List<SingleReplyFloor> lightedReplies;
  late List<SingleReplyFloor> replies;

  int currentPage = 1;
  int totalRepliesNum = 0;
  final repliesPerPage = 20;
  late int totalPagesNum;

  ThreadDetail(dynamic tid, {int page = 1, bool hasVote = false}) {
    currentPage = page;
    mainFloor.hasVote = hasVote;
    if (tid is int) {
      this.tid = tid.toString();
    } else {
      this.tid = tid;
    }
  }

  Future<void> refresh() async {
    // TODO: change to get json from TID
    var threadInfo = await getThreadInfoMapFromTid(tid, currentPage);
    mainFloor = ThreadMain(threadInfo["thread"]);

    if (mainFloor.hasVote) {
      //TODO: if there's vote, init vote
      var htmldoc = parse(mainFloor.contentHTML);
      var voteElement = htmldoc.querySelector('[data-type="vote"]');
      if (voteElement != null) {
        var vote = Vote();
        vote.voteID = voteElement.attributes["data-vote-id"];
        await vote.refresh();
        mainFloor.vote = vote;
      }
    }

    totalRepliesNum = threadInfo["replies"]["count"];
    totalPagesNum = (totalRepliesNum / repliesPerPage).ceil();
    lightedReplies = getReplyListFromWholeMap("lights", threadInfo);
    replies = getReplyListFromWholeMap("replies", threadInfo);
  }

  //TODO: Handle reply floor video

  void likeThread() {}

  void commentToThread() {}

  void collectThread() {}

  void shareThread() {}

  void reportThread() {}

  void onlyAuthor() {}
}

import 'package:bluefish/models/thread_main.dart';
import 'package:bluefish/models/single_reply_floor.dart';

/// Data container for thread detail page.
class ThreadDetail {
  final String tid;
  final int currentPage;
  final int totalRepliesNum;
  final int repliesPerPage;
  final ThreadMain mainFloor;
  final List<SingleReplyFloor> lightedReplies;
  final List<SingleReplyFloor> replies;

  ThreadDetail({
    required this.tid,
    required this.currentPage,
    required this.totalRepliesNum,
    required this.repliesPerPage,
    required this.mainFloor,
    required this.lightedReplies,
    required this.replies,
  });

  int get totalPagesNum {
    final pages = (totalRepliesNum / repliesPerPage).ceil();
    return pages < 1 ? 1 : pages;
  }
}

import 'single_floor.dart';

class ThreadDetail {
  late String tid;

  late SingleFloor mainFloor;

  List<SingleReplyFloor> replyHtmlList = List.empty(growable: true);
  List<SingleReplyFloor> lightedReplyHtmlList = List.empty(growable: true);

  ThreadDetail._privateConstructor(
      this.mainFloor, this.replyHtmlList, this.lightedReplyHtmlList);

  Future<ThreadDetail> fromTid(String tid) async {
    // TODO: change to get tuple from TID
    // var threadHTML = await getHTMLFromTid(tid);
    // mainFloor = getMainFloor(threadHTML);
  }

  void likeThread() {}

  void commentToThread() {}

  void collectThread() {}

  void shareThread() {}

  void reportThread() {}

  void onlyAuthor() {}
}

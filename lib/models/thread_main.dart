import 'package:bluefish/models/author.dart';
import 'package:bluefish/models/abstract_floor_content.dart';
import 'package:bluefish/models/vote.dart';
import 'package:html/parser.dart';

class ThreadMain extends FloorContent {
  late String tid;
  late String title;
  Vote? vote;

  // TODO: make sure the type of these in video thread
  late String videoCover;
  String? video;

  late String urlSuffix;
  late int lightsNum;
  late int repliesNum;
  late int recommendNum;
  late int readNum;
  // late String client;
  late bool hasVideo;
  late bool hasVote;
  late bool isRecommended;

  late DateTime lastReplyTime;

  // what's this? maybe locked/deleted/normal?
  late int status;

  // maybe text/video/vote or something like that?
  late int contentType;

  late int isLock;
  late String rawContent;
  // late String postLocation;

  // TODO: add vote detect and initilization
  ThreadMain(Map threadJsonMap) {
    tid = threadJsonMap["tid"];
    title = threadJsonMap["title"];
    contentHTML = threadJsonMap["content"];
    videoCover = threadJsonMap["videoCover"];
    video = threadJsonMap["video"];
    urlSuffix = threadJsonMap["url"];
    lightsNum = threadJsonMap["lights"];
    repliesNum = threadJsonMap["replies"];
    recommendNum = threadJsonMap["recommend"];
    isRecommended = threadJsonMap["isRecommended"];
    readNum = threadJsonMap["read"];
    client = threadJsonMap["client"];
    postTime = DateTime.fromMillisecondsSinceEpoch(threadJsonMap["createdAt"]);
    postTimeReadable = threadJsonMap["createdAtFormat"];
    lastReplyTime =
        DateTime.fromMillisecondsSinceEpoch(threadJsonMap["repliedAt"]);
    hasVideo = threadJsonMap["hasVideo"];
    author = Author.forThread(threadJsonMap["author"]);
    status = threadJsonMap["status"];
    isLock = threadJsonMap["isLock"];
    contentType = threadJsonMap["contentType"];
    rawContent = threadJsonMap["format"];
    postLocation = threadJsonMap["location"];
    _checkVoteExist();
  }

  void _checkVoteExist() {
    var htmldoc = parse(contentHTML);
    var voteElement = htmldoc.querySelector('[data-type="vote"]');
    if (voteElement != null) {
      hasVote = true;
    } else {
      hasVote = false;
    }
  }

  // TODO: check Video exist
  // void _checkVideoExist() {
  //   var htmldoc = parse(contentHTML);
  //   var voteElement = htmldoc.querySelector('[data-type="vote"]');
  //   if (voteElement != null) {
  //     hasVote = true;
  //   } else {
  //     hasVote = false;
  //   }
  // }

  //TODO: parse vote link, detected vote is done by main.
}

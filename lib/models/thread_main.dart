import 'author.dart';

class ThreadMain {
  late int tid;
  late String title;
  late String contentHTML;

  // TODO: make sure the type of these in video thread
  late String videoCover;
  late String video;

  late String urlSuffix;
  late int lights;
  late int replies;
  late int recommend;
  late int read;
  late String client;
  late bool hasVideo;

  late Author author;
  late DateTime postDateTime;
  late DateTime lastReplyTime;
  late String postDateTimeReadable; // in fact can be find from timestamp

  // what's this?
  late int status;
  late int contentType;

  late int isLock;
  late String rawContent;
  late String postLocation;

  ThreadMain(Map threadJsonMap) {
    tid = threadJsonMap["tid"];
    title = threadJsonMap["title"];
    contentHTML = threadJsonMap["content"];
    videoCover = threadJsonMap["videoCover"];
    video = threadJsonMap["video"];
    urlSuffix = threadJsonMap["url"];
    lights = threadJsonMap["lights"];
    replies = threadJsonMap["replies"];
    recommend = threadJsonMap["recommend"];
    read = threadJsonMap["read"];
    client = threadJsonMap["client"];
    postDateTime =
        DateTime.fromMillisecondsSinceEpoch(threadJsonMap["createdAt"]);
    postDateTimeReadable = threadJsonMap["createdAtFormat"];
    postDateTime =
        DateTime.fromMillisecondsSinceEpoch(threadJsonMap["repliedAt"]);
    hasVideo = threadJsonMap["hasVideo"];
    author = Author(threadJsonMap["author"]);
    status = threadJsonMap["status"];
    isLock = threadJsonMap["isLock"];
    contentType = threadJsonMap["contentType"];
    rawContent = threadJsonMap["format"];
    postLocation = threadJsonMap["location"];
  }
}

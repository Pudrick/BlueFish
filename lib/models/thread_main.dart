import 'package:bluefish/models/author.dart';
import 'package:bluefish/models/floor_meta.dart';
import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/vote.dart';
import 'package:html/parser.dart';

class ThreadMain {
  final String tid;
  final String title;
  final Vote? vote;
  // TODO: make sure the type of these in video thread.
  final String? videoCover;
  final String? video;
  final String urlSuffix;
  final int lightsNum;
  final int repliesNum;
  final int recommendNum;
  final int readNum;
  final bool hasVideo;
  final bool hasVote;
  final bool isRecommended;
  final DateTime lastReplyTime;
  // What's this? Maybe locked/deleted/normal?
  final int status;
  // Maybe text/video/vote or something like that?
  final int contentType;
  final int isLock;
  final String rawContent;
  final String contentHtml;
  final FloorMeta meta;

  const ThreadMain({
    required this.tid,
    required this.title,
    required this.vote,
    required this.videoCover,
    required this.video,
    required this.urlSuffix,
    required this.lightsNum,
    required this.repliesNum,
    required this.recommendNum,
    required this.readNum,
    required this.hasVideo,
    required this.hasVote,
    required this.isRecommended,
    required this.lastReplyTime,
    required this.status,
    required this.contentType,
    required this.isLock,
    required this.rawContent,
    required this.contentHtml,
    required this.meta,
  });

  factory ThreadMain.fromJson(Map<String, dynamic> json) {
    final contentHtml = parseString(json['content']);

    return ThreadMain(
      tid: parseString(json['tid']),
      title: parseString(json['title']),
      vote: null,
      videoCover: parseNullableString(json['videoCover']),
      video: parseNullableString(json['video']),
      urlSuffix: parseString(json['url']),
      lightsNum: parseInt(json['lights']),
      repliesNum: parseInt(json['replies']),
      recommendNum: parseInt(json['recommend']),
      readNum: parseInt(json['read']),
      hasVideo: parseBool(json['hasVideo']),
      hasVote: _detectVote(contentHtml),
      isRecommended: parseBool(json['isRecommended']),
      lastReplyTime: parseDateTimeFromMilliseconds(json['repliedAt']),
      status: parseInt(json['status']),
      contentType: parseInt(json['contentType']),
      isLock: parseInt(json['isLock']),
      rawContent: parseString(json['format']),
      contentHtml: contentHtml,
      meta: FloorMeta.fromJson(
        json,
        author: Author.forThread(parseMap(json['author'])),
      ),
    );
  }

  static bool _detectVote(String contentHtml) {
    final htmlDoc = parse(contentHtml);
    return htmlDoc.querySelector('[data-type="vote"]') != null;
  }

  // TODO: check video existence via HTML when the API payload is not reliable.
  // TODO: parse vote link; vote detection is currently handled by the main post itself.
}

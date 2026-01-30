import 'package:bluefish/models/author_homepage/thread_pic_peek.dart';
import 'package:bluefish/models/author_homepage/thread_video_peek.dart';
import 'package:json_annotation/json_annotation.dart';

part 'author_home_thread_title.g.dart';

@JsonSerializable()
class AuthorHomeThreadTitle {
  final int fid;

  @JsonKey(name: 'create_time')
  final int postTimeStamp;

  @JsonKey(name: 'lastpost_time')
  final int lastReplyStamp;

  // maybe always be "mt"?
  final String type;
  final String title;
  final int tid;
  final int visits;
  final int puid;

  @JsonKey(name: 'replies')
  final int repliesNum;

  @JsonKey(name: 'nickname')
  final String authorName;

  @JsonKey(name: 'topic_logo')
  final String forumIconUrl;

  final String topic_id;

  @JsonKey(name: 'attr')
  final String PHPattr;

  @JsonKey(name: 'pics')
  final List<ThreadPicPeek>? picUrls;
  final int lights;

  @JsonKey(name: 'share_num')
  final int sharedNum;

  @JsonKey(name: 'summary')
  final String? mainFloorPeek;

  @JsonKey(name: 'is_hot', fromJson: _intToBool, toJson: _boolToInt)
  final bool isHot;

  @JsonKey(name: 'is_lock', fromJson: _intToBool, toJson: _boolToInt)
  final bool isLock;

  // TODO: make sure what does this mean.
  final int status;

  @JsonKey(name: 'video')
  final ThreadVideoPeek? videoInfo;

  // ... and what's this?
  final int contentType;
  final String visibleRange;

  const AuthorHomeThreadTitle({
    required this.fid,
    required this.postTimeStamp,
    required this.lastReplyStamp,
    required this.type,
    required this.title,
    required this.tid,
    required this.visits,
    required this.puid,
    required this.repliesNum,
    required this.authorName,
    required this.forumIconUrl,
    required this.topic_id,
    required this.PHPattr,
    this.picUrls,
    required this.lights,
    required this.sharedNum,
    this.mainFloorPeek,
    required this.isHot,
    required this.isLock,
    required this.status,
    this.videoInfo,
    required this.contentType,
    required this.visibleRange,
  });

  factory AuthorHomeThreadTitle.fromJson(Map<String, dynamic> json) =>
      _$AuthorHomeThreadTitleFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorHomeThreadTitleToJson(this);

  static bool _intToBool(dynamic value) => value == 1;
  static int _boolToInt(bool value) => value ? 1 : 0;
}

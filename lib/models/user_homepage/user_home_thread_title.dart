import 'package:bluefish/models/user_homepage/thread_pic_peek.dart';
import 'package:bluefish/models/user_homepage/thread_video_peek.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_home_thread_title.g.dart';

@JsonSerializable()
class UserHomeThreadTitle {
  final int fid;

  @JsonKey(name: 'create_time')
  final int postTimeStamp;

  // the timeStamp here is in seconds, so 1000x.
  DateTime get postTime => DateTime.fromMillisecondsSinceEpoch(postTimeStamp * 1000);

  @JsonKey(name: 'lastpost_time')
  final int lastReplyTimeStamp;
  DateTime get lastReplyTime => DateTime.fromMillisecondsSinceEpoch(lastReplyTimeStamp * 1000);

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

  final int topic_id;

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

  const UserHomeThreadTitle.UserHomeThreadTitle({
    required this.fid,
    required this.postTimeStamp,
    required this.lastReplyTimeStamp,
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

  factory UserHomeThreadTitle.fromJson(Map<String, dynamic> json) =>
      _$UserHomeThreadTitleFromJson(json);

  Map<String, dynamic> toJson() => _$UserHomeThreadTitleToJson(this);

  static bool _intToBool(dynamic value) => value == 1;
  static int _boolToInt(bool value) => value ? 1 : 0;
}

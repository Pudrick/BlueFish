import 'package:json_annotation/json_annotation.dart';

part 'user_home_reply_video_peek.g.dart';

@JsonSerializable()
class UserHomeReplyVideoPeek {
  final int vid;
  final int tid;
  final int pid;
  final int puid;

  @JsonKey(name: 'from_url')
  final String permissionURL;
  @JsonKey(name: 'src')
  final String playUrl;

  Uri get URL => Uri.parse(playUrl);

  @JsonKey(name: 'img')
  final String coverImgUrl;

  final int width;
  final int height;

  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final int duration;
  final int size;

  //TODO：check what this mean. 0 can be play normally.
  final int expire;
  // seems always 0, useless?
  final int play_num;
  final String? origin;

  @JsonKey(name: 'bullet_comment_num')
  final int danmakuNum;

  //TODO: and check what's this.
  final int status;

  @JsonKey(name: 'addtime')
  final int uploadTimeStamp;
  DateTime get uploadTime =>
      DateTime.fromMillisecondsSinceEpoch(uploadTimeStamp * 1000);

  final int? humanSize;

  const UserHomeReplyVideoPeek({
    required this.vid,
    required this.tid,
    required this.pid,
    required this.puid,
    required this.permissionURL,
    required this.playUrl,
    required this.coverImgUrl,
    required this.width,
    required this.height,
    required this.duration,
    required this.size,
    required this.expire,
    required this.play_num,
    this.origin,
    required this.danmakuNum,
    required this.status,
    required this.uploadTimeStamp,
    this.humanSize,
  });
  factory UserHomeReplyVideoPeek.fromJson(Map<String, dynamic> json) =>
      _$UserHomeReplyVideoPeekFromJson(json);

  Map<String, dynamic> toJson() => _$UserHomeReplyVideoPeekToJson(this);

  static int _durationFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

static dynamic _durationToJson(int value) => value;
}

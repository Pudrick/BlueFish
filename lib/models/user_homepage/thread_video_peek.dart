import 'package:json_annotation/json_annotation.dart';

part 'thread_video_peek.g.dart';

@JsonSerializable()
class ThreadVideoPeek {
  final int duration;
  final int vid;

  @JsonKey(name: 'img')
  final String imgUrl;
  final int size;
  final int width;
  final int height;

  @JsonKey(name: 'play_num')
  final int totalPlays;

  @JsonKey(name: 'url')
  final String videoUrl;
  
  // what's this?
  final int bulletCommentNum;

  const ThreadVideoPeek({
  required this.duration,
  required this.vid,
  required this.imgUrl,
  required this.size,
  required this.width,
  required this.height,
  required this.totalPlays,
  required this.videoUrl,

  // maybe means "danmaku"?
  @JsonKey(name: 'bullet_comment_num')
  required this.bulletCommentNum,
  });

  factory ThreadVideoPeek.fromJson(Map<String, dynamic> json) =>
    _$ThreadVideoPeekFromJson(json);
}
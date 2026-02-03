// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_video_peek.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThreadVideoPeek _$ThreadVideoPeekFromJson(Map<String, dynamic> json) =>
    ThreadVideoPeek(
      duration: (json['duration'] as num).toInt(),
      vid: (json['vid'] as num).toInt(),
      imgUrl: json['img'] as String,
      size: (json['size'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      totalPlays: (json['play_num'] as num).toInt(),
      videoUrl: json['url'] as String,
      bulletCommentNum: (json['bullet_comment_num'] as num).toInt(),
    );

Map<String, dynamic> _$ThreadVideoPeekToJson(ThreadVideoPeek instance) =>
    <String, dynamic>{
      'duration': instance.duration,
      'vid': instance.vid,
      'img': instance.imgUrl,
      'size': instance.size,
      'width': instance.width,
      'height': instance.height,
      'play_num': instance.totalPlays,
      'url': instance.videoUrl,
      'bullet_comment_num': instance.bulletCommentNum,
    };

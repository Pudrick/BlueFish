// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_home_reply_video_peek.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserHomeReplyVideoPeek _$UserHomeReplyVideoPeekFromJson(
  Map<String, dynamic> json,
) => UserHomeReplyVideoPeek(
  vid: (json['vid'] as num).toInt(),
  tid: (json['tid'] as num).toInt(),
  pid: (json['pid'] as num).toInt(),
  puid: (json['puid'] as num).toInt(),
  permissionURL: json['from_url'] as String,
  playUrl: json['src'] as String,
  coverImgUrl: json['img'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  duration: UserHomeReplyVideoPeek._durationFromJson(json['duration']),
  size: (json['size'] as num).toInt(),
  expire: (json['expire'] as num).toInt(),
  play_num: (json['play_num'] as num).toInt(),
  origin: json['origin'] as String?,
  danmakuNum: (json['bullet_comment_num'] as num).toInt(),
  status: (json['status'] as num).toInt(),
  uploadTimeStamp: (json['addtime'] as num).toInt(),
  humanSize: (json['humanSize'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserHomeReplyVideoPeekToJson(
  UserHomeReplyVideoPeek instance,
) => <String, dynamic>{
  'vid': instance.vid,
  'tid': instance.tid,
  'pid': instance.pid,
  'puid': instance.puid,
  'from_url': instance.permissionURL,
  'src': instance.playUrl,
  'img': instance.coverImgUrl,
  'width': instance.width,
  'height': instance.height,
  'duration': UserHomeReplyVideoPeek._durationToJson(instance.duration),
  'size': instance.size,
  'expire': instance.expire,
  'play_num': instance.play_num,
  'origin': instance.origin,
  'bullet_comment_num': instance.danmakuNum,
  'status': instance.status,
  'addtime': instance.uploadTimeStamp,
  'humanSize': instance.humanSize,
};

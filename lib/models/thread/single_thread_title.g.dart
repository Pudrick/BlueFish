// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_thread_title.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleThreadTitle _$SingleThreadTitleFromJson(Map<String, dynamic> json) =>
    SingleThreadTitle(
      fid: (json['fid'] as num).toInt(),
      isGifInt: (json['is_gif'] as num).toInt(),
      repliesNum: (json['replys'] as num).toInt(),
      authorName: json['user_name'] as String,
      coverHeight: (json['cover_height'] as num).toInt(),
      title: json['title'] as String,
      type: (json['type'] as num).toInt(),
      tid: (json['tid'] as num).toInt(),
      lightRepliesNum: (json['light_replys'] as num).toInt(),
      puid: (json['puid'] as num).toInt(),
      coverWidth: (json['cover_width'] as num).toInt(),
      imageCount: (json['image_count'] as num).toInt(),
      zoneId: (json['zoneId'] as num?)?.toInt(),
      recommends: (json['recommends'] as num).toInt(),
      time: json['time'] as String,
      threadType: json['threadType'] as String?,
      contentType: (json['contentType'] as num?)?.toInt(),
      isPinned: json['isPinned'] as bool?,
    );

Map<String, dynamic> _$SingleThreadTitleToJson(SingleThreadTitle instance) =>
    <String, dynamic>{
      'fid': instance.fid,
      'is_gif': instance.isGifInt,
      'replys': instance.repliesNum,
      'user_name': instance.authorName,
      'cover_height': instance.coverHeight,
      'title': instance.title,
      'type': instance.type,
      'tid': instance.tid,
      'light_replys': instance.lightRepliesNum,
      'puid': instance.puid,
      'cover_width': instance.coverWidth,
      'image_count': instance.imageCount,
      'zoneId': instance.zoneId,
      'recommends': instance.recommends,
      'time': instance.time,
      'threadType': instance.threadType,
      'contentType': instance.contentType,
      'isPinned': instance.isPinned,
    };

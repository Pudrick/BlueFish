// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_thread_title.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleThreadTitle _$SingleThreadTitleFromJson(Map<String, dynamic> json) =>
    SingleThreadTitle()
      ..fid = json['fid'] as int
      ..is_gif = json['is_gif'] as int
      ..replys = json['replys'] as int
      ..user_name = json['user_name'] as String
      ..cover_height = json['cover_height'] as int
      ..title = json['title'] as String
      ..type = json['type'] as int
      ..tid = json['tid'] as int
      ..light_replys = json['light_replys'] as int
      ..puid = json['puid'] as int
      ..cover_width = json['cover_width'] as int
      ..image_count = json['image_count'] as int
      ..zoneId = json['zoneId'] as int?
      ..recommends = json['recommends'] as int
      ..time = json['time'] as String
      ..threadType = json['threadType'] as String?
      ..contentType = json['contentType'] as int?
      ..isPinned = json['isPinned'] as bool;

Map<String, dynamic> _$SingleThreadTitleToJson(SingleThreadTitle instance) =>
    <String, dynamic>{
      'fid': instance.fid,
      'is_gif': instance.is_gif,
      'replys': instance.replys,
      'user_name': instance.user_name,
      'cover_height': instance.cover_height,
      'title': instance.title,
      'type': instance.type,
      'tid': instance.tid,
      'light_replys': instance.light_replys,
      'puid': instance.puid,
      'cover_width': instance.cover_width,
      'image_count': instance.image_count,
      'zoneId': instance.zoneId,
      'recommends': instance.recommends,
      'time': instance.time,
      'threadType': instance.threadType,
      'contentType': instance.contentType,
      'isPinned': instance.isPinned,
    };

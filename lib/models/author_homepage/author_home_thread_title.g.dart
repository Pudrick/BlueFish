// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author_home_thread_title.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorHomeThreadTitle _$AuthorHomeThreadTitleFromJson(
  Map<String, dynamic> json,
) => AuthorHomeThreadTitle(
  fid: (json['fid'] as num).toInt(),
  postTimeStamp: (json['create_time'] as num).toInt(),
  lastReplyStamp: (json['lastpost_time'] as num).toInt(),
  type: json['type'] as String,
  title: json['title'] as String,
  tid: (json['tid'] as num).toInt(),
  visits: (json['visits'] as num).toInt(),
  puid: (json['puid'] as num).toInt(),
  repliesNum: (json['replies'] as num).toInt(),
  authorName: json['nickname'] as String,
  forumIconUrl: json['topic_logo'] as String,
  topic_id: (json['topic_id'] as num).toInt(),
  PHPattr: json['attr'] as String,
  picUrls: (json['pics'] as List<dynamic>?)
      ?.map((e) => ThreadPicPeek.fromJson(e as Map<String, dynamic>))
      .toList(),
  lights: (json['lights'] as num).toInt(),
  sharedNum: (json['share_num'] as num).toInt(),
  mainFloorPeek: json['summary'] as String?,
  isHot: AuthorHomeThreadTitle._intToBool(json['is_hot']),
  isLock: AuthorHomeThreadTitle._intToBool(json['is_lock']),
  status: (json['status'] as num).toInt(),
  videoInfo: json['video'] == null
      ? null
      : ThreadVideoPeek.fromJson(json['video'] as Map<String, dynamic>),
  contentType: (json['contentType'] as num).toInt(),
  visibleRange: json['visibleRange'] as String,
);

Map<String, dynamic> _$AuthorHomeThreadTitleToJson(
  AuthorHomeThreadTitle instance,
) => <String, dynamic>{
  'fid': instance.fid,
  'create_time': instance.postTimeStamp,
  'lastpost_time': instance.lastReplyStamp,
  'type': instance.type,
  'title': instance.title,
  'tid': instance.tid,
  'visits': instance.visits,
  'puid': instance.puid,
  'replies': instance.repliesNum,
  'nickname': instance.authorName,
  'topic_logo': instance.forumIconUrl,
  'topic_id': instance.topic_id,
  'attr': instance.PHPattr,
  'pics': instance.picUrls,
  'lights': instance.lights,
  'share_num': instance.sharedNum,
  'summary': instance.mainFloorPeek,
  'is_hot': AuthorHomeThreadTitle._boolToInt(instance.isHot),
  'is_lock': AuthorHomeThreadTitle._boolToInt(instance.isLock),
  'status': instance.status,
  'video': instance.videoInfo,
  'contentType': instance.contentType,
  'visibleRange': instance.visibleRange,
};

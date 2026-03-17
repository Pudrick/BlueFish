// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mention_reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplyPic _$ReplyPicFromJson(Map<String, dynamic> json) => ReplyPic(
  urlStr: json['url'] as String,
  isGifInt: (json['is_gif'] as num).toInt(),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
);

Map<String, dynamic> _$ReplyPicToJson(ReplyPic instance) => <String, dynamic>{
  'url': instance.urlStr,
  'is_gif': instance.isGifInt,
  'width': instance.width,
  'height': instance.height,
};

MentionReply _$MentionReplyFromJson(Map<String, dynamic> json) => MentionReply(
  id: (json['id'] as num).toInt(),
  msgType: (json['msgType'] as num).toInt(),
  puid: (json['puid'] as num).toInt(),
  username: json['username'] as String,
  userBanned: (json['userBanned'] as num?)?.toInt(),
  avatarUrlStr: json['headerUrl'] as String,
  cert: (json['cert'] as num?)?.toInt(),
  content: json['postContent'] as String,
  threadTitle: json['threadTitle'] as String,
  tid: (json['tid'] as num).toInt(),
  pid: (json['pid'] as num).toInt(),
  fid: (json['fid'] as num).toInt(),
  topicId: (json['topicId'] as num).toInt(),
  imagesList:
      (json['pics'] as List<dynamic>?)
          ?.map((e) => ReplyPic.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  video: (json['video'] as num?)?.toInt(),
  quoteContent: json['quoteContent'] as String,
  delete: (json['delete'] as num?)?.toInt(),
  hide: (json['hide'] as num?)?.toInt(),
  auditStatus: (json['auditStatus'] as num?)?.toInt(),
  publishTimeFormatStr: json['publishTime'] as String,
  threader: json['threader'] as String?,
  followStatus: json['yrConcern'] as String?,
  protocolThreadUrl: json['threadSchema'] as String,
  protocolReplyUrl: json['replySchema'] as String,
  publishTimeStamp: (json['updateTime'] as num).toInt(),
);

Map<String, dynamic> _$MentionReplyToJson(MentionReply instance) =>
    <String, dynamic>{
      'id': instance.id,
      'msgType': instance.msgType,
      'puid': instance.puid,
      'username': instance.username,
      'userBanned': instance.userBanned,
      'headerUrl': instance.avatarUrlStr,
      'cert': instance.cert,
      'postContent': instance.content,
      'threadTitle': instance.threadTitle,
      'tid': instance.tid,
      'pid': instance.pid,
      'fid': instance.fid,
      'topicId': instance.topicId,
      'pics': instance.imagesList,
      'video': instance.video,
      'quoteContent': instance.quoteContent,
      'delete': instance.delete,
      'hide': instance.hide,
      'auditStatus': instance.auditStatus,
      'publishTime': instance.publishTimeFormatStr,
      'threader': instance.threader,
      'yrConcern': instance.followStatus,
      'threadSchema': instance.protocolThreadUrl,
      'replySchema': instance.protocolReplyUrl,
      'updateTime': instance.publishTimeStamp,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_home_reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReplyPicInfo _$ReplyPicInfoFromJson(Map<String, dynamic> json) => ReplyPicInfo(
  url: Uri.parse(json['url'] as String),
  height: (json['height'] as num).toInt(),
  width: (json['width'] as num).toInt(),
  count: (json['count'] as num).toInt(),
  isGif: json['isGif'] as bool,
);

Map<String, dynamic> _$ReplyPicInfoToJson(ReplyPicInfo instance) =>
    <String, dynamic>{
      'url': instance.url.toString(),
      'height': instance.height,
      'width': instance.width,
      'count': instance.count,
      'isGif': instance.isGif,
    };

UserHomeReply _$UserHomeReplyFromJson(Map<String, dynamic> json) =>
    UserHomeReply(
      pid: (json['pid'] as num).toInt(),
      tid: (json['tid'] as num).toInt(),
      aid: (json['aid'] as num?)?.toInt(),
      puid: (json['puid'] as num).toInt(),
      euid: (json['euid'] as num?)?.toInt(),
      userName: json['username'] as String,
      avatarUrl: UserHomeReply._uriFromJson(json['header'] as String),
      via: (json['via'] as num).toInt(),
      replyContent: json['content'] as String,
      quotePid: (json['quote'] as num).toInt(),
      quote: json['quoteInfo'] == null
          ? null
          : UserHomeReply.fromJson(json['quoteInfo'] as Map<String, dynamic>),
      createTimeStamp: (json['createTime'] as num).toInt(),
      updateInfo: json['updateInfo'] as String,
      rawPHPAttr: json['attr'] as String,
      score: (json['score'] as num).toInt(),
      videoInfo: json['videoInfo'] == null
          ? null
          : UserHomeReplyVideoPeek.fromJson(
              json['videoInfo'] as Map<String, dynamic>,
            ),
      lightCount: (json['lightCount'] as num).toInt(),
      unLightCount: (json['unlightCount'] as num).toInt(),
      replyPics: (json['picInfos'] as List<dynamic>)
          .map((e) => ReplyPicInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      threadTitle: json['title'] as String,
      formatTime: json['formatTime'] as String,
      topicId: (json['topicId'] as num).toInt(),
    );

Map<String, dynamic> _$UserHomeReplyToJson(UserHomeReply instance) =>
    <String, dynamic>{
      'pid': instance.pid,
      'tid': instance.tid,
      'aid': instance.aid,
      'puid': instance.puid,
      'euid': instance.euid,
      'username': instance.userName,
      'header': UserHomeReply._uriToJson(instance.avatarUrl),
      'via': instance.via,
      'content': instance.replyContent,
      'quote': instance.quotePid,
      'quoteInfo': instance.quote?.toJson(),
      'createTime': instance.createTimeStamp,
      'updateInfo': instance.updateInfo,
      'attr': instance.rawPHPAttr,
      'score': instance.score,
      'videoInfo': instance.videoInfo?.toJson(),
      'lightCount': instance.lightCount,
      'unlightCount': instance.unLightCount,
      'picInfos': instance.replyPics.map((e) => e.toJson()).toList(),
      'title': instance.threadTitle,
      'formatTime': instance.formatTime,
      'topicId': instance.topicId,
    };

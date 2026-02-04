import 'dart:convert';
import 'dart:io';

import 'package:bluefish/utils/http_with_ua.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:php_serializer/php_serializer.dart';

@JsonSerializable()
class ReplyPicInfo {
  final Uri url;
  final int height;
  final int width;
  final int count;
  final bool isGif;

  ReplyPicInfo({
    required this.url,
    required this.height,
    required this.width,
    required this.count,
    required this.isGif,
  });

  factory ReplyPicInfo.fromJson(Map<String, dynamic> json) =>
      replyPicInfoFromJson(json);

  // Map<String, dynamic> toJson() => _$ReplyPicInfoToJson(this);

  static ReplyPicInfo replyPicInfoFromJson(Map<String, dynamic> json) =>
      ReplyPicInfo(
        url: Uri.parse(json['url'] as String),
        height: (json['height'] as num).toInt(),
        width: (json['width'] as num).toInt(),
        count: (json['count'] as num).toInt(),
        isGif: (json['isGif'] as num) == 1 ? true : false,
      );
}

@JsonSerializable()
class UserHomeReply {
  final int pid;
  final int tid;
  final int? aid;
  final int puid;
  final int? euid;

  @JsonKey(name: 'username')
  final String userName;
  @JsonKey(name: 'header')
  final Uri avatarUrl;

  // what's this?
  final int via;

  @JsonKey(name: 'content')
  final String replyContent;

  @JsonKey(name: 'quote')
  final int quotePid;
  @JsonKey(name: 'quoteInfo')
  final UserHomeReply? quote;

  @JsonKey(name: 'createTime')
  final int createTimeStamp;

  // ... and what's this?
  final String updateInfo;

  @JsonKey(name: 'attr')
  final String rawPHPAttr;  
  // keys: client, source, audit_status
  final Map<String, dynamic> parsedPHPAttr;

  final int score;

  // FIXME: make sure what type it is.
  final String? videoInfo;
  final int lightCount;
  @JsonKey(name: 'unlightCount')
  final int unLightCount;

  @JsonKey(name: 'picInfos')
  final List<ReplyPicInfo> replyPics;

  // there's a replyReplyNum attribute, but it seems always null, so ignore it.
  // final int? replyReplyNum

  @JsonKey(name: 'title')
  final String threadTitle;
  final String formatTime;
  final int topicId;
  final String topicName = "崩坏3";


  UserHomeReply({
    required this.pid,
    required this.tid,
    this.aid,
    required this.puid,
    this.euid,
    required this.userName,
    required this.avatarUrl,
    required this.via,
    required this.replyContent,
    required this.quotePid,
    this.quote,
    required this.createTimeStamp,
    required this.updateInfo,
    required this.rawPHPAttr,
    required this.score,
    required this.videoInfo,
    required this.lightCount,
    required this.unLightCount,
    required this.replyPics,
    required this.threadTitle,
    required this.formatTime,
    required this.topicId,
  }) : parsedPHPAttr = Map<String, dynamic>.from(
         phpDeserialize(rawPHPAttr) as Map,
       );
  factory UserHomeReply.fromJson(Map<String, dynamic> json) =>
      authorHomeReplyFromJson(json);

  // Map<String, dynamic> toJson() => _$AuthorHomeReplyToJson(this);

  static UserHomeReply authorHomeReplyFromJson(Map<String, dynamic> json) =>
      UserHomeReply(
        pid: (json['pid'] as num).toInt(),
        tid: (json['tid'] as num).toInt(),
        aid: (json['aid'] as num?)?.toInt(),
        puid: (json['puid'] as num).toInt(),
        euid: (json['euid'] as num?)?.toInt(),
        userName: json['username'] as String,
        avatarUrl: Uri.parse(json['header'] as String),
        via: (json['via'] as num).toInt(),
        replyContent: json['content'] as String,
        quotePid: (json['quote'] as num).toInt(),
        quote: json['quoteInfo'] == null
            ? null
            : UserHomeReply.fromJson(
                json['quoteInfo'] as Map<String, dynamic>,
              ),
        createTimeStamp: (json['createTime'] as num).toInt(),
        updateInfo: json['updateInfo'] as String,
        rawPHPAttr: json['attr'] as String,
        score: (json['score'] as num).toInt(),
        videoInfo: json['videoInfo'] as String?,
        lightCount: (json['lightCount'] as num).toInt(),
        unLightCount: (json['unlightCount'] as num).toInt(),
        replyPics: (json['picInfos'] as List<dynamic>)
            .map((e) => ReplyPicInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        threadTitle: json['title'] as String,
        formatTime: json['formatTime'] as String,
        topicId: (json['topicId'] as num).toInt(),
      );
}

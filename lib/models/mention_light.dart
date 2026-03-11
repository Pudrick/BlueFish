import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mention_light.g.dart';

@JsonSerializable()
class MentionLight
{
  // looks like 'pid' in other places.
  final int id;

  @JsonKey(name: 'updateTime')
  final int updateTimeStamp;
  DateTime get updateTime => DateTime.fromMillisecondsSinceEpoch(updateTimeStamp * 1000);

  final int dataType;
  final int puid;

  // TODO: check what the type number indicates.
  final int type;

  // maybe always same with the thread's tid?
  final int operateId;
  final int pid;

  // what's this?
  final int number;

  final int? recommendNum;
  final int lightNum;
  final int historyNum;

  // maybe useless...?
  final String url;

  // TODO: check this.
  final int status;

  @JsonKey(name: 'lastTime')
  final int lastTimeStamp;
  DateTime get lastTime => DateTime.fromMillisecondsSinceEpoch(lastTimeStamp * 1000);
  @JsonKey(name: 'title')
  final String threadTitle;
  final int optUid;
  @JsonKey(name: 'isVideo')
  final int isVideoNum;
  bool get isVideo => isVideoNum != 0;
  final String? optHeader;
  final String? optUsername;
  final String? optSpaceUrl;
  final String titlePrefix;
  final String? certIconUrl;
  final String? certTitle;

  final LightPost post;

  final List<Operator> operators;

  @JsonKey(name: 'formatTime')
  final String createTimeString;

  MentionLight({
    required this.id,
    required this.updateTimeStamp,
    required this.dataType,
    required this.puid,
    required this.type,
    required this.operateId,
    required this.pid,
    required this.number,
    this.recommendNum,
    required this.lightNum,
    required this.historyNum,
    required this.url,
    required this.status,
    required this.lastTimeStamp,
    required this.threadTitle,
    required this.optUid,
    required this.isVideoNum,
    this.optHeader,
    this.optUsername,
    this.optSpaceUrl,
    required this.titlePrefix,
    this.certIconUrl,
    this.certTitle,
    required this.post,
    required this.operators,
    required this.createTimeString,
  });

  factory MentionLight.fromJson(Map<String, dynamic> json) => _$MentionLightFromJson(json);
  Map<String, dynamic> toJson() => _$MentionLightToJson(this);

}

@JsonSerializable()
class LightPost
{
  final int pid;
  final int tid;
  final int? aid;
  final int puid;
  final String username;
  final String userIp;

  // what's this?
  final int via;
  final String content;
  final int quote;

  @JsonKey(name: 'createTime')
  final int createTimeStamp;
  DateTime get createTime => DateTime.fromMillisecondsSinceEpoch(createTimeStamp * 1000);
  final String updateInfo;
  
  @JsonKey(name: 'attr')
  final String rawPHPAttr;

  final int score;
  final int preCount;

  @JsonKey(name: 'header')
  final String avatarUrlStr;
  Uri get avatarUrl => Uri.parse(avatarUrlStr);

  final int page;
  final String? url;
  final int lightCount;
  final int? quoteLightCount;

  @JsonKey(name: 'isHide')
  final int isHideInt;
  bool get isHide => (isHideInt != 0);

  final int? quoteIsHide;
  final int auditStatus;
  final int? quoteAuditStatus;

  @JsonKey(name: 'isDelete')
  final int isDeleteInt;
  bool get isDelete => (isDeleteInt != 0);

  final int? quoteIsDeleted;
  final int? quoteDeleted;

  @JsonKey(name: 'userBanned')
  final int userBannedInt;
  bool get isUserBanned => (userBannedInt != 0);

  final String? quoteInfo;
  final int? quotePuid;
  final int? quoteFloor;
  final String? quoteUsername;
  final String? quoteContent;
  final String? isMerged;
  final String? mergeId;
  final String? mergeTitle;

  LightPost({
    required this.pid,
    required this.tid,
    this.aid,
    required this.puid,
    required this.username,
    required this.userIp,
    required this.via,
    required this.content,
    required this.quote,
    required this.createTimeStamp,
    required this.updateInfo,
    required this.rawPHPAttr,
    required this.score,
    required this.preCount,
    required this.avatarUrlStr,
    required this.page,
    this.url,
    required this.lightCount,
    this.quoteLightCount,
    required this.isHideInt,
    this.quoteIsHide,
    required this.auditStatus,
    this.quoteAuditStatus,
    required this.isDeleteInt,
    this.quoteIsDeleted,
    this.quoteDeleted,
    required this.userBannedInt,
    this.quoteInfo,
    this.quotePuid,
    this.quoteFloor,
    this.quoteUsername,
    this.quoteContent,
    this.isMerged,
    this.mergeId,
    this.mergeTitle,
  });

  factory LightPost.fromJson(Map<String, dynamic> json) => _$LightPostFromJson(json);
  Map<String, dynamic> toJson() => _$LightPostToJson(this);
}

@JsonSerializable()
class Operator
{
  final int? uid;
  final String username;
  @JsonKey(name: 'spaceUrl')
  final String spaceUrlStr;
  Uri get spaceUrl => Uri.parse(spaceUrlStr);
  @JsonKey(name: 'optHeader')
  final String avatarUrlStr;
  Uri get avatarUrl => Uri.parse(avatarUrlStr);
  final String? certIconUrl;
  final String? certTitle;

  Operator({
    this.uid,
    required this.username,
    required this.spaceUrlStr,
    required this.avatarUrlStr,
    this.certIconUrl,
    this.certTitle,
  });

  factory Operator.fromJson(Map<String, dynamic> json) => _$OperatorFromJson(json);
  Map<String, dynamic> toJson() => _$OperatorToJson(this);
}
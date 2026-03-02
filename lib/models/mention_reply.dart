import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mention_reply.g.dart';

@JsonSerializable()
class ReplyPic {
    @JsonKey(name: 'url')
    final String urlStr;
    Uri get Url => Uri.parse(urlStr);

    @JsonKey(name: 'is_gif')
    final int isGifInt;
    bool get isGif => isGifInt == 1;

    final int width;
    final int height;

    ReplyPic({
    required this.urlStr,
    required this.isGifInt,
    required this.width,
    required this.height,
  });

  factory ReplyPic.fromJson(Map<String, dynamic> json) => _$ReplyPicFromJson(json);
  Map<String, dynamic> toJson() => _$ReplyPicToJson(this);
}

@JsonSerializable()
class MentionReply {
    // is this pid? but there is a existing pid field.
  final int id;

    // what's this?
  final int msgType;
  final int puid;
  final String username;

  //TODO: make sure what type is
  final int? userBanned;

    @JsonKey(name: 'headerUrl')
    final String avatarUrlStr;
    Uri get avatarUrl => Uri.parse(avatarUrlStr);

    // TODO: make sure what type is
    final int? cert;

    @JsonKey(name: 'postContent')
    final String content;
    final String threadTitle;
    final int tid;
    final int pid;
    final int fid;
    final int topicId;
    @JsonKey(name: 'pics')
    final List<ReplyPic> imagesList;

    //TODO: get type of this field.
    final int? video;

    // quote here is just a string, do not has pic or other elements.
    final String quoteContent;
    
    //TODO: these status variable types do not know. temporarily use int.
    final int? delete;
    final int? hide;
    final int? auditStatus;

    @JsonKey(name: 'publishTime')
    final String publishTimeFormatStr;

    //TODO: what type is this?
    final int? threader;

    @JsonKey(name: 'yrConcern')
    final String? followStatus;

    @JsonKey(name: 'threadSchema')
    final String protocolThreadUrl;
    @JsonKey(name: 'replySchema')
    final String protocolReplyUrl;

    @JsonKey(name: 'updateTime')
    final int publishTimeStamp;
    DateTime get publishTime => DateTime.fromMillisecondsSinceEpoch(publishTimeStamp * 1000);

    MentionReply({
    required this.id,
    required this.msgType,
    required this.puid,
    required this.username,
    this.userBanned,
    required this.avatarUrlStr,
    this.cert,
    required this.content,
    required this.threadTitle,
    required this.tid,
    required this.pid,
    required this.fid,
    required this.topicId,
    required this.imagesList,
    this.video,
    required this.quoteContent,
    this.delete,
    this.hide,
    this.auditStatus,
    required this.publishTimeFormatStr,
    this.threader,
    this.followStatus,
    required this.protocolThreadUrl,
    required this.protocolReplyUrl,
    required this.publishTimeStamp,
  });

  factory MentionReply.fromJson(Map<String, dynamic> json) => _$MentionReplyFromJson(json);
  Map<String, dynamic> toJson() => _$MentionReplyToJson(this);
}
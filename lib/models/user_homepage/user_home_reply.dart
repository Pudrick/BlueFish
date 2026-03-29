import 'package:bluefish/models/user_homepage/user_home_reply_video_peek.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:php_serializer/php_serializer.dart';

part 'user_home_reply.g.dart';

@JsonSerializable()
class ReplyPicInfo {
  final Uri url;
  final int height;
  final int width;
  final int count;

  @JsonKey(fromJson: _intToBool, toJson: _boolToInt)
  final bool isGif;

  ReplyPicInfo({
    required this.url,
    required this.height,
    required this.width,
    required this.count,
    required this.isGif,
  });

  factory ReplyPicInfo.fromJson(Map<String, dynamic> json) =>
      _$ReplyPicInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReplyPicInfoToJson(this);

  static bool _intToBool(dynamic value) => value == 1;
  static int _boolToInt(bool value) => value ? 1 : 0;
}

@JsonSerializable(explicitToJson: true)
class UserHomeReply {
  final int pid;
  final int tid;
  final int? aid;
  final int puid;
  final int? euid;

  @JsonKey(name: 'username')
  final String userName;

  @JsonKey(
    name: 'header',
    fromJson: _uriFromJson,
    toJson: _uriToJson,
  )
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

  DateTime get createTime =>
      DateTime.fromMillisecondsSinceEpoch(createTimeStamp * 1000);

  // ... and what's this?
  final String updateInfo;

  @JsonKey(name: 'attr')
  final String rawPHPAttr;

  // keys: client, source, audit_status
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Map<String, dynamic> parsedPHPAttr;

  final int score;

  final UserHomeReplyVideoPeek? videoInfo;

  final int lightCount;

  @JsonKey(name: 'unlightCount')
  final int unLightCount;

  @JsonKey(name: 'picInfos')
  final List<ReplyPicInfo> replyPics;

  @JsonKey(name: 'title')
  final String threadTitle;

  final String formatTime;
  final int topicId;

  @JsonKey(includeFromJson: false)
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
      _$UserHomeReplyFromJson(json);

  Map<String, dynamic> toJson() => _$UserHomeReplyToJson(this);

  // ---------- converters ----------

  static Uri _uriFromJson(String value) => Uri.parse(value);

  static String _uriToJson(Uri uri) => uri.toString();
}

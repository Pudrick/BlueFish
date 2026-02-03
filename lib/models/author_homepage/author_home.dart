import 'package:bluefish/models/author_homepage/author_home_reply.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'author_home_thread_title.dart';

// part 'author_home.g.dart';

enum FollowStatus { following, notFollowed, self }

enum Gender { female, male, unknown }

enum ThreadListType {
  post,
  recommend;

  String get apiType => switch (this) {
    ThreadListType.post => 'getThreadList',
    ThreadListType.recommend => 'getRecommendList',
  };
}

// @JsonSerializable()
class AuthorHome {
  // TODO: what is this used for?
  final bool isLogin;

  final Uri bbs_follow_url;

  // -1 for not followed(include self), 2 for followed
  @JsonKey(
    name: 'follow_status',
    fromJson: _intToFollowStatus,
    toJson: _followStatusToInt,
  )
  final FollowStatus followStatus;
  @JsonKey(fromJson: _getReputationNum)
  final int reputation;

  // main threads count
  @JsonKey(name: 'bbs_msg_count')
  final int mainThreadsCount;

  @JsonKey(name: 'be_light_count')
  final int be_light_count;
  final double bbsUserLevelPercent;

  // not the level number that in mainpage. do not use this.
  final int level;
  final String? birth;

  @JsonKey(name: 'be_follow_count')
  final int fansCount;

  // this is the mainpage user level.
  final String bbsUserLevel;

  @JsonKey(name: 'bbsUserLevelDesc')
  final String bbsUserLevelFormatedStr;

  @JsonKey(name: 'bbs_recommend_count')
  final int recommendCount;
  final int follow_count;

  @JsonKey(name: 'header')
  final Uri avatarUrl;
  final bool be_follow_status;

  @JsonKey(name: 'be_recommend_count')
  final int beRecommendCount;

  @JsonKey(fromJson: _intToGender, toJson: _genderToInt)
  final Gender gender;

  // do not know what does this means
  final String? banStatus;
  final int puid;

  @JsonKey(name: 'header_back')
  final Uri gaussAvatarUrl;

  final String nickname;

  @JsonKey(name: 'is_self', fromJson: _intToBool, toJson: _boolToInt)
  final bool isSelf;

  @JsonKey(name: 'reg_time_str')
  final String registerTimeStr;

  // what's this?
  // only appear in self page.
  final int? bbs_favorite_count;

  @JsonKey(name: 'bbs_post_count')
  final int replyCount;
  final String location;

  // ... and what're these?
  final bool nextPage;
  final String env;
  final String tabKey;

  static const threadPageSize = 30;
  // AuthorHomeThreadList threads;
  final List<AuthorHomeThreadTitle> threads;
  // AuthorHomeThreadList recommendThreads;
  final List<AuthorHomeThreadTitle> recommendThreads;  

    static const int replyPageSize = 20;
  // AuthorHomeReplyList replies;
  final List<AuthorHomeReply> replies;


  final String euid;

  AuthorHome({
    required this.bbs_follow_url,
    required this.followStatus,
    required this.reputation,
    required this.mainThreadsCount,
    required this.be_light_count,
    required this.bbsUserLevelPercent,
    required this.level,
    this.birth,
    required this.fansCount,
    required this.bbsUserLevel,
    required this.bbsUserLevelFormatedStr,
    required this.recommendCount,
    required this.follow_count,
    required this.avatarUrl,
    required this.be_follow_status,
    required this.beRecommendCount,
    required this.gender,
    this.banStatus,
    required this.puid,
    required this.gaussAvatarUrl,
    required this.nickname,
    required this.isSelf,
    required this.registerTimeStr,
    this.bbs_favorite_count,
    required this.replyCount,
    required this.location,
    required this.nextPage,
    required this.env,
    required this.tabKey,

    // only for 1st page.
    this.threads = const [],
    required this.euid,
    this.replies = const [],
    this.recommendThreads = const [],
    required this.isLogin,
  });

  static int _getReputationNum(Map<String, dynamic> json) {
    return json['value'] as int;
  }

  factory AuthorHome.fromJson(Map<String, dynamic> json) {
    return AuthorHome(
      bbs_follow_url: Uri.parse(json['bbs_follow_url'] as String),
      followStatus: AuthorHome._intToFollowStatus(json['follow_status']),
      reputation: AuthorHome._getReputationNum(
        json['reputation'] as Map<String, dynamic>,
      ),
      mainThreadsCount: (json['bbs_msg_count'] as num).toInt(),
      be_light_count: (json['be_light_count'] as num).toInt(),
      bbsUserLevelPercent: (json['bbsUserLevelPercent'] as num).toDouble(),
      level: (json['level'] as num).toInt(),
      birth: json['birth'] as String?,
      fansCount: (json['be_follow_count'] as num).toInt(),
      bbsUserLevel: json['bbsUserLevel'] as String,
      bbsUserLevelFormatedStr: json['bbsUserLevelDesc'] as String,
      recommendCount: (json['bbs_recommend_count'] as num).toInt(),
      follow_count: (json['follow_count'] as num).toInt(),
      avatarUrl: Uri.parse(json['header'] as String),

      be_follow_status: (json['be_follow_status'] as int) == -1 ? false : true,
      beRecommendCount: (json['be_recommend_count'] as num).toInt(),
      gender: AuthorHome._intToGender(json['gender']),
      banStatus: json['banStatus'] as String?,
      puid: (json['puid'] as num).toInt(),
      gaussAvatarUrl: Uri.parse(json['header_back'] as String),
      nickname: json['nickname'] as String,
      isSelf: AuthorHome._intToBool(json['is_self']),
      registerTimeStr: json['reg_time_str'] as String,

      bbs_favorite_count: (json['bbs_favorite_count'] as num?)?.toInt(),

      replyCount: (json['bbs_post_count'] as num).toInt(),
      location: json['location'] as String,
      nextPage: json['nextPage'] as bool,
      env: json['env'] as String,
      tabKey: json['tabKey'] as String,

      euid: json['euid'] as String,

      // keep empty here, fill it later via API.
      // threads: AuthorHomeThreadList(authorEuid: json['euid'] as String, type: ThreadListType.post),
      // replies: AuthorHomeReplyList(authorEuid: json['euid'] as String),
      // recommendThreads: AuthorHomeThreadList(authorEuid: json['euid'] as String, type: ThreadListType.recommend)
      isLogin: json['isLogin'] as bool,
    );
  }

    AuthorHome copyWith({
    List<AuthorHomeThreadTitle>? threads,
    List<AuthorHomeReply>? replies,
    List<AuthorHomeThreadTitle>? recommendThreads,
    FollowStatus? followStatus, 
  }) {
    return AuthorHome(
      // changed field
      threads: threads ?? this.threads,
      replies: replies ?? this.replies,
      recommendThreads: recommendThreads ?? this.recommendThreads,
      followStatus: followStatus ?? this.followStatus,
      
      // fields that didn't change
      isLogin: isLogin,
      euid: euid,
      nickname: nickname,
      puid: puid,
      isSelf: isSelf,
      be_follow_status: be_follow_status,
      banStatus: banStatus,
      reputation: reputation,
      mainThreadsCount: mainThreadsCount,
      be_light_count: be_light_count,
      fansCount: fansCount,
      recommendCount: recommendCount,
      follow_count: follow_count,
      beRecommendCount: beRecommendCount,
      bbs_favorite_count: bbs_favorite_count,
      replyCount: replyCount,
      bbsUserLevelPercent: bbsUserLevelPercent,
      level: level,
      bbsUserLevel: bbsUserLevel,
      bbsUserLevelFormatedStr: bbsUserLevelFormatedStr,
      birth: birth,
      gender: gender,
      location: location,
      registerTimeStr: registerTimeStr,
      bbs_follow_url: bbs_follow_url,
      avatarUrl: avatarUrl,
      gaussAvatarUrl: gaussAvatarUrl,
      nextPage: nextPage,
      env: env,
      tabKey: tabKey,
    );
  }

  // Map<String, dynamic> toJson() => _$AuthorHomeToJson(this);

  static bool _intToBool(dynamic value) => value == 1;
  static int _boolToInt(bool value) => value ? 1 : 0;

  static Gender _intToGender(dynamic value) {
    switch (value) {
      case 0:
        return Gender.female;
      case 1:
        return Gender.male;
      case 2:
      default:
        return Gender.unknown;
    }
  }

  static int _genderToInt(Gender gender) {
    switch (gender) {
      case Gender.female:
        return 0;
      case Gender.male:
        return 1;
      case Gender.unknown:
        return 2;
    }
  }

  static FollowStatus _intToFollowStatus(dynamic value) {
    switch (value) {
      case 2:
        return FollowStatus.following;
      case -1:
        return FollowStatus.notFollowed;
      default:
        return FollowStatus.self;
    }
  }

  static int _followStatusToInt(FollowStatus status) {
    switch (status) {
      case FollowStatus.following:
        return 2;
      case FollowStatus.notFollowed:
        return -1;
      case FollowStatus.self:
        return -1;
    }
  }
}

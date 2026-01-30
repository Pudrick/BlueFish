import 'package:json_annotation/json_annotation.dart';

import 'author_home_thread_title.dart';

part 'author_home.g.dart';

enum FollowStatus { following, notFollowed, self }

enum Gender { female, male, notSet }

@JsonSerializable()
class AuthorHome {
  // TODO: what is this used for?
  late bool isLogin;

  final String bbs_follow_url;

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
  final String avatarUrl;
  final bool be_follow_status;
  final int mainThreadsRecommendsCount;

  @JsonKey(fromJson: _intToGender, toJson: _genderToInt)
  final Gender gender;

  // do not know what does this means
  final String? banStatus;
  final int puid;

  @JsonKey(name: 'header_back')
  final String gaussAvatarUrl;

  final String nickname;

  @JsonKey(name: 'is_self', fromJson: _intToBool, toJson: _boolToInt)
  final bool isSelf;

  @JsonKey(name: 'reg_time_str')
  final String registerTimeStr;

  // what's this?
  final int bbs_favorite_count;

  @JsonKey(name: 'bbs_post_count')
  final int replyCount;
  final String location;

  // ... and what're these?
  final bool nextPage;
  final String env;
  final String tabKey;
  final List<AuthorHomeThreadTitle> threads;

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
    required this.mainThreadsRecommendsCount,
    required this.gender,
    this.banStatus,
    required this.puid,
    required this.gaussAvatarUrl,
    required this.nickname,
    required this.isSelf,
    required this.registerTimeStr,
    required this.bbs_favorite_count,
    required this.replyCount,
    required this.location,
    required this.nextPage,
    required this.env,
    required this.tabKey,
    required this.threads,
    required this.euid,
  });

  static int _getReputationNum(Map<String, dynamic> json) {
    return json['value'] as int;
  }

  factory AuthorHome.fromJson(Map<String, dynamic> json) =>
      _$AuthorHomeFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorHomeToJson(this);

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
        return Gender.notSet;
    }
  }

  static int _genderToInt(Gender gender) {
    switch (gender) {
      case Gender.female:
        return 0;
      case Gender.male:
        return 1;
      case Gender.notSet:
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

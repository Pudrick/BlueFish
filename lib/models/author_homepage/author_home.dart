import 'package:bluefish/models/author_homepage/author_home_thread_list.dart';
import 'package:json_annotation/json_annotation.dart';

import 'author_home_thread_title.dart';

// part 'author_home.g.dart';

enum FollowStatus { following, notFollowed, self }

enum Gender { female, male, unknown }

@JsonSerializable()
class AuthorHome {
  // TODO: what is this used for?
  late bool isLogin;

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
  AuthorHomeThreadList threads;

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
    required this.threads,
    required this.euid,
  });

  static int _getReputationNum(Map<String, dynamic> json) {
    return json['value'] as int;
  }

  // factory AuthorHome.fromJson(Map<String, dynamic> json) =>
  //     AuthorHomeFromJson(json);

static AuthorHome authorHomeFromJson(Map<String, dynamic> json) {
  final card = json['cardInfoData'] as Map<String, dynamic>;

  return AuthorHome(
    bbs_follow_url: Uri.parse(card['bbs_follow_url'] as String),
    followStatus: AuthorHome._intToFollowStatus(card['follow_status']),
    reputation: AuthorHome._getReputationNum(
      card['reputation'] as Map<String, dynamic>,
    ),
    mainThreadsCount: (card['bbs_msg_count'] as num).toInt(),
    be_light_count: (card['be_light_count'] as num).toInt(),
    bbsUserLevelPercent: (card['bbsUserLevelPercent'] as num).toDouble(),
    level: (card['level'] as num).toInt(),
    birth: card['birth'] as String?,
    fansCount: (card['be_follow_count'] as num).toInt(),
    bbsUserLevel: card['bbsUserLevel'] as String,
    bbsUserLevelFormatedStr: card['bbsUserLevelDesc'] as String,
    recommendCount: (card['bbs_recommend_count'] as num).toInt(),
    follow_count: (card['follow_count'] as num).toInt(),
    avatarUrl: Uri.parse(card['header'] as String),

    be_follow_status:
        (card['be_follow_status'] as int) == -1 ? false : true,
    beRecommendCount:
        (card['be_recommend_count'] as num).toInt(),
    gender: AuthorHome._intToGender(card['gender']),
    banStatus: card['banStatus'] as String?,
    puid: (card['puid'] as num).toInt(),
    gaussAvatarUrl: Uri.parse(card['header_back'] as String),
    nickname: card['nickname'] as String,
    isSelf: AuthorHome._intToBool(card['is_self']),
    registerTimeStr: card['reg_time_str'] as String,

    bbs_favorite_count:
        (card['bbs_favorite_count'] as num?)?.toInt(),

    replyCount: (card['bbs_post_count'] as num).toInt(),
    location: card['location'] as String,
    nextPage: json['nextPage'] as bool,
    env: json['env'] as String,
    tabKey: json['tabKey'] as String,

    euid: json['euid'] as String,
    
    // keep empty here, fill it later via API.
    threads: AuthorHomeThreadList(authorEuid: json['euid'] as String),
  )..isLogin = json['isLogin'] as bool;
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

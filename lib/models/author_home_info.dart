import './author_home_thread_title.dart';

enum FollowStatus {following, notFollowed, self}

enum Gender {female, male, notSet}

class AuthorHomeInfo {
  // TODO: what is this used for?
  late bool isLogin;

  final String bbs_follow_url;

  // -1 for not followed(include self), 2 for followed
  final FollowStatus follow_status;
  final int reputation;

  // main threads count
  final int mainThreadsCount;
  final int be_light_count;
  final double bbsUserLevelPercent;

  // not the level number that in mainpage. do not use this.
  final int level;
  final String? birth;
  final int fansCount;

  // this is the mainpage user level.
  final String bbsUserLevel;
  final String bbsUserLevelFormatedStr;
  final int be_recommend_count;
  final int follow_count;
  final String avatarUrl;
  final bool be_follow_status;
  final int mainThreadsRecommendsCount;
  final Gender gender;

  // do not know what does this means
  final String? banStatus;
  final int puid;
  final String GaussAvatarUrl;
  final String nickname;
  final bool is_self;
  final String registerTimeStr;

  // what's this?
  final int bbs_favorite_count;

  final int ReplyCount;
  final String location;
}
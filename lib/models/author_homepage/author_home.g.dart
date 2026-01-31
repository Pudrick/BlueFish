// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// AuthorHome _$AuthorHomeFromJson(Map<String, dynamic> json) => AuthorHome(
//   bbs_follow_url: json['bbs_follow_url'] as String,
//   followStatus: AuthorHome._intToFollowStatus(json['follow_status']),
//   reputation: AuthorHome._getReputationNum(
//     json['reputation'] as Map<String, dynamic>,
//   ),
//   mainThreadsCount: (json['bbs_msg_count'] as num).toInt(),
//   be_light_count: (json['be_light_count'] as num).toInt(),
//   bbsUserLevelPercent: (json['bbsUserLevelPercent'] as num).toDouble(),
//   level: (json['level'] as num).toInt(),
//   birth: json['birth'] as String?,
//   fansCount: (json['be_follow_count'] as num).toInt(),
//   bbsUserLevel: json['bbsUserLevel'] as String,
//   bbsUserLevelFormatedStr: json['bbsUserLevelDesc'] as String,
//   recommendCount: (json['bbs_recommend_count'] as num).toInt(),
//   follow_count: (json['follow_count'] as num).toInt(),
//   avatarUrl: json['avatarUrl'] as String,
//   be_follow_status: json['be_follow_status'] as bool,
//   mainThreadsRecommendsCount: (json['mainThreadsRecommendsCount'] as num)
//       .toInt(),
//   gender: AuthorHome._intToGender(json['gender']),
//   banStatus: json['banStatus'] as String?,
//   puid: (json['puid'] as num).toInt(),
//   gaussAvatarUrl: json['header_back'] as String,
//   nickname: json['nickname'] as String,
//   isSelf: AuthorHome._intToBool(json['is_self']),
//   registerTimeStr: json['reg_time_str'] as String,
//   bbs_favorite_count: (json['bbs_favorite_count'] as num).toInt(),
//   replyCount: (json['bbs_post_count'] as num).toInt(),
//   location: json['location'] as String,
//   nextPage: json['nextPage'] as bool,
//   env: json['env'] as String,
//   tabKey: json['tabKey'] as String,
//   threads: (json['threads'] as List<dynamic>)
//       .map((e) => AuthorHomeThreadTitle.fromJson(e as Map<String, dynamic>))
//       .toList(),
//   euid: json['euid'] as String,
// )..isLogin = json['isLogin'] as bool;

Map<String, dynamic> _$AuthorHomeToJson(AuthorHome instance) =>
    <String, dynamic>{
      'isLogin': instance.isLogin,
      'bbs_follow_url': instance.bbs_follow_url,
      'follow_status': AuthorHome._followStatusToInt(instance.followStatus),
      'reputation': instance.reputation,
      'bbs_msg_count': instance.mainThreadsCount,
      'be_light_count': instance.be_light_count,
      'bbsUserLevelPercent': instance.bbsUserLevelPercent,
      'level': instance.level,
      'birth': instance.birth,
      'be_follow_count': instance.fansCount,
      'bbsUserLevel': instance.bbsUserLevel,
      'bbsUserLevelDesc': instance.bbsUserLevelFormatedStr,
      'bbs_recommend_count': instance.recommendCount,
      'follow_count': instance.follow_count,
      'avatarUrl': instance.avatarUrl,
      'be_follow_status': instance.be_follow_status,
      'mainThreadsRecommendsCount': instance.mainThreadsRecommendsCount,
      'gender': AuthorHome._genderToInt(instance.gender),
      'banStatus': instance.banStatus,
      'puid': instance.puid,
      'header_back': instance.gaussAvatarUrl,
      'nickname': instance.nickname,
      'is_self': AuthorHome._boolToInt(instance.isSelf),
      'reg_time_str': instance.registerTimeStr,
      'bbs_favorite_count': instance.bbs_favorite_count,
      'bbs_post_count': instance.replyCount,
      'location': instance.location,
      'nextPage': instance.nextPage,
      'env': instance.env,
      'tabKey': instance.tabKey,
      'threads': instance.threads,
      'euid': instance.euid,
    };

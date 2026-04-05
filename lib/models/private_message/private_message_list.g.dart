// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_message_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateMessageList _$PrivateMessageListFromJson(Map<String, dynamic> json) =>
    PrivateMessageList(
      pageInfo: PrivateMessageListPageInfo.fromJson(
        json['page'] as Map<String, dynamic>,
      ),
      messagePeeks:
          (json['dataList'] as List<dynamic>?)
              ?.map(
                (e) => PrivateMessagePeek.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$PrivateMessageListToJson(PrivateMessageList instance) =>
    <String, dynamic>{
      'page': instance.pageInfo,
      'dataList': instance.messagePeeks,
    };

PrivateMessagePeek _$PrivateMessagePeekFromJson(Map<String, dynamic> json) =>
    PrivateMessagePeek(
      sid: (json['sid'] as num).toInt(),
      puid: (json['puid'] as num).toInt(),
      lastMessagePeek: json['content'] as String,
      isSystemInt: (json['isSystem'] as num).toInt(),
      isBlockInt: (json['isBlock'] as num).toInt(),
      unReadInt: (json['unread'] as num).toInt(),
      lastMessageTimeStamp: (json['lastTime'] as num).toInt(),
      nickName: json['nickName'] as String,
      avatarUrlStr: json['headerPic'] as String,
      certIconUrlStr: json['certIconUrl'] as String?,
    );

Map<String, dynamic> _$PrivateMessagePeekToJson(PrivateMessagePeek instance) =>
    <String, dynamic>{
      'sid': instance.sid,
      'puid': instance.puid,
      'content': instance.lastMessagePeek,
      'isSystem': instance.isSystemInt,
      'isBlock': instance.isBlockInt,
      'unread': instance.unReadInt,
      'lastTime': instance.lastMessageTimeStamp,
      'nickName': instance.nickName,
      'headerPic': instance.avatarUrlStr,
      'certIconUrl': instance.certIconUrlStr,
    };

PrivateMessageListPageInfo _$PrivateMessageListPageInfoFromJson(
  Map<String, dynamic> json,
) => PrivateMessageListPageInfo(
  pageNum: (json['pageNum'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalMessages: (json['total'] as num).toInt(),
  isEndNum: (json['isEnd'] as num).toInt(),
  nextPage: (json['nextPage'] as num).toInt(),
  totalPage: (json['totalPage'] as num).toInt(),
);

Map<String, dynamic> _$PrivateMessageListPageInfoToJson(
  PrivateMessageListPageInfo instance,
) => <String, dynamic>{
  'pageNum': instance.pageNum,
  'pageSize': instance.pageSize,
  'total': instance.totalMessages,
  'isEnd': instance.isEndNum,
  'nextPage': instance.nextPage,
  'totalPage': instance.totalPage,
};

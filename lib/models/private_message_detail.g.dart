// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_message_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateMessageDetail _$PrivateMessageDetailFromJson(
  Map<String, dynamic> json,
) => PrivateMessageDetail(
  isSystemInt: (json['isSystem'] as num).toInt(),
  unReadInt: (json['unread'] as num).toInt(),
  isBanInt: (json['isban'] as num).toInt(),
  messages:
      (json['dataList'] as List<dynamic>?)
          ?.map((e) => SinglePrivateMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  loginPuid: (json['loginPuid'] as num).toInt(),
  pageInfo: PrivateMessagePageInfo.fromJson(
    json['page'] as Map<String, dynamic>,
  ),
  interval: (json['interval'] as num).toInt(),
);

Map<String, dynamic> _$PrivateMessageDetailToJson(
  PrivateMessageDetail instance,
) => <String, dynamic>{
  'isSystem': instance.isSystemInt,
  'unread': instance.unReadInt,
  'isban': instance.isBanInt,
  'dataList': instance.messages,
  'loginPuid': instance.loginPuid,
  'page': instance.pageInfo,
  'interval': instance.interval,
};

PrivateMessagePageInfo _$PrivateMessagePageInfoFromJson(
  Map<String, dynamic> json,
) => PrivateMessagePageInfo(
  pageNum: (json['pageNum'] as num).toInt(),
  pageSize: (json['pageSize'] as num).toInt(),
  totalMessagesNum: (json['total'] as num).toInt(),
  isEndInt: (json['isEnd'] as num).toInt(),
  nextPage: (json['nextPage'] as num).toInt(),
  totalPage: (json['totalPage'] as num).toInt(),
);

Map<String, dynamic> _$PrivateMessagePageInfoToJson(
  PrivateMessagePageInfo instance,
) => <String, dynamic>{
  'pageNum': instance.pageNum,
  'pageSize': instance.pageSize,
  'total': instance.totalMessagesNum,
  'isEnd': instance.isEndInt,
  'nextPage': instance.nextPage,
  'totalPage': instance.totalPage,
};

SinglePrivateMessage _$SinglePrivateMessageFromJson(
  Map<String, dynamic> json,
) => SinglePrivateMessage(
  pmid: (json['pmid'] as num).toInt(),
  puid: (json['puid'] as num).toInt(),
  content: json['content'] as String,
  createTimeStamp: (json['createTime'] as num).toInt(),
  allowLinkInt: (json['allowLink'] as num).toInt(),
  nickName: json['nickName'] as String,
  avatarUrlStr: json['headerPic'] as String,
  type: (json['type'] as num).toInt(),
  cardPm: json['cardPm'] == null
      ? null
      : CardPm.fromJson(json['cardPm'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SinglePrivateMessageToJson(
  SinglePrivateMessage instance,
) => <String, dynamic>{
  'pmid': instance.pmid,
  'puid': instance.puid,
  'content': instance.content,
  'createTime': instance.createTimeStamp,
  'allowLink': instance.allowLinkInt,
  'nickName': instance.nickName,
  'headerPic': instance.avatarUrlStr,
  'type': instance.type,
  'cardPm': instance.cardPm,
};

CardPmImage _$CardPmImageFromJson(Map<String, dynamic> json) => CardPmImage(
  urlStr: json['url'] as String,
  height: (json['height'] as num).toInt(),
  width: (json['width'] as num).toInt(),
  isGifInt: (json['isGif'] as num).toInt(),
);

Map<String, dynamic> _$CardPmImageToJson(CardPmImage instance) =>
    <String, dynamic>{
      'url': instance.urlStr,
      'height': instance.height,
      'width': instance.width,
      'isGif': instance.isGifInt,
    };

CardPmRedirection _$CardPmRedirectionFromJson(Map<String, dynamic> json) =>
    CardPmRedirection(
      urlStr: json['url'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$CardPmRedirectionToJson(CardPmRedirection instance) =>
    <String, dynamic>{'url': instance.urlStr, 'text': instance.text};

CardPm _$CardPmFromJson(Map<String, dynamic> json) => CardPm(
  title: json['title'] as String,
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => CardPmImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  videos: json['videos'],
  intro: json['intro'] as String,
  redirection: CardPmRedirection.fromJson(
    json['redirection'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CardPmToJson(CardPm instance) => <String, dynamic>{
  'title': instance.title,
  'images': instance.images,
  'videos': instance.videos,
  'intro': instance.intro,
  'redirection': instance.redirection,
};

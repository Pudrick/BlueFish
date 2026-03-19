import 'package:json_annotation/json_annotation.dart';

part 'private_message_detail.g.dart';

@JsonSerializable()
class PrivateMessageDetail {
  @JsonKey(name: 'isSystem')
  final int isSystemInt;
  bool get isSystem => (isSystemInt != 0);

  @JsonKey(name: 'unread')
  final int unReadInt;
  bool get unread => (unReadInt != 0);

  @JsonKey(name: 'isban')
  final int isBanInt;
  bool get isBanned => (isBanInt != 0);

  @JsonKey(name: 'dataList', defaultValue: <SinglePrivateMessage>[])
  final List<SinglePrivateMessage> messages;

  final int loginPuid;

  @JsonKey(name: 'page')
  final PrivateMessagePageInfo pageInfo;

  final int interval;

  PrivateMessageDetail({
    required this.isSystemInt,
    required this.unReadInt,
    required this.isBanInt,
    required this.messages,
    required this.loginPuid,
    required this.pageInfo,
    required this.interval,
  });

  factory PrivateMessageDetail.fromJson(Map<String, dynamic> json) =>
      _$PrivateMessageDetailFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateMessageDetailToJson(this);
}

@JsonSerializable()
class PrivateMessagePageInfo {
  final int pageNum;
  final int pageSize;

  @JsonKey(name: 'total')
  final int totalMessagesNum;

  @JsonKey(name: 'isEnd')
  final int isEndInt;
  bool get isEnd => (isEndInt != 0);

  final int nextPage;
  final int totalPage;

  PrivateMessagePageInfo({
    required this.pageNum,
    required this.pageSize,
    required this.totalMessagesNum,
    required this.isEndInt,
    required this.nextPage,
    required this.totalPage,
  });

  factory PrivateMessagePageInfo.fromJson(Map<String, dynamic> json) =>
      _$PrivateMessagePageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateMessagePageInfoToJson(this);
}

// TODO: message with images
@JsonSerializable()
class SinglePrivateMessage {
  final int pmid;
  final int puid;

  // when image contained, it is an html.
  final String content;

  @JsonKey(name: 'createTime')
  final int createTimeStamp;
  DateTime get createTime =>
      DateTime.fromMillisecondsSinceEpoch(createTimeStamp * 1000);

  @JsonKey(name: 'allowLink')
  final int allowLinkInt;
  bool get allowLink => (allowLinkInt != 0);

  final String nickName;

  @JsonKey(name: 'headerPic')
  final String avatarUrlStr;
  Uri get avatarUrl => Uri.parse(avatarUrlStr);

  // type == 1 means card? or system?
  final int type;
  final CardPm? cardPm;

  SinglePrivateMessage({
    required this.pmid,
    required this.puid,
    required this.content,
    required this.createTimeStamp,
    required this.allowLinkInt,
    required this.nickName,
    required this.avatarUrlStr,
    required this.type,
    this.cardPm,
  });

  factory SinglePrivateMessage.fromJson(Map<String, dynamic> json) =>
      _$SinglePrivateMessageFromJson(json);
  Map<String, dynamic> toJson() => _$SinglePrivateMessageToJson(this);
}

@JsonSerializable()
class CardPmImage {
  @JsonKey(name: 'url')
  final String urlStr;
  Uri get imageUrl => Uri.parse(urlStr);

  final int height;
  final int width;

  @JsonKey(name: 'isGif')
  final int isGifInt;
  bool get isGif => (isGifInt != 0);

  CardPmImage({
    required this.urlStr,
    required this.height,
    required this.width,
    required this.isGifInt,
  });

  factory CardPmImage.fromJson(Map<String, dynamic> json) =>
      _$CardPmImageFromJson(json);
  Map<String, dynamic> toJson() => _$CardPmImageToJson(this);
}

@JsonSerializable()
class CardPmRedirection {
  @JsonKey(name: 'url')
  final String urlStr;
  Uri get redirUrl => Uri.parse(urlStr);
  final String text;

  CardPmRedirection({required this.urlStr, required this.text});

  factory CardPmRedirection.fromJson(Map<String, dynamic> json) =>
      _$CardPmRedirectionFromJson(json);
  Map<String, dynamic> toJson() => _$CardPmRedirectionToJson(this);
}

@JsonSerializable()
class CardPm {
  final String title;

  @JsonKey(defaultValue: <CardPmImage>[])
  final List<CardPmImage> images;

  //TODO: make sure the data structure here. but is it really available??
  final dynamic videos;
  final String intro;
  final CardPmRedirection redirection;

  CardPm({
    required this.title,
    required this.images,
    this.videos,
    required this.intro,
    required this.redirection,
  });

  factory CardPm.fromJson(Map<String, dynamic> json) => _$CardPmFromJson(json);
  Map<String, dynamic> toJson() => _$CardPmToJson(this);
}

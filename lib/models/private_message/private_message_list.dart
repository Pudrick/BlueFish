import 'package:json_annotation/json_annotation.dart';

part 'private_message_list.g.dart';

@JsonSerializable()
class PrivateMessageList {
  @JsonKey(name: 'page')
  final PrivateMessageListPageInfo pageInfo;

  // this List may be empty/null?
  @JsonKey(name: 'dataList', defaultValue: <PrivateMessagePeek>[])
  final List<PrivateMessagePeek> messagePeeks;

  PrivateMessageList({required this.pageInfo, required this.messagePeeks});

  factory PrivateMessageList.fromJson(Map<String, dynamic> json) =>
      _$PrivateMessageListFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateMessageListToJson(this);
}

@JsonSerializable()
class PrivateMessagePeek {
  final int sid;
  final int puid;
  @JsonKey(name: 'content')
  final String lastMessagePeek;
  @JsonKey(name: 'isSystem')
  final int isSystemInt;
  bool get isSystem => (isSystemInt != 0);
  @JsonKey(name: 'isBlock')
  final int isBlockInt;
  bool get isBlocked => (isBlockInt != 0);
  @JsonKey(name: 'unread')
  final int unReadInt;
  bool get isUnread => (unReadInt != 0);
  @JsonKey(name: 'lastTime')
  final int lastMessageTimeStamp;
  DateTime get lastMessageTime =>
      DateTime.fromMillisecondsSinceEpoch(lastMessageTimeStamp * 1000);
  final String nickName;
  @JsonKey(name: 'headerPic')
  final String avatarUrlStr;
  Uri get avatarUrl => Uri.parse(avatarUrlStr);
  @JsonKey(name: 'certIconUrl')
  final String? certIconUrlStr;
  Uri? get certIconUrl =>
      certIconUrlStr == null ? null : Uri.parse(certIconUrlStr!);

  PrivateMessagePeek({
    required this.sid,
    required this.puid,
    required this.lastMessagePeek,
    required this.isSystemInt,
    required this.isBlockInt,
    required this.unReadInt,
    required this.lastMessageTimeStamp,
    required this.nickName,
    required this.avatarUrlStr,
    this.certIconUrlStr,
  });

  factory PrivateMessagePeek.fromJson(Map<String, dynamic> json) =>
      _$PrivateMessagePeekFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateMessagePeekToJson(this);
}

@JsonSerializable()
class PrivateMessageListPageInfo {
  final int pageNum;
  final int pageSize;

  @JsonKey(name: 'total')
  final int totalMessages;
  @JsonKey(name: 'isEnd')
  final int isEndNum;
  bool get isEnd => (isEndNum != 0);

  // is this truly necessary???
  final int nextPage;
  final int totalPage;

  PrivateMessageListPageInfo({
    required this.pageNum,
    required this.pageSize,
    required this.totalMessages,
    required this.isEndNum,
    required this.nextPage,
    required this.totalPage,
  });

  factory PrivateMessageListPageInfo.fromJson(Map<String, dynamic> json) =>
      _$PrivateMessageListPageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateMessageListPageInfoToJson(this);
}

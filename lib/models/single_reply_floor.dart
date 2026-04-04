import 'package:bluefish/models/author.dart';
import 'package:bluefish/models/floor_meta.dart';
import 'package:bluefish/models/model_parsing.dart';

enum ReplyVisibility {
  visible,
  deleted,
  selfDeleted,
  hidden,
  auditing;

  factory ReplyVisibility.fromJson(Map<String, dynamic> json) {
    final isDelete = parseBool(json['isDelete']);
    final isSelfDelete = parseBool(json['isSelfDelete']);
    final isAudit = parseBool(json['isAudit']);
    final isHidden = parseBool(json['isHidden']);

    if (isDelete) {
      return isSelfDelete
          ? ReplyVisibility.selfDeleted
          : ReplyVisibility.deleted;
    }

    if (isAudit) {
      return ReplyVisibility.auditing;
    }

    if (isHidden) {
      return ReplyVisibility.hidden;
    }

    return ReplyVisibility.visible;
  }

  bool get canDisplay => this == ReplyVisibility.visible;

  String get hiddenReasonText => switch (this) {
    ReplyVisibility.deleted => '该内容已被删除',
    ReplyVisibility.selfDeleted => '该内容已被作者删除',
    ReplyVisibility.hidden => '该内容已被隐藏',
    ReplyVisibility.auditing => '该内容正在卡审核',
    ReplyVisibility.visible => '该内容不知道为什么不可显示',
  };
}

abstract interface class ReplyContent {
  String get pid;
  String get contentHtml;
  FloorMeta get meta;
  ReplyVisibility get visibility;
  // Quoted replies can also be authored by the OP, so the UI still needs this flag.
  bool get isOp;
  ReplyQuote? get quote;
}

class ReplyQuote implements ReplyContent {
  @override
  final String pid;

  @override
  final String contentHtml;

  @override
  final FloorMeta meta;

  @override
  final ReplyVisibility visibility;

  @override
  final bool isOp;

  @override
  final ReplyQuote? quote;

  const ReplyQuote({
    required this.pid,
    required this.contentHtml,
    required this.meta,
    required this.visibility,
    required this.isOp,
    this.quote,
  });

  bool get hasQuote => quote != null;

  factory ReplyQuote.fromJson(Map<String, dynamic> json) {
    return ReplyQuote(
      pid: parseString(json['pid']),
      contentHtml: parseString(json['content']),
      meta: FloorMeta.fromJson(json, author: _parseReplyAuthor(json)),
      visibility: ReplyVisibility.fromJson(json),
      isOp: parseBool(json['isStarter']),
      quote: _parseQuote(json['quote']),
    );
  }
}

class SingleReplyFloor implements ReplyContent {
  @override
  final String pid;
  final String authorId;
  final int? serverFloorNumber;
  final int lightCount;
  // The source JSON uses `isStarter` to indicate whether the reply author is the OP.
  @override
  final bool isOp;
  final int replyNum;
  // Often null in the lights list; exact semantics still need confirmation.
  final int? userBanned;
  final int? hidePost;

  @override
  final String contentHtml;

  final String? replyVideo;
  final String? replyVideoCover;

  @override
  final FloorMeta meta;

  @override
  final ReplyVisibility visibility;

  @override
  final ReplyQuote? quote;

  const SingleReplyFloor({
    required this.pid,
    required this.authorId,
    required this.serverFloorNumber,
    required this.lightCount,
    required this.isOp,
    required this.replyNum,
    required this.userBanned,
    required this.hidePost,
    required this.contentHtml,
    required this.replyVideo,
    required this.replyVideoCover,
    required this.meta,
    required this.visibility,
    required this.quote,
  });

  bool get hasQuote => quote != null;

  bool get canDisplay => visibility.canDisplay;

  int resolveFloorNumber({
    required int currentPage,
    required int repliesPerPage,
    required int indexInPage,
  }) {
    final fallbackFloorNumber =
        ((currentPage - 1) * repliesPerPage) + indexInPage + 1;
    final resolvedServerFloorNumber = serverFloorNumber;
    if (resolvedServerFloorNumber != null && resolvedServerFloorNumber > 0) {
      return resolvedServerFloorNumber;
    }
    return fallbackFloorNumber;
  }

  factory SingleReplyFloor.fromJson(Map<String, dynamic> json) {
    return SingleReplyFloor(
      pid: parseString(json['pid']),
      authorId: parseString(json['authorId']),
      serverFloorNumber: _parseServerFloorNumber(json),
      lightCount: parseInt(json['count']),
      isOp: parseBool(json['isStarter']),
      replyNum: parseInt(json['replyNum']),
      // These fields may be absent in some reply payloads.
      userBanned: parseNullableInt(json['userBanned']),
      hidePost: parseNullableInt(json['hidePost']),
      contentHtml: parseString(json['content']),
      replyVideo: parseNullableString(json['video']),
      replyVideoCover: parseNullableString(json['videoCover']),
      meta: FloorMeta.fromJson(json, author: _parseReplyAuthor(json)),
      visibility: ReplyVisibility.fromJson(json),
      quote: _parseQuote(json['quote']),
    );
  }
}

Author _parseReplyAuthor(Map<String, dynamic> json) {
  // These flags were historically observed on quoted reply payloads,
  // but we keep parsing them here so Author stays structurally consistent.
  return Author.forReply(
    parseMap(json['author']),
    isBlacked: parseBool(json['isBlacked']),
    isAdmin: parseBool(json['isAdmin']),
  );
}

ReplyQuote? _parseQuote(Object? value) {
  if (value is! Map) {
    return null;
  }

  final quoteJson = Map<String, dynamic>.from(value);
  if (!quoteJson.containsKey('pid')) {
    return null;
  }

  return ReplyQuote.fromJson(quoteJson);
}

int? _parseServerFloorNumber(Map<String, dynamic> json) {
  const candidateKeys = <String>[
    'floor',
    'floorNum',
    'floorNo',
    'postFloor',
    'louNum',
    'replyFloor',
    'sequence',
  ];

  for (final key in candidateKeys) {
    final value = parseNullableInt(json[key]);
    if (value != null && value > 0) {
      return value;
    }
  }

  return null;
}

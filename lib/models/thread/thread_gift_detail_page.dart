import 'package:bluefish/models/model_parsing.dart';

class ThreadGiftDetailItem {
  final String giftIconUrl;
  final String giftId;
  final int giftNum;
  final String giverAvatarUrl;
  final String giverName;
  final String giverPuid;
  final String pid;
  final String tid;

  const ThreadGiftDetailItem({
    required this.giftIconUrl,
    required this.giftId,
    required this.giftNum,
    required this.giverAvatarUrl,
    required this.giverName,
    required this.giverPuid,
    required this.pid,
    required this.tid,
  });

  static ThreadGiftDetailItem? tryFromJson(Map<String, dynamic> json) {
    final giftId = parseString(json['giftId']).trim();
    if (giftId.isEmpty) {
      return null;
    }

    final giverName = parseString(json['giveName']).trim();

    return ThreadGiftDetailItem(
      giftIconUrl: parseString(json['giftIcon']).trim(),
      giftId: giftId,
      giftNum: parseInt(json['giftNum']),
      giverAvatarUrl: parseString(json['giveHeader']).trim(),
      giverName: giverName.isEmpty ? '匿名用户' : giverName,
      giverPuid: parseString(json['givePuid']).trim(),
      pid: parseString(json['pid']).trim(),
      tid: parseString(json['tid']).trim(),
    );
  }
}

class ThreadGiftDetailPage {
  final List<ThreadGiftDetailItem> list;
  final bool nextPage;
  final int total;
  final int totalPage;

  const ThreadGiftDetailPage({
    required this.list,
    required this.nextPage,
    required this.total,
    required this.totalPage,
  });

  bool get hasNextPage => nextPage;

  factory ThreadGiftDetailPage.fromJson(Map<String, dynamic> json) {
    final data = parseMap(json['data']);
    final rawList = data['list'];

    final parsedItems = <ThreadGiftDetailItem>[];
    if (rawList is List) {
      for (final entry in rawList) {
        if (entry is! Map) {
          continue;
        }

        final item = ThreadGiftDetailItem.tryFromJson(
          Map<String, dynamic>.from(entry),
        );
        if (item != null) {
          parsedItems.add(item);
        }
      }
    }

    return ThreadGiftDetailPage(
      list: List<ThreadGiftDetailItem>.unmodifiable(parsedItems),
      nextPage: parseBool(data['nextPage']),
      total: parseInt(data['total']),
      totalPage: parseInt(data['totalPage']),
    );
  }
}

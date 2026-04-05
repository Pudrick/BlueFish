import 'package:bluefish/models/model_parsing.dart';
import 'package:bluefish/models/single_reply_floor.dart';

class ThreadReplyPage {
  final List<SingleReplyFloor> replies;
  final int nextPage;

  const ThreadReplyPage({required this.replies, required this.nextPage});

  bool get hasNextPage => nextPage > 0;

  factory ThreadReplyPage.fromJson(Map<String, dynamic> json) {
    final data = parseMap(json['data']);
    final rawReplies = (data['list'] as List<dynamic>?) ?? const <dynamic>[];

    return ThreadReplyPage(
      replies: [
        for (final reply in rawReplies)
          SingleReplyFloor.fromJson(Map<String, dynamic>.from(reply as Map)),
      ],
      nextPage: parseInt(data['nextPage']),
    );
  }
}

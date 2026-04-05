import 'package:bluefish/models/mention/mention_reply.dart';
import 'package:bluefish/services/mention/mention_service.dart';

class MentionReplyService extends MentionService<MentionReply> {
  MentionReplyService()
    : super(apiPath: "getMentionedRemindList", fromJson: MentionReply.fromJson);
}

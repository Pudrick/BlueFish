// fully comes from vibe.

import 'package:bluefish/models/mention_reply.dart';
import 'package:bluefish/services/mention_reply_service.dart';
import 'package:bluefish/viewModels/mention_view_model.dart';

class MentionReplyViewModel extends MentionViewModel<MentionReply> {
  MentionReplyViewModel() : super(MentionReplyService());
}

import 'package:flutter/foundation.dart';

import 'composer_attachment.dart';
import 'quill_draft_utils.dart';

@immutable
class ReplyDraft {
  final List<Map<String, dynamic>> deltaJson;
  final List<ComposerAttachment> attachments;
  final String? bodyHtml;

  const ReplyDraft({
    required this.deltaJson,
    this.attachments = const <ComposerAttachment>[],
    this.bodyHtml,
  });

  factory ReplyDraft.empty() => ReplyDraft(deltaJson: emptyQuillDeltaJson());

  bool get hasPublishableContent {
    return !isQuillDeltaMeaningfullyEmpty(deltaJson) || attachments.isNotEmpty;
  }

  ReplyDraft copyWith({
    List<Map<String, dynamic>>? deltaJson,
    List<ComposerAttachment>? attachments,
    String? bodyHtml,
    bool clearBodyHtml = false,
  }) {
    return ReplyDraft(
      deltaJson: deltaJson ?? this.deltaJson,
      attachments: attachments ?? this.attachments,
      bodyHtml: clearBodyHtml ? null : bodyHtml ?? this.bodyHtml,
    );
  }
}

import 'package:flutter/foundation.dart';

import 'composer_attachment.dart';
import 'quill_draft_utils.dart';

@immutable
class RichTextComposerContent {
  final List<Map<String, dynamic>> deltaJson;
  final List<ComposerAttachment> attachments;
  final String? bodyHtml;

  const RichTextComposerContent({
    required this.deltaJson,
    this.attachments = const <ComposerAttachment>[],
    this.bodyHtml,
  });

  factory RichTextComposerContent.empty() =>
      RichTextComposerContent(deltaJson: emptyQuillDeltaJson());

  bool get hasPublishableContent {
    return !isQuillDeltaMeaningfullyEmpty(deltaJson) || attachments.isNotEmpty;
  }

  RichTextComposerContent copyWith({
    List<Map<String, dynamic>>? deltaJson,
    List<ComposerAttachment>? attachments,
    String? bodyHtml,
    bool clearBodyHtml = false,
  }) {
    return RichTextComposerContent(
      deltaJson: deltaJson ?? this.deltaJson,
      attachments: attachments ?? this.attachments,
      bodyHtml: clearBodyHtml ? null : bodyHtml ?? this.bodyHtml,
    );
  }

  RichTextComposerContent clearedBody() {
    return RichTextComposerContent.empty();
  }
}

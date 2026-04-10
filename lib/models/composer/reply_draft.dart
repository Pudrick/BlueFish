import 'package:flutter/foundation.dart';

import 'composer_attachment.dart';
import 'rich_text_composer_content.dart';

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

  factory ReplyDraft.empty() =>
      ReplyDraft.fromComposerContent(RichTextComposerContent.empty());

  factory ReplyDraft.fromComposerContent(RichTextComposerContent content) {
    return ReplyDraft(
      deltaJson: content.deltaJson,
      attachments: content.attachments,
      bodyHtml: content.bodyHtml,
    );
  }

  RichTextComposerContent get composerContent {
    return RichTextComposerContent(
      deltaJson: deltaJson,
      attachments: attachments,
      bodyHtml: bodyHtml,
    );
  }

  bool get hasPublishableContent {
    return composerContent.hasPublishableContent;
  }

  ReplyDraft copyWith({
    List<Map<String, dynamic>>? deltaJson,
    List<ComposerAttachment>? attachments,
    String? bodyHtml,
    bool clearBodyHtml = false,
  }) {
    return ReplyDraft.fromComposerContent(
      composerContent.copyWith(
        deltaJson: deltaJson,
        attachments: attachments,
        bodyHtml: bodyHtml,
        clearBodyHtml: clearBodyHtml,
      ),
    );
  }
}

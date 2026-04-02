import 'package:flutter/foundation.dart';

import 'composer_attachment.dart';
import 'composer_document.dart';

@immutable
class ReplyDraft {
  final ComposerDocument document;
  final List<ComposerAttachment> attachments;

  const ReplyDraft({
    required this.document,
    this.attachments = const <ComposerAttachment>[],
  });

  factory ReplyDraft.empty() =>
      ReplyDraft(document: ComposerDocument.withSingleParagraph());

  bool get hasPublishableContent {
    return !document.isEmpty ||
        attachments.any((attachment) => attachment.isReady);
  }

  ReplyDraft copyWith({
    ComposerDocument? document,
    List<ComposerAttachment>? attachments,
  }) {
    return ReplyDraft(
      document: document ?? this.document,
      attachments: attachments ?? this.attachments,
    );
  }
}

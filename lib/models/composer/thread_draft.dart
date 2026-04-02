import 'package:flutter/foundation.dart';

import 'composer_attachment.dart';
import 'composer_document.dart';

enum ThreadComposeMode { richText, videoOnly }

@immutable
sealed class ThreadDraft {
  final String title;

  const ThreadDraft({required this.title});
}

@immutable
class RichTextThreadDraft extends ThreadDraft {
  final ComposerDocument document;
  final List<ComposerAttachment> attachments;

  const RichTextThreadDraft({
    required super.title,
    required this.document,
    this.attachments = const <ComposerAttachment>[],
  });

  factory RichTextThreadDraft.empty() => RichTextThreadDraft(
    title: '',
    document: ComposerDocument.withSingleParagraph(),
  );

  bool get hasPublishableContent {
    return !document.isEmpty ||
        attachments.any((attachment) => attachment.isReady);
  }

  RichTextThreadDraft copyWith({
    String? title,
    ComposerDocument? document,
    List<ComposerAttachment>? attachments,
  }) {
    return RichTextThreadDraft(
      title: title ?? this.title,
      document: document ?? this.document,
      attachments: attachments ?? this.attachments,
    );
  }

  RichTextThreadDraft clearedBodyPreservingTitle() {
    return RichTextThreadDraft(
      title: title,
      document: ComposerDocument.withSingleParagraph(),
      attachments: const <ComposerAttachment>[],
    );
  }
}

@immutable
class VideoThreadDraft extends ThreadDraft {
  final ComposerAttachment? video;

  const VideoThreadDraft({required super.title, this.video});

  factory VideoThreadDraft.empty() => const VideoThreadDraft(title: '');

  bool get hasReadyVideo => video?.isReady ?? false;

  VideoThreadDraft copyWith({String? title, ComposerAttachment? video}) {
    return VideoThreadDraft(
      title: title ?? this.title,
      video: video ?? this.video,
    );
  }

  VideoThreadDraft clearedVideoPreservingTitle() {
    return VideoThreadDraft(title: title);
  }
}

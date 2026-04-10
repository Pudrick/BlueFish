import 'package:flutter/foundation.dart';

import 'composer_attachment.dart';
import 'rich_text_composer_content.dart';

enum ThreadComposeMode { richText, videoOnly }

@immutable
sealed class ThreadDraft {
  final String title;

  const ThreadDraft({required this.title});
}

@immutable
class RichTextThreadDraft extends ThreadDraft {
  final List<Map<String, dynamic>> deltaJson;
  final List<ComposerAttachment> attachments;
  final String? bodyHtml;

  const RichTextThreadDraft({
    required super.title,
    required this.deltaJson,
    this.attachments = const <ComposerAttachment>[],
    this.bodyHtml,
  });

  factory RichTextThreadDraft.empty() =>
      RichTextThreadDraft.fromComposerContent(
        title: '',
        content: RichTextComposerContent.empty(),
      );

  factory RichTextThreadDraft.fromComposerContent({
    required String title,
    required RichTextComposerContent content,
  }) {
    return RichTextThreadDraft(
      title: title,
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

  RichTextThreadDraft copyWith({
    String? title,
    List<Map<String, dynamic>>? deltaJson,
    List<ComposerAttachment>? attachments,
    String? bodyHtml,
    bool clearBodyHtml = false,
  }) {
    return RichTextThreadDraft.fromComposerContent(
      title: title ?? this.title,
      content: composerContent.copyWith(
        deltaJson: deltaJson,
        attachments: attachments,
        bodyHtml: bodyHtml,
        clearBodyHtml: clearBodyHtml,
      ),
    );
  }

  RichTextThreadDraft clearedBodyPreservingTitle() {
    return RichTextThreadDraft.fromComposerContent(
      title: title,
      content: composerContent.clearedBody(),
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

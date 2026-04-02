import 'package:flutter/foundation.dart';

import 'composer_attachment.dart';
import 'quill_draft_utils.dart';

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
      RichTextThreadDraft(title: '', deltaJson: emptyQuillDeltaJson());

  bool get hasPublishableContent {
    return !isQuillDeltaMeaningfullyEmpty(deltaJson) || attachments.isNotEmpty;
  }

  RichTextThreadDraft copyWith({
    String? title,
    List<Map<String, dynamic>>? deltaJson,
    List<ComposerAttachment>? attachments,
    String? bodyHtml,
    bool clearBodyHtml = false,
  }) {
    return RichTextThreadDraft(
      title: title ?? this.title,
      deltaJson: deltaJson ?? this.deltaJson,
      attachments: attachments ?? this.attachments,
      bodyHtml: clearBodyHtml ? null : bodyHtml ?? this.bodyHtml,
    );
  }

  RichTextThreadDraft clearedBodyPreservingTitle() {
    return RichTextThreadDraft(
      title: title,
      deltaJson: emptyQuillDeltaJson(),
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

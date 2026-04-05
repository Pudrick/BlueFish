import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bluefish/models/composer/reply_draft.dart';
import 'package:bluefish/models/composer/thread_draft.dart';

@immutable
class ComposerSubmissionReceipt {
  final String channel;
  final String summary;
  final DateTime submittedAt;

  const ComposerSubmissionReceipt({
    required this.channel,
    required this.summary,
    required this.submittedAt,
  });
}

abstract class ThreadPublishService {
  Future<ComposerSubmissionReceipt> publishReply(ReplyDraft draft);

  Future<ComposerSubmissionReceipt> publishRichTextThread(
    RichTextThreadDraft draft,
  );

  Future<ComposerSubmissionReceipt> publishVideoThread(VideoThreadDraft draft);
}

class StubThreadPublishService implements ThreadPublishService {
  const StubThreadPublishService();

  @override
  Future<ComposerSubmissionReceipt> publishReply(ReplyDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return ComposerSubmissionReceipt(
      channel: 'reply',
      summary: '回复草稿已通过 stub 服务提交',
      submittedAt: DateTime.now(),
    );
  }

  @override
  Future<ComposerSubmissionReceipt> publishRichTextThread(
    RichTextThreadDraft draft,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 480));
    return ComposerSubmissionReceipt(
      channel: 'thread.rich_text',
      summary: '图文主贴草稿已通过 stub 服务提交',
      submittedAt: DateTime.now(),
    );
  }

  @override
  Future<ComposerSubmissionReceipt> publishVideoThread(
    VideoThreadDraft draft,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 520));
    return ComposerSubmissionReceipt(
      channel: 'thread.video_only',
      summary: '视频主贴草稿已通过 stub 服务提交',
      submittedAt: DateTime.now(),
    );
  }
}

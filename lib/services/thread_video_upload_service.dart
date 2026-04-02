import 'dart:async';

import '../models/composer/composer_attachment.dart';

abstract class ThreadVideoUploadService {
  Future<ComposerAttachment> uploadVideo(ComposerAttachment attachment);
}

class StubThreadVideoUploadService implements ThreadVideoUploadService {
  const StubThreadVideoUploadService();

  @override
  Future<ComposerAttachment> uploadVideo(ComposerAttachment attachment) async {
    await Future<void>.delayed(const Duration(milliseconds: 760));
    return attachment.copyWith(
      uploadState: ComposerUploadState.uploaded,
      progress: 1,
      remoteUrl: 'stub://video/${attachment.id}',
      thumbnailUrl:
          attachment.thumbnailUrl ?? 'stub://video/${attachment.id}/cover',
    );
  }
}

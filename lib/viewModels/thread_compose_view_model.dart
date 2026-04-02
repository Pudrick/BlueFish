import 'package:flutter/foundation.dart';

import '../models/composer/composer_attachment.dart';
import '../models/composer/composer_document.dart';
import '../models/composer/thread_draft.dart';
import '../services/thread_publish_service.dart';
import '../services/thread_video_upload_service.dart';

class ThreadComposeViewModel extends ChangeNotifier {
  final ThreadPublishService _publishService;
  final ThreadVideoUploadService _videoUploadService;

  ThreadComposeMode _mode = ThreadComposeMode.richText;
  RichTextThreadDraft _richTextDraft = RichTextThreadDraft.empty();
  VideoThreadDraft _videoDraft = VideoThreadDraft.empty();
  bool _isSubmitting = false;
  String? _statusMessage;

  ThreadComposeViewModel({
    ThreadPublishService? publishService,
    ThreadVideoUploadService? videoUploadService,
  }) : _publishService = publishService ?? const StubThreadPublishService(),
       _videoUploadService =
           videoUploadService ?? const StubThreadVideoUploadService();

  ThreadComposeMode get mode => _mode;
  RichTextThreadDraft get richTextDraft => _richTextDraft;
  VideoThreadDraft get videoDraft => _videoDraft;
  bool get isSubmitting => _isSubmitting;
  String? get statusMessage => _statusMessage;

  bool get canPublish {
    if (_isSubmitting) {
      return false;
    }

    final hasTitle = currentTitle.trim().isNotEmpty;
    if (!hasTitle) {
      return false;
    }

    return switch (_mode) {
      ThreadComposeMode.richText => _richTextDraft.hasPublishableContent,
      ThreadComposeMode.videoOnly => _videoDraft.hasReadyVideo,
    };
  }

  String get currentTitle => _mode == ThreadComposeMode.richText
      ? _richTextDraft.title
      : _videoDraft.title;

  String get richTextPreviewHtml => _richTextDraft.document.toHtml();

  void updateTitle(String value) {
    if (_richTextDraft.title == value && _videoDraft.title == value) {
      return;
    }

    _richTextDraft = _richTextDraft.copyWith(title: value);
    _videoDraft = _videoDraft.copyWith(title: value);
    notifyListeners();
  }

  String? describeModeSwitch(ThreadComposeMode nextMode) {
    if (nextMode == _mode) {
      return null;
    }

    return switch (nextMode) {
      ThreadComposeMode.videoOnly when _richTextDraft.hasPublishableContent =>
        '切换到视频主贴会清空当前图文正文和附件占位。',
      ThreadComposeMode.richText when _videoDraft.video != null =>
        '切换到图文主贴会移除当前视频草稿。',
      _ => null,
    };
  }

  void setMode(
    ThreadComposeMode nextMode, {
    bool discardCurrentModeContent = false,
  }) {
    if (nextMode == _mode) {
      return;
    }

    final warning = describeModeSwitch(nextMode);
    if (warning != null && !discardCurrentModeContent) {
      return;
    }

    if (nextMode == ThreadComposeMode.videoOnly && warning != null) {
      _richTextDraft = _richTextDraft.clearedBodyPreservingTitle();
    }

    if (nextMode == ThreadComposeMode.richText && warning != null) {
      _videoDraft = _videoDraft.clearedVideoPreservingTitle();
    }

    _mode = nextMode;
    _statusMessage = null;
    notifyListeners();
  }

  void addParagraphBlock() {
    _richTextDraft = _richTextDraft.copyWith(
      document: _richTextDraft.document.append(ComposerParagraphBlock.empty()),
    );
    notifyListeners();
  }

  void addDetailsBlock() {
    _richTextDraft = _richTextDraft.copyWith(
      document: _richTextDraft.document.append(ComposerDetailsBlock.empty()),
    );
    notifyListeners();
  }

  void addImagePlaceholder() {
    final attachmentId = createComposerId('image-attachment');
    final imageAttachment = ComposerAttachment(
      id: attachmentId,
      type: ComposerAttachmentType.image,
      uploadState: ComposerUploadState.pending,
      label: '图片占位 ${_richTextDraft.attachments.length + 1}',
    );
    final imageBlock = ComposerImageBlock.placeholder(
      attachmentId: attachmentId,
    );

    _richTextDraft = _richTextDraft.copyWith(
      document: _richTextDraft.document.append(imageBlock),
      attachments: <ComposerAttachment>[
        ..._richTextDraft.attachments,
        imageAttachment,
      ],
    );
    notifyListeners();
  }

  void updateParagraphText(String blockId, String value) {
    final block = _richTextDraft.document.findBlock<ComposerParagraphBlock>(
      blockId,
    );
    if (block == null) {
      return;
    }

    _richTextDraft = _richTextDraft.copyWith(
      document: _richTextDraft.document.replaceBlock(
        block.copyWith(children: <ComposerInlineNode>[ComposerTextNode(value)]),
      ),
    );
    notifyListeners();
  }

  void updateDetailsSummaryText(String blockId, String value) {
    final block = _richTextDraft.document.findBlock<ComposerDetailsBlock>(
      blockId,
    );
    if (block == null) {
      return;
    }

    _richTextDraft = _richTextDraft.copyWith(
      document: _richTextDraft.document.replaceBlock(
        block.copyWith(summary: <ComposerInlineNode>[ComposerTextNode(value)]),
      ),
    );
    notifyListeners();
  }

  void updateDetailsBodyText(String blockId, String value) {
    final block = _richTextDraft.document.findBlock<ComposerDetailsBlock>(
      blockId,
    );
    if (block == null) {
      return;
    }

    _richTextDraft = _richTextDraft.copyWith(
      document: _richTextDraft.document.replaceBlock(
        block.copyWith(
          children: <ComposerBlockNode>[
            ComposerParagraphBlock(
              id:
                  block.children
                      .whereType<ComposerParagraphBlock>()
                      .firstOrNull
                      ?.id ??
                  createComposerId('details-body'),
              children: <ComposerInlineNode>[ComposerTextNode(value)],
            ),
          ],
        ),
      ),
    );
    notifyListeners();
  }

  void updateImageCaption(String blockId, String value) {
    final block = _richTextDraft.document.findBlock<ComposerImageBlock>(
      blockId,
    );
    if (block == null) {
      return;
    }

    _richTextDraft = _richTextDraft.copyWith(
      document: _richTextDraft.document.replaceBlock(
        block.copyWith(caption: value),
      ),
    );
    notifyListeners();
  }

  void removeRichTextBlock(String blockId) {
    final imageBlock = _richTextDraft.document.findBlock<ComposerImageBlock>(
      blockId,
    );
    if (imageBlock != null) {
      removeRichTextAttachment(imageBlock.attachmentId);
      return;
    }

    final nextDocument = _richTextDraft.document.removeBlock(blockId);
    _richTextDraft = _richTextDraft.copyWith(
      document: nextDocument.blocks.isEmpty
          ? ComposerDocument.withSingleParagraph()
          : nextDocument,
    );
    notifyListeners();
  }

  void removeRichTextAttachment(String attachmentId) {
    final nextAttachments = _richTextDraft.attachments
        .where((attachment) => attachment.id != attachmentId)
        .toList(growable: false);
    final nextDocument = ComposerDocument(
      blocks: _richTextDraft.document.blocks
          .where(
            (block) =>
                block is! ComposerImageBlock ||
                block.attachmentId != attachmentId,
          )
          .toList(growable: false),
    );

    _richTextDraft = _richTextDraft.copyWith(
      attachments: nextAttachments,
      document: nextDocument.blocks.isEmpty
          ? ComposerDocument.withSingleParagraph()
          : nextDocument,
    );
    notifyListeners();
  }

  Future<void> selectVideoPlaceholder() async {
    if (_videoDraft.video?.uploadState == ComposerUploadState.uploading) {
      return;
    }

    final pendingAttachment = ComposerAttachment(
      id: createComposerId('video-attachment'),
      type: ComposerAttachmentType.video,
      uploadState: ComposerUploadState.uploading,
      label: '视频草稿',
      duration: const Duration(minutes: 1, seconds: 28),
      progress: 0.15,
    );

    _videoDraft = _videoDraft.copyWith(video: pendingAttachment);
    _statusMessage = '已创建视频草稿占位，正在通过 stub 服务模拟上传。';
    notifyListeners();

    try {
      final uploaded = await _videoUploadService.uploadVideo(pendingAttachment);
      if (_videoDraft.video?.id != pendingAttachment.id) {
        return;
      }

      _videoDraft = _videoDraft.copyWith(video: uploaded);
      _statusMessage = '视频草稿已就绪，可用于后续视频主贴或回贴扩展。';
    } catch (_) {
      if (_videoDraft.video?.id != pendingAttachment.id) {
        return;
      }
      _videoDraft = _videoDraft.copyWith(
        video: pendingAttachment.copyWith(
          uploadState: ComposerUploadState.failed,
          progress: 0,
          errorMessage: 'stub 上传失败',
        ),
      );
      _statusMessage = '视频草稿上传失败。';
    }

    notifyListeners();
  }

  void clearVideoDraft() {
    if (_videoDraft.video == null) {
      return;
    }
    _videoDraft = _videoDraft.clearedVideoPreservingTitle();
    notifyListeners();
  }

  Future<void> publishCurrentDraft() async {
    if (!canPublish) {
      _statusMessage = '当前草稿还不满足发布条件。';
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final receipt = switch (_mode) {
        ThreadComposeMode.richText =>
          await _publishService.publishRichTextThread(_richTextDraft),
        ThreadComposeMode.videoOnly => await _publishService.publishVideoThread(
          _videoDraft,
        ),
      };
      _statusMessage = '${receipt.summary}（${receipt.submittedAt.toLocal()}）';
    } catch (_) {
      _statusMessage = 'stub 发布失败，请稍后再试。';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}

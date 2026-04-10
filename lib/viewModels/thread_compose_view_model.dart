import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/composer/composer_attachment.dart';
import '../models/composer/quill_embed_models.dart';
import '../models/composer/rich_text_composer_content.dart';
import '../models/composer/thread_draft.dart';
import '../services/composer/composer_image_picker_service.dart';
import '../services/composer/html_export_service.dart';
import '../services/composer/thread_publish_service.dart';
import '../services/composer/thread_video_upload_service.dart';
import 'rich_text_composer_controller.dart';

class ThreadComposeViewModel extends ChangeNotifier {
  final ThreadPublishService _publishService;
  final ThreadVideoUploadService _videoUploadService;

  late final RichTextComposerController _richTextComposer;

  ThreadComposeMode _mode = ThreadComposeMode.richText;
  String _title = '';
  ComposerAttachment? _videoAttachment;
  bool _isSubmitting = false;
  String? _videoStatusMessage;

  ThreadComposeViewModel({
    ThreadPublishService? publishService,
    ThreadVideoUploadService? videoUploadService,
    ComposerImagePickerService? imagePickerService,
    HtmlExportService? htmlExportService,
  }) : _publishService = publishService ?? const StubThreadPublishService(),
       _videoUploadService =
           videoUploadService ?? const StubThreadVideoUploadService() {
    _richTextComposer = RichTextComposerController(
      videoUploadService: _videoUploadService,
      imagePickerService: imagePickerService,
      htmlExportService: htmlExportService,
    )..addListener(_handleRichTextComposerChanged);
  }

  ThreadComposeMode get mode => _mode;
  RichTextThreadDraft get richTextDraft =>
      RichTextThreadDraft.fromComposerContent(
        title: _title,
        content: _richTextComposer.content,
      );
  VideoThreadDraft get videoDraft =>
      VideoThreadDraft(title: _title, video: _videoAttachment);
  bool get isSubmitting => _isSubmitting;
  String? get statusMessage => switch (_mode) {
    ThreadComposeMode.richText => _richTextComposer.statusMessage,
    ThreadComposeMode.videoOnly => _videoStatusMessage,
  };
  quill.QuillController get richTextController => _richTextComposer.controller;

  bool get canPublish {
    if (_isSubmitting) {
      return false;
    }

    if (_title.trim().isEmpty) {
      return false;
    }

    return switch (_mode) {
      ThreadComposeMode.richText => _richTextComposer.hasPublishableContent,
      ThreadComposeMode.videoOnly => _videoAttachment?.isReady ?? false,
    };
  }

  String get currentTitle => _title;

  String get richTextPreviewHtml => _richTextComposer.previewHtml;

  void updateTitle(String value) {
    if (_title == value) {
      return;
    }

    _title = value;
    notifyListeners();
  }

  String? describeModeSwitch(ThreadComposeMode nextMode) {
    if (nextMode == _mode) {
      return null;
    }

    return switch (nextMode) {
      ThreadComposeMode.videoOnly
          when _richTextComposer.hasPublishableContent =>
        '切换到视频主贴会清空当前图文正文和附件占位。',
      ThreadComposeMode.richText when _videoAttachment != null =>
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
      _richTextComposer.replaceContent(RichTextComposerContent.empty());
    }

    if (nextMode == ThreadComposeMode.richText && warning != null) {
      _videoAttachment = null;
    }

    _mode = nextMode;
    _videoStatusMessage = null;
    _richTextComposer.clearStatusMessage();
    notifyListeners();
  }

  void insertDetailsEmbed() {
    _richTextComposer.insertDetailsEmbed();
  }

  Future<void> pickAndInsertImage() {
    return _richTextComposer.pickAndInsertImage();
  }

  void updateDetailsEmbed(int offset, BluefishDetailsEmbedData data) {
    _richTextComposer.updateDetailsEmbed(offset, data);
  }

  void updateImagePlaceholderEmbed(
    int offset,
    BluefishImagePlaceholderEmbedData data,
  ) {
    _richTextComposer.updateImagePlaceholderEmbed(offset, data);
  }

  void removeRichTextEmbed(int offset) {
    _richTextComposer.removeEmbed(offset);
  }

  void removeRichTextAttachment(String attachmentId) {
    _richTextComposer.removeAttachment(attachmentId);
  }

  Future<void> selectVideoPlaceholder() async {
    if (_videoAttachment?.uploadState == ComposerUploadState.uploading) {
      return;
    }

    final pendingAttachment = ComposerAttachment(
      id: _createComposerId('video-attachment'),
      type: ComposerAttachmentType.video,
      uploadState: ComposerUploadState.uploading,
      label: '视频草稿',
      duration: const Duration(minutes: 1, seconds: 28),
      progress: 0.15,
    );

    _videoAttachment = pendingAttachment;
    _videoStatusMessage = '已创建视频草稿占位，正在通过 stub 服务模拟上传。';
    notifyListeners();

    try {
      final uploaded = await _videoUploadService.uploadVideo(pendingAttachment);
      if (_videoAttachment?.id != pendingAttachment.id) {
        return;
      }

      _videoAttachment = uploaded;
      _videoStatusMessage = '视频草稿已就绪，可用于后续视频主贴或回贴扩展。';
    } catch (_) {
      if (_videoAttachment?.id != pendingAttachment.id) {
        return;
      }
      _videoAttachment = pendingAttachment.copyWith(
        uploadState: ComposerUploadState.failed,
        progress: 0,
        errorMessage: 'stub 上传失败',
      );
      _videoStatusMessage = '视频草稿上传失败。';
    }

    notifyListeners();
  }

  void clearVideoDraft() {
    if (_videoAttachment == null) {
      return;
    }
    _videoAttachment = null;
    notifyListeners();
  }

  Future<void> publishCurrentDraft() async {
    if (!canPublish) {
      _setStatusMessageForCurrentMode('当前草稿还不满足发布条件。');
      if (_mode == ThreadComposeMode.videoOnly) {
        notifyListeners();
      }
      return;
    }

    _isSubmitting = true;
    _setStatusMessageForCurrentMode(null);
    notifyListeners();

    try {
      switch (_mode) {
        case ThreadComposeMode.richText:
          final draftForPublish = RichTextThreadDraft.fromComposerContent(
            title: _title,
            content: _richTextComposer.buildExportedContent(),
          );
          final receipt = await _publishService.publishRichTextThread(
            draftForPublish,
          );
          _richTextComposer.replaceContent(
            draftForPublish.composerContent,
            reloadDocument: false,
          );
          _richTextComposer.setStatusMessage(
            '${receipt.summary}（${receipt.submittedAt.toLocal()}）',
          );
          break;
        case ThreadComposeMode.videoOnly:
          final receipt = await _publishService.publishVideoThread(videoDraft);
          _videoStatusMessage =
              '${receipt.summary}（${receipt.submittedAt.toLocal()}）';
          break;
      }
    } catch (_) {
      _setStatusMessageForCurrentMode('stub 发布失败，请稍后再试。');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _handleRichTextComposerChanged() {
    notifyListeners();
  }

  void _setStatusMessageForCurrentMode(String? message) {
    switch (_mode) {
      case ThreadComposeMode.richText:
        _richTextComposer.setStatusMessage(message);
        break;
      case ThreadComposeMode.videoOnly:
        _videoStatusMessage = message;
        break;
    }
  }

  String _createComposerId(String prefix) {
    _threadComposerIdCounter += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_threadComposerIdCounter';
  }

  @override
  void dispose() {
    _richTextComposer
      ..removeListener(_handleRichTextComposerChanged)
      ..dispose();
    super.dispose();
  }
}

int _threadComposerIdCounter = 0;

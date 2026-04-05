import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/composer/composer_attachment.dart';
import '../models/composer/quill_embed_models.dart';
import '../models/composer/quill_draft_utils.dart';
import '../models/composer/thread_draft.dart';
import '../services/composer/composer_image_picker_service.dart';
import '../services/composer/html_export_service.dart';
import 'package:bluefish/services/composer/thread_publish_service.dart';
import 'package:bluefish/services/composer/thread_video_upload_service.dart';

class ThreadComposeViewModel extends ChangeNotifier {
  final ThreadPublishService _publishService;
  final ThreadVideoUploadService _videoUploadService;
  final ComposerImagePickerService _imagePickerService;
  final HtmlExportService _htmlExportService;

  ThreadComposeMode _mode = ThreadComposeMode.richText;
  RichTextThreadDraft _richTextDraft = RichTextThreadDraft.empty();
  VideoThreadDraft _videoDraft = VideoThreadDraft.empty();
  bool _isSubmitting = false;
  String? _statusMessage;
  bool _isApplyingProgrammaticRichTextUpdate = false;
  bool _isNormalizingCollapsedSelection = false;

  late final quill.QuillController _richTextController;

  ThreadComposeViewModel({
    ThreadPublishService? publishService,
    ThreadVideoUploadService? videoUploadService,
    ComposerImagePickerService? imagePickerService,
    HtmlExportService? htmlExportService,
  }) : _publishService = publishService ?? const StubThreadPublishService(),
       _videoUploadService =
           videoUploadService ?? const StubThreadVideoUploadService(),
       _imagePickerService =
           imagePickerService ?? DeviceComposerImagePickerService(),
       _htmlExportService = htmlExportService ?? const HtmlExportService() {
    _richTextController = quill.QuillController(
      document: _documentFromDeltaJson(_richTextDraft.deltaJson),
      selection: const TextSelection.collapsed(offset: 0),
    )..addListener(_handleRichTextChanged);
  }

  ThreadComposeMode get mode => _mode;
  RichTextThreadDraft get richTextDraft => _richTextDraft;
  VideoThreadDraft get videoDraft => _videoDraft;
  bool get isSubmitting => _isSubmitting;
  String? get statusMessage => _statusMessage;
  quill.QuillController get richTextController => _richTextController;

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

  String get richTextPreviewHtml =>
      _htmlExportService.exportRichText(_richTextDraft.deltaJson);

  void updateTitle(String value) {
    if (_richTextDraft.title == value && _videoDraft.title == value) {
      return;
    }

    _richTextDraft = _richTextDraft.copyWith(title: value, clearBodyHtml: true);
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
      _reloadRichTextController();
    }

    if (nextMode == ThreadComposeMode.richText && warning != null) {
      _videoDraft = _videoDraft.clearedVideoPreservingTitle();
    }

    _mode = nextMode;
    _statusMessage = null;
    notifyListeners();
  }

  void insertDetailsEmbed() {
    _insertBlockEmbedWithLineBreaks(
      BluefishDetailsEmbed(BluefishDetailsEmbedData.initial()),
    );
  }

  Future<void> pickAndInsertImage() async {
    try {
      final pickedImage = await _imagePickerService.pickImage();
      if (pickedImage == null) {
        _statusMessage = '已取消选择图片。';
        notifyListeners();
        return;
      }

      _insertPickedImage(pickedImage);
    } catch (_) {
      _statusMessage = '选择图片失败，请稍后再试。';
      notifyListeners();
    }
  }

  void _insertPickedImage(PickedComposerImage pickedImage) {
    final attachmentId = _createComposerId('image-attachment');
    final label = pickedImage.name.trim().isEmpty
        ? '图片 ${_richTextDraft.attachments.length + 1}'
        : pickedImage.name.trim();
    final attachment = ComposerAttachment(
      id: attachmentId,
      type: ComposerAttachmentType.image,
      uploadState: ComposerUploadState.pending,
      label: label,
      localPath: pickedImage.path,
      thumbnailUrl: pickedImage.path,
      bytes: pickedImage.bytes,
    );

    _richTextDraft = _richTextDraft.copyWith(
      attachments: <ComposerAttachment>[
        ..._richTextDraft.attachments,
        attachment,
      ],
      clearBodyHtml: true,
    );
    _statusMessage = '已添加图片：$label';

    _insertBlockEmbedWithLineBreaks(
      BluefishImagePlaceholderEmbed(
        BluefishImagePlaceholderEmbedData(
          attachmentId: attachmentId,
          label: label,
          sourceUrl: pickedImage.path,
        ),
      ),
    );
  }

  void updateDetailsEmbed(int offset, BluefishDetailsEmbedData data) {
    _replaceEmbed(offset, BluefishDetailsEmbed(data));
  }

  void updateImagePlaceholderEmbed(
    int offset,
    BluefishImagePlaceholderEmbedData data,
  ) {
    _replaceEmbed(offset, BluefishImagePlaceholderEmbed(data));
  }

  void removeRichTextEmbed(int offset) {
    _richTextController.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }

  void removeRichTextAttachment(String attachmentId) {
    final nextAttachments = _richTextDraft.attachments
        .where((attachment) => attachment.id != attachmentId)
        .toList(growable: false);

    if (nextAttachments.length == _richTextDraft.attachments.length) {
      return;
    }

    _richTextDraft = _richTextDraft.copyWith(
      attachments: nextAttachments,
      clearBodyHtml: true,
    );

    final offset = _findImagePlaceholderOffsetByAttachmentId(
      _serializeControllerDelta(),
      attachmentId,
    );
    if (offset != null) {
      _richTextController.replaceText(
        offset,
        1,
        '',
        TextSelection.collapsed(offset: offset),
      );
      return;
    }

    notifyListeners();
  }

  Future<void> selectVideoPlaceholder() async {
    if (_videoDraft.video?.uploadState == ComposerUploadState.uploading) {
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
          await _publishService.publishRichTextThread(
            _richTextDraft = _richTextDraft.copyWith(
              bodyHtml: richTextPreviewHtml,
              clearBodyHtml: false,
            ),
          ),
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

  void _insertBlockEmbedWithLineBreaks(quill.Embeddable embed) {
    final selection = _normalizedSelection();
    final plainText = _richTextController.document.toPlainText();
    final replaceLength = selection.end - selection.start;
    final hasLeadingNewline =
        selection.start == 0 || plainText[selection.start - 1] == '\n';
    final hasTrailingNewline =
        selection.end >= plainText.length || plainText[selection.end] == '\n';
    _isApplyingProgrammaticRichTextUpdate = true;
    try {
      _richTextController.replaceText(
        selection.start,
        replaceLength,
        '',
        TextSelection.collapsed(offset: selection.start),
      );

      var insertOffset = selection.start;
      if (!hasLeadingNewline) {
        _richTextController.replaceText(
          insertOffset,
          0,
          '\n',
          TextSelection.collapsed(offset: insertOffset + 1),
        );
        insertOffset += 1;
      }

      _richTextController.replaceText(
        insertOffset,
        0,
        embed,
        TextSelection.collapsed(offset: insertOffset + 1),
      );
      insertOffset += 1;

      if (!hasTrailingNewline) {
        _richTextController.replaceText(
          insertOffset,
          0,
          '\n',
          TextSelection.collapsed(offset: insertOffset + 1),
        );
        insertOffset += 1;
      }

      _richTextController.updateSelection(
        TextSelection.collapsed(offset: insertOffset),
        quill.ChangeSource.local,
      );
    } finally {
      _isApplyingProgrammaticRichTextUpdate = false;
    }

    _handleRichTextChanged();
  }

  void _replaceEmbed(int offset, quill.Embeddable embed) {
    _isApplyingProgrammaticRichTextUpdate = true;
    try {
      _richTextController.replaceText(
        offset,
        1,
        embed,
        TextSelection.collapsed(offset: offset + 1),
      );
    } finally {
      _isApplyingProgrammaticRichTextUpdate = false;
    }

    _handleRichTextChanged();
  }

  TextSelection _normalizedSelection() {
    final selection = _richTextController.selection;
    if (selection.isValid) {
      return selection;
    }

    final fallbackOffset = (_richTextController.document.length - 1).clamp(
      0,
      _richTextController.document.length,
    );
    return TextSelection.collapsed(offset: fallbackOffset);
  }

  void _handleRichTextChanged() {
    if (_isApplyingProgrammaticRichTextUpdate) {
      return;
    }

    if (_normalizeCollapsedSelectionAroundBlockEmbeds()) {
      return;
    }

    final nextDeltaJson = _serializeControllerDelta();
    final nextAttachments = _synchronizeImageAttachments(nextDeltaJson);

    final deltaChanged =
        _deltaSignature(nextDeltaJson) !=
        _deltaSignature(_richTextDraft.deltaJson);
    final attachmentsChanged =
        _attachmentSignature(nextAttachments) !=
        _attachmentSignature(_richTextDraft.attachments);

    if (!deltaChanged && !attachmentsChanged) {
      return;
    }

    _richTextDraft = _richTextDraft.copyWith(
      deltaJson: nextDeltaJson,
      attachments: nextAttachments,
      clearBodyHtml: true,
    );
    notifyListeners();
  }

  bool _normalizeCollapsedSelectionAroundBlockEmbeds() {
    if (_isNormalizingCollapsedSelection) {
      return false;
    }

    final selection = _richTextController.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      return false;
    }

    final deltaJson = _serializeControllerDelta();
    final normalizedSelection = normalizedCollapsedSelectionForBlockEmbeds(
      deltaJson: deltaJson,
      plainText: _richTextController.document.toPlainText(),
      selection: selection,
    );
    if (normalizedSelection == null || normalizedSelection == selection) {
      return false;
    }

    _isNormalizingCollapsedSelection = true;
    try {
      _richTextController.updateSelection(
        normalizedSelection,
        quill.ChangeSource.local,
      );
    } finally {
      _isNormalizingCollapsedSelection = false;
    }
    return true;
  }

  List<ComposerAttachment> _synchronizeImageAttachments(
    List<Map<String, dynamic>> deltaJson,
  ) {
    final referencedEmbeds = <String, BluefishImagePlaceholderEmbedData>{};
    for (final operation in deltaJson) {
      final insert = operation['insert'];
      if (insert is! Map ||
          !insert.containsKey(bluefishImagePlaceholderEmbedType)) {
        continue;
      }

      final embedData = BluefishImagePlaceholderEmbedData.fromJsonString(
        insert[bluefishImagePlaceholderEmbedType].toString(),
      );
      referencedEmbeds[embedData.attachmentId] = embedData;
    }

    return _richTextDraft.attachments
        .where((attachment) => referencedEmbeds.containsKey(attachment.id))
        .map((attachment) {
          final embed = referencedEmbeds[attachment.id]!;
          return attachment.copyWith(label: embed.label);
        })
        .toList(growable: false);
  }

  int? _findImagePlaceholderOffsetByAttachmentId(
    List<Map<String, dynamic>> deltaJson,
    String attachmentId,
  ) {
    var offset = 0;
    for (final operation in deltaJson) {
      final insert = operation['insert'];
      if (insert is String) {
        offset += insert.length;
        continue;
      }

      if (insert is Map &&
          insert.containsKey(bluefishImagePlaceholderEmbedType)) {
        final embedData = BluefishImagePlaceholderEmbedData.fromJsonString(
          insert[bluefishImagePlaceholderEmbedType].toString(),
        );
        if (embedData.attachmentId == attachmentId) {
          return offset;
        }
      }

      offset += 1;
    }
    return null;
  }

  void _reloadRichTextController() {
    _isApplyingProgrammaticRichTextUpdate = true;
    _richTextController.document = _documentFromDeltaJson(
      _richTextDraft.deltaJson,
    );
    _richTextController.updateSelection(
      TextSelection.collapsed(
        offset: (_richTextController.document.length - 1).clamp(
          0,
          _richTextController.document.length,
        ),
      ),
      quill.ChangeSource.local,
    );
    _isApplyingProgrammaticRichTextUpdate = false;
  }

  quill.Document _documentFromDeltaJson(List<Map<String, dynamic>> deltaJson) {
    try {
      return quill.Document.fromJson(deltaJson);
    } catch (_) {
      return quill.Document();
    }
  }

  List<Map<String, dynamic>> _serializeControllerDelta() {
    final rawJson = _richTextController.document.toDelta().toJson();
    return _cloneDeltaJson(rawJson);
  }

  List<Map<String, dynamic>> _cloneDeltaJson(List<dynamic> rawJson) {
    return (jsonDecode(jsonEncode(rawJson)) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  String _deltaSignature(List<Map<String, dynamic>> deltaJson) {
    return jsonEncode(deltaJson);
  }

  String _attachmentSignature(List<ComposerAttachment> attachments) {
    return jsonEncode(
      attachments
          .map(
            (attachment) => <String, Object?>{
              'id': attachment.id,
              'type': attachment.type.name,
              'state': attachment.uploadState.name,
              'label': attachment.label,
              'localPath': attachment.localPath,
              'remoteUrl': attachment.remoteUrl,
              'thumbnailUrl': attachment.thumbnailUrl,
              'bytes': attachment.bytes,
              'progress': attachment.progress,
            },
          )
          .toList(growable: false),
    );
  }

  String _createComposerId(String prefix) {
    _composerIdCounter += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_composerIdCounter';
  }

  @override
  void dispose() {
    _richTextController
      ..removeListener(_handleRichTextChanged)
      ..dispose();
    super.dispose();
  }
}

int _composerIdCounter = 0;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/composer/composer_attachment.dart';
import '../models/composer/quill_embed_models.dart';
import '../models/composer/quill_draft_utils.dart';
import '../models/composer/rich_text_composer_content.dart';
import '../services/composer/composer_image_picker_service.dart';
import '../services/composer/html_export_service.dart';
import '../services/composer/thread_video_upload_service.dart';

class RichTextComposerController extends ChangeNotifier {
  final ThreadVideoUploadService _videoUploadService;
  final ComposerImagePickerService _imagePickerService;
  final HtmlExportService _htmlExportService;
  final String _imageAttachmentLabelPrefix;
  final String _videoAttachmentLabel;
  final Duration _videoAttachmentDuration;
  final double _videoAttachmentProgress;
  final String _videoUploadStartedMessage;
  final String _videoUploadReadyMessage;
  final String _videoUploadFailedMessage;

  RichTextComposerContent _content;
  String? _statusMessage;
  bool _isApplyingProgrammaticRichTextUpdate = false;
  bool _isNormalizingCollapsedSelection = false;
  bool _isDisposed = false;

  late final quill.QuillController _controller;

  RichTextComposerController({
    RichTextComposerContent? initialContent,
    ThreadVideoUploadService? videoUploadService,
    ComposerImagePickerService? imagePickerService,
    HtmlExportService? htmlExportService,
    String imageAttachmentLabelPrefix = '图片',
    String videoAttachmentLabel = '视频草稿',
    Duration videoAttachmentDuration = const Duration(seconds: 42),
    double videoAttachmentProgress = 0.18,
    String videoUploadStartedMessage = '正在模拟上传视频附件。',
    String videoUploadReadyMessage = '视频附件草稿已就绪。',
    String videoUploadFailedMessage = '视频附件上传失败。',
  }) : _videoUploadService =
           videoUploadService ?? const StubThreadVideoUploadService(),
       _imagePickerService =
           imagePickerService ?? DeviceComposerImagePickerService(),
       _htmlExportService = htmlExportService ?? const HtmlExportService(),
       _imageAttachmentLabelPrefix = imageAttachmentLabelPrefix,
       _videoAttachmentLabel = videoAttachmentLabel,
       _videoAttachmentDuration = videoAttachmentDuration,
       _videoAttachmentProgress = videoAttachmentProgress,
       _videoUploadStartedMessage = videoUploadStartedMessage,
       _videoUploadReadyMessage = videoUploadReadyMessage,
       _videoUploadFailedMessage = videoUploadFailedMessage,
       _content = initialContent ?? RichTextComposerContent.empty() {
    _controller = quill.QuillController(
      document: _documentFromDeltaJson(_content.deltaJson),
      selection: const TextSelection.collapsed(offset: 0),
    )..addListener(_handleRichTextChanged);
  }

  quill.QuillController get controller => _controller;
  RichTextComposerContent get content => _content;
  String? get statusMessage => _statusMessage;
  bool get hasPublishableContent => _content.hasPublishableContent;

  String get previewHtml =>
      _htmlExportService.exportRichText(_content.deltaJson);

  RichTextComposerContent buildExportedContent() {
    return _content.copyWith(bodyHtml: previewHtml, clearBodyHtml: false);
  }

  void setStatusMessage(String? value) {
    if (_statusMessage == value) {
      return;
    }

    _statusMessage = value;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void clearStatusMessage() {
    setStatusMessage(null);
  }

  void replaceContent(
    RichTextComposerContent nextContent, {
    bool reloadDocument = true,
  }) {
    if (_contentSignature(nextContent) == _contentSignature(_content)) {
      return;
    }

    _content = nextContent;
    if (reloadDocument) {
      _reloadController();
    }
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void insertDetailsEmbed() {
    _insertBlockEmbedWithLineBreaks(
      BluefishDetailsEmbed(BluefishDetailsEmbedData.initial()),
    );
  }

  Future<void> pickAndInsertImage() async {
    try {
      final pickedImage = await _imagePickerService.pickImage();
      if (_isDisposed) {
        return;
      }
      if (pickedImage == null) {
        setStatusMessage('已取消选择图片。');
        return;
      }

      _insertPickedImage(pickedImage);
    } catch (_) {
      if (_isDisposed) {
        return;
      }
      setStatusMessage('选择图片失败，请稍后再试。');
    }
  }

  Future<void> addVideoAttachment() async {
    final pendingVideo = ComposerAttachment(
      id: _createComposerId('video-attachment'),
      type: ComposerAttachmentType.video,
      uploadState: ComposerUploadState.uploading,
      label: _videoAttachmentLabel,
      duration: _videoAttachmentDuration,
      progress: _videoAttachmentProgress,
    );

    _content = _content.copyWith(
      attachments: <ComposerAttachment>[..._content.attachments, pendingVideo],
      clearBodyHtml: true,
    );
    _statusMessage = _videoUploadStartedMessage;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      final uploaded = await _videoUploadService.uploadVideo(pendingVideo);
      if (_isDisposed) {
        return;
      }

      _content = _content.copyWith(
        attachments: _content.attachments
            .map(
              (attachment) =>
                  attachment.id == pendingVideo.id ? uploaded : attachment,
            )
            .toList(growable: false),
        clearBodyHtml: true,
      );
      _statusMessage = _videoUploadReadyMessage;
    } catch (_) {
      if (_isDisposed) {
        return;
      }

      _content = _content.copyWith(
        attachments: _content.attachments
            .map((attachment) {
              if (attachment.id != pendingVideo.id) {
                return attachment;
              }
              return attachment.copyWith(
                uploadState: ComposerUploadState.failed,
                progress: 0,
                errorMessage: 'stub 上传失败',
              );
            })
            .toList(growable: false),
        clearBodyHtml: true,
      );
      _statusMessage = _videoUploadFailedMessage;
    }

    if (!_isDisposed) {
      notifyListeners();
    }
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

  void removeEmbed(int offset) {
    _controller.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }

  void removeAttachment(String attachmentId) {
    final nextAttachments = _content.attachments
        .where((attachment) => attachment.id != attachmentId)
        .toList(growable: false);

    if (nextAttachments.length == _content.attachments.length) {
      return;
    }

    _content = _content.copyWith(
      attachments: nextAttachments,
      clearBodyHtml: true,
    );

    final offset = _findImagePlaceholderOffsetByAttachmentId(
      _serializeControllerDelta(),
      attachmentId,
    );
    if (offset != null) {
      _controller.replaceText(
        offset,
        1,
        '',
        TextSelection.collapsed(offset: offset),
      );
      return;
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _insertPickedImage(PickedComposerImage pickedImage) {
    final attachmentId = _createComposerId('image-attachment');
    final label = pickedImage.name.trim().isEmpty
        ? '$_imageAttachmentLabelPrefix ${_content.attachments.length + 1}'
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

    _content = _content.copyWith(
      attachments: <ComposerAttachment>[..._content.attachments, attachment],
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

  void _insertBlockEmbedWithLineBreaks(quill.Embeddable embed) {
    final selection = _normalizedSelection();
    final plainText = _controller.document.toPlainText();
    final replaceLength = selection.end - selection.start;
    final hasLeadingNewline =
        selection.start == 0 || plainText[selection.start - 1] == '\n';
    final hasTrailingNewline =
        selection.end >= plainText.length || plainText[selection.end] == '\n';
    _isApplyingProgrammaticRichTextUpdate = true;
    try {
      _controller.replaceText(
        selection.start,
        replaceLength,
        '',
        TextSelection.collapsed(offset: selection.start),
      );

      var insertOffset = selection.start;
      if (!hasLeadingNewline) {
        _controller.replaceText(
          insertOffset,
          0,
          '\n',
          TextSelection.collapsed(offset: insertOffset + 1),
        );
        insertOffset += 1;
      }

      _controller.replaceText(
        insertOffset,
        0,
        embed,
        TextSelection.collapsed(offset: insertOffset + 1),
      );
      insertOffset += 1;

      if (!hasTrailingNewline) {
        _controller.replaceText(
          insertOffset,
          0,
          '\n',
          TextSelection.collapsed(offset: insertOffset + 1),
        );
        insertOffset += 1;
      }

      _controller.updateSelection(
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
      _controller.replaceText(
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
    final selection = _controller.selection;
    if (selection.isValid) {
      return selection;
    }

    final fallbackOffset = (_controller.document.length - 1).clamp(
      0,
      _controller.document.length,
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
    final nextAttachments = _synchronizeAttachments(nextDeltaJson);

    final deltaChanged =
        _deltaSignature(nextDeltaJson) != _deltaSignature(_content.deltaJson);
    final attachmentsChanged =
        _attachmentSignature(nextAttachments) !=
        _attachmentSignature(_content.attachments);

    if (!deltaChanged && !attachmentsChanged) {
      return;
    }

    _content = _content.copyWith(
      deltaJson: nextDeltaJson,
      attachments: nextAttachments,
      clearBodyHtml: true,
    );
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  bool _normalizeCollapsedSelectionAroundBlockEmbeds() {
    if (_isNormalizingCollapsedSelection) {
      return false;
    }

    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      return false;
    }

    final deltaJson = _serializeControllerDelta();
    final normalizedSelection = normalizedCollapsedSelectionForBlockEmbeds(
      deltaJson: deltaJson,
      plainText: _controller.document.toPlainText(),
      selection: selection,
    );
    if (normalizedSelection == null || normalizedSelection == selection) {
      return false;
    }

    _isNormalizingCollapsedSelection = true;
    try {
      _controller.updateSelection(
        normalizedSelection,
        quill.ChangeSource.local,
      );
    } finally {
      _isNormalizingCollapsedSelection = false;
    }
    return true;
  }

  List<ComposerAttachment> _synchronizeAttachments(
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

    return _content.attachments
        .where(
          (attachment) =>
              attachment.type != ComposerAttachmentType.image ||
              referencedEmbeds.containsKey(attachment.id),
        )
        .map((attachment) {
          final embed = referencedEmbeds[attachment.id];
          if (embed == null) {
            return attachment;
          }
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

  void _reloadController() {
    _isApplyingProgrammaticRichTextUpdate = true;
    _controller.document = _documentFromDeltaJson(_content.deltaJson);
    _controller.updateSelection(
      TextSelection.collapsed(
        offset: (_controller.document.length - 1).clamp(
          0,
          _controller.document.length,
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
    final rawJson = _controller.document.toDelta().toJson();
    return (jsonDecode(jsonEncode(rawJson)) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  String _contentSignature(RichTextComposerContent content) {
    return jsonEncode(<String, Object?>{
      'deltaJson': content.deltaJson,
      'attachments': jsonDecode(_attachmentSignature(content.attachments)),
      'bodyHtml': content.bodyHtml,
    });
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
              'durationMs': attachment.duration?.inMilliseconds,
              'bytes': attachment.bytes,
              'progress': attachment.progress,
              'errorMessage': attachment.errorMessage,
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
    _isDisposed = true;
    _controller
      ..removeListener(_handleRichTextChanged)
      ..dispose();
    super.dispose();
  }
}

int _composerIdCounter = 0;

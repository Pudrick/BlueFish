import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/composer/composer_attachment.dart';
import '../../models/composer/quill_embed_models.dart';
import '../../models/composer/quill_draft_utils.dart';
import '../../models/composer/reply_draft.dart';
import '../../services/composer/composer_image_picker_service.dart';
import '../../services/composer/html_export_service.dart';
import '../../services/thread_publish_service.dart';
import '../../services/thread_video_upload_service.dart';
import 'composer_accessory_panel.dart';
import 'quill_composer_editor.dart';
import 'quill_composer_toolbar.dart';

const Duration replyComposerSheetTransitionDuration = Duration(
  milliseconds: 220,
);
const Duration replyComposerSheetReverseTransitionDuration = Duration(
  milliseconds: 180,
);

Widget buildReplyComposerSheetTransition({
  required Animation<double> animation,
  required Widget child,
}) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final opacityAnimation = CurvedAnimation(
    parent: animation,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );

  return FadeTransition(
    opacity: opacityAnimation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    ),
  );
}

Future<ReplyDraft?> showReplyComposerSheet({
  required BuildContext context,
  String title = '发送回复',
  String submitLabel = '发送',
  String placeholder = '写下你的回复',
  String? contextLabel,
  String? contextPreview,
  ReplyDraft? initialDraft,
  bool allowVideoAttachments = false,
  bool closeOnSubmit = true,
  Future<void> Function(ReplyDraft draft)? onSubmit,
  ThreadPublishService? publishService,
  ThreadVideoUploadService? videoUploadService,
  ComposerImagePickerService? imagePickerService,
}) {
  return showGeneralDialog<ReplyDraft>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: replyComposerSheetTransitionDuration,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return buildReplyComposerSheetTransition(
        animation: animation,
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return ReplyComposerSheet(
        title: title,
        submitLabel: submitLabel,
        placeholder: placeholder,
        contextLabel: contextLabel,
        contextPreview: contextPreview,
        initialDraft: initialDraft ?? ReplyDraft.empty(),
        allowVideoAttachments: allowVideoAttachments,
        closeOnSubmit: closeOnSubmit,
        onSubmit: onSubmit,
        publishService: publishService,
        videoUploadService: videoUploadService,
        imagePickerService: imagePickerService,
      );
    },
  );
}

class ReplyComposerSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String placeholder;
  final String? contextLabel;
  final String? contextPreview;
  final ReplyDraft initialDraft;
  final bool allowVideoAttachments;
  final bool closeOnSubmit;
  final Future<void> Function(ReplyDraft draft)? onSubmit;
  final ThreadPublishService? publishService;
  final ThreadVideoUploadService? videoUploadService;
  final ComposerImagePickerService? imagePickerService;

  const ReplyComposerSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.initialDraft,
    this.placeholder = '写下你的回复',
    this.contextLabel,
    this.contextPreview,
    this.allowVideoAttachments = false,
    this.closeOnSubmit = true,
    this.onSubmit,
    this.publishService,
    this.videoUploadService,
    this.imagePickerService,
  });

  @override
  State<ReplyComposerSheet> createState() => _ReplyComposerSheetState();
}

class _ReplyComposerSheetState extends State<ReplyComposerSheet>
    with TickerProviderStateMixin {
  static const double _collapsedHeightFactor = 0.9;
  static const double _collapsedSheetInset = 12;
  static const double _collapsedBorderRadius = 28;
  static const double _dragDistanceToFullscreen = 140;
  static const double _fullscreenSnapThreshold = 0.62;
  static const Duration _sheetSnapDuration = Duration(milliseconds: 260);
  static const double _dismissDragThreshold = 120;
  static const double _dismissDragVelocity = 1100;
  static const double _maxDismissDragOffset = 260;

  late ReplyDraft _draft;
  bool _isSubmitting = false;
  String? _statusMessage;
  bool _isApplyingProgrammaticRichTextUpdate = false;
  bool _isNormalizingCollapsedSelection = false;
  late final ThreadPublishService _publishService;
  late final ThreadVideoUploadService _videoUploadService;
  late final ComposerImagePickerService _imagePickerService;
  final HtmlExportService _htmlExportService = const HtmlExportService();

  late final quill.QuillController _controller;
  late final AnimationController _fullscreenController;
  late final AnimationController _dismissOffsetController;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _publishService = widget.publishService ?? const StubThreadPublishService();
    _videoUploadService =
        widget.videoUploadService ?? const StubThreadVideoUploadService();
    _imagePickerService =
        widget.imagePickerService ?? DeviceComposerImagePickerService();
    _controller = quill.QuillController(
      document: _documentFromDeltaJson(_draft.deltaJson),
      selection: const TextSelection.collapsed(offset: 0),
    )..addListener(_handleRichTextChanged);
    _fullscreenController = AnimationController(
      vsync: this,
      duration: _sheetSnapDuration,
    )..addListener(_handleAnimationProgressChanged);
    _dismissOffsetController = AnimationController.unbounded(
      vsync: this,
      value: 0,
    )..addListener(_handleAnimationProgressChanged);
  }

  void _handleAnimationProgressChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _insertDetailsEmbed() {
    _insertBlockEmbedWithLineBreaks(
      BluefishDetailsEmbed(BluefishDetailsEmbedData.initial()),
    );
  }

  Future<void> _pickAndInsertImage() async {
    try {
      final pickedImage = await _imagePickerService.pickImage();
      if (pickedImage == null) {
        setState(() {
          _statusMessage = '已取消选择图片。';
        });
        return;
      }

      _insertPickedImage(pickedImage);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = '选择图片失败，请稍后再试。';
      });
    }
  }

  void _insertPickedImage(PickedComposerImage pickedImage) {
    final attachmentId = _createComposerId('reply-image-attachment');
    final label = pickedImage.name.trim().isEmpty
        ? '回复图片 ${_draft.attachments.length + 1}'
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

    setState(() {
      _draft = _draft.copyWith(
        attachments: <ComposerAttachment>[..._draft.attachments, attachment],
        clearBodyHtml: true,
      );
      _statusMessage = '已添加图片：$label';
    });

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

  Future<void> _addVideoPlaceholder() async {
    final pendingVideo = ComposerAttachment(
      id: _createComposerId('reply-video-attachment'),
      type: ComposerAttachmentType.video,
      uploadState: ComposerUploadState.uploading,
      label: '回复视频草稿',
      duration: const Duration(seconds: 42),
      progress: 0.18,
    );

    setState(() {
      _draft = _draft.copyWith(
        attachments: <ComposerAttachment>[..._draft.attachments, pendingVideo],
        clearBodyHtml: true,
      );
      _statusMessage = '正在模拟为回复附件上传视频。';
    });

    try {
      final uploaded = await _videoUploadService.uploadVideo(pendingVideo);
      if (!mounted) {
        return;
      }

      setState(() {
        _draft = _draft.copyWith(
          attachments: _draft.attachments
              .map(
                (attachment) =>
                    attachment.id == pendingVideo.id ? uploaded : attachment,
              )
              .toList(growable: false),
          clearBodyHtml: true,
        );
        _statusMessage = '回复视频草稿已就绪，后续接线时可直接沿用。';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _draft = _draft.copyWith(
          attachments: _draft.attachments
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
        _statusMessage = '回复视频草稿上传失败。';
      });
    }
  }

  void _updateDetailsEmbed(int offset, BluefishDetailsEmbedData data) {
    _replaceEmbed(offset, BluefishDetailsEmbed(data));
  }

  void _updateImagePlaceholderEmbed(
    int offset,
    BluefishImagePlaceholderEmbedData data,
  ) {
    _replaceEmbed(offset, BluefishImagePlaceholderEmbed(data));
  }

  void _removeEmbed(int offset) {
    _controller.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }

  void _removeAttachment(String attachmentId) {
    final nextAttachments = _draft.attachments
        .where((attachment) => attachment.id != attachmentId)
        .toList(growable: false);

    if (nextAttachments.length == _draft.attachments.length) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        attachments: nextAttachments,
        clearBodyHtml: true,
      );
    });

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
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_draft.hasPublishableContent) {
      setState(() {
        _statusMessage = '回复草稿还没有可发送内容。';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    final draftForSubmit = _draft.copyWith(
      bodyHtml: _htmlExportService.exportRichText(_draft.deltaJson),
      clearBodyHtml: false,
    );

    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(draftForSubmit);
      } else {
        final receipt = await _publishService.publishReply(draftForSubmit);
        _statusMessage = receipt.summary;
      }

      if (!mounted) {
        return;
      }
      if (widget.closeOnSubmit) {
        Navigator.of(context).pop(draftForSubmit);
      } else {
        setState(() {
          _draft = draftForSubmit;
          _statusMessage ??= '回复草稿已保存。';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = '回复草稿发送失败。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
    final nextAttachments = _synchronizeImageAttachments(nextDeltaJson);
    final deltaChanged =
        jsonEncode(nextDeltaJson) != jsonEncode(_draft.deltaJson);
    final attachmentsChanged =
        jsonEncode(_attachmentSignature(nextAttachments)) !=
        jsonEncode(_attachmentSignature(_draft.attachments));

    if (!deltaChanged && !attachmentsChanged) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        deltaJson: nextDeltaJson,
        attachments: nextAttachments,
        clearBodyHtml: true,
      );
    });
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

    return _draft.attachments
        .where(
          (attachment) =>
              attachment.type == ComposerAttachmentType.video ||
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

  List<Map<String, Object?>> _attachmentSignature(
    List<ComposerAttachment> attachments,
  ) {
    return attachments
        .map(
          (attachment) => <String, Object?>{
            'id': attachment.id,
            'type': attachment.type.name,
            'state': attachment.uploadState.name,
            'label': attachment.label,
            'localPath': attachment.localPath,
            'bytes': attachment.bytes,
            'progress': attachment.progress,
          },
        )
        .toList(growable: false);
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

  String _createComposerId(String prefix) {
    _replyComposerIdCounter += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_replyComposerIdCounter';
  }

  void _handleSheetResizeDragStart(DragStartDetails details) {
    _fullscreenController.stop();
    _dismissOffsetController.stop();
  }

  void _handleSheetResizeDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    if (delta < 0 && _dismissOffsetController.value > 0) {
      _dismissOffsetController.value = (_dismissOffsetController.value + delta)
          .clamp(0.0, _maxDismissDragOffset);
      return;
    }

    if (delta > 0 && _fullscreenController.value <= 0.0) {
      _dismissOffsetController.value = (_dismissOffsetController.value + delta)
          .clamp(0.0, _maxDismissDragOffset);
      return;
    }

    final nextValue =
        (_fullscreenController.value - (delta / _dragDistanceToFullscreen))
            .clamp(0.0, 1.0);
    if (nextValue == _fullscreenController.value) {
      return;
    }
    _fullscreenController.value = nextValue;
  }

  void _handleSheetResizeDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dismissOffsetController.value >= _dismissDragThreshold ||
        velocity >= _dismissDragVelocity) {
      Navigator.of(context).maybePop();
      return;
    }

    if (_dismissOffsetController.value > 0) {
      _dismissOffsetController.animateTo(
        0,
        duration: _sheetSnapDuration,
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final bool shouldCollapse = velocity > 700;
    final bool shouldExpand =
        !shouldCollapse &&
        (velocity < -700 ||
            _fullscreenController.value >= _fullscreenSnapThreshold);
    final target = shouldExpand ? 1.0 : 0.0;

    _fullscreenController.animateTo(target, curve: Curves.easeOutCubic);
  }

  bool get _isFullscreen => _fullscreenController.value >= 0.98;

  void _toggleFullscreen() {
    final target = _isFullscreen ? 0.0 : 1.0;
    _fullscreenController.animateTo(target, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _fullscreenController
      ..removeListener(_handleAnimationProgressChanged)
      ..dispose();
    _dismissOffsetController
      ..removeListener(_handleAnimationProgressChanged)
      ..dispose();
    _controller
      ..removeListener(_handleRichTextChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final fullscreenProgress = _fullscreenController.value;
    final sheetHeightFactor = ui.lerpDouble(
      _collapsedHeightFactor,
      1,
      fullscreenProgress,
    )!;
    final sheetInset = ui.lerpDouble(
      _collapsedSheetInset,
      0,
      fullscreenProgress,
    )!;
    final sheetRadius = ui.lerpDouble(
      _collapsedBorderRadius,
      0,
      fullscreenProgress,
    )!;
    final handleZoneHeight = ui.lerpDouble(24, 32, fullscreenProgress)!;
    final handleWidth = ui.lerpDouble(42, 58, fullscreenProgress)!;
    final handleOpacity = ui.lerpDouble(0.42, 0.8, fullscreenProgress)!;
    final hasContext =
        (widget.contextLabel?.trim().isNotEmpty ?? false) ||
        (widget.contextPreview?.trim().isNotEmpty ?? false);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: sheetHeightFactor,
            child: Padding(
              padding: EdgeInsets.all(sheetInset),
              child: Transform.translate(
                offset: Offset(0, _dismissOffsetController.value),
                child: Material(
                  key: const ValueKey('reply-composer-sheet-surface'),
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(sheetRadius),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: GestureDetector(
                          key: const ValueKey(
                            'reply-composer-drag-handle-zone',
                          ),
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragStart: _handleSheetResizeDragStart,
                          onVerticalDragUpdate: _handleSheetResizeDragUpdate,
                          onVerticalDragEnd: _handleSheetResizeDragEnd,
                          child: SizedBox(
                            height: handleZoneHeight,
                            child: Center(
                              child: Container(
                                width: handleWidth,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: handleOpacity),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.allowVideoAttachments
                                        ? '支持富文本、折叠说明、图片和视频附件草稿。'
                                        : '支持富文本、折叠说明和图片。',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: const ValueKey(
                                'reply-composer-fullscreen-toggle',
                              ),
                              tooltip: _isFullscreen ? '恢复默认大小' : '全屏显示',
                              onPressed: _toggleFullscreen,
                              icon: Icon(
                                _isFullscreen
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          key: const ValueKey('reply-composer-content-scroll'),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          children: [
                            if (hasContext)
                              _ComposerContextPreviewCard(
                                contextLabel: widget.contextLabel,
                                contextPreview: widget.contextPreview,
                              ),
                            if (hasContext) const SizedBox(height: 12),
                            QuillComposerToolbar(
                              controller: _controller,
                              onInsertDetails: _insertDetailsEmbed,
                              onInsertImagePlaceholder: _pickAndInsertImage,
                              onInsertVideoPlaceholder:
                                  widget.allowVideoAttachments
                                  ? _addVideoPlaceholder
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            QuillComposerEditor(
                              controller: _controller,
                              placeholder: widget.placeholder,
                              onDetailsEmbedChanged: _updateDetailsEmbed,
                              onImagePlaceholderChanged:
                                  _updateImagePlaceholderEmbed,
                              onEmbedRemoved: _removeEmbed,
                            ),
                            const SizedBox(height: 12),
                            ComposerAccessoryPanel(
                              title: '附件与状态',
                              description: '已选择的图片和视频附件会显示在这里，后续可以直接接入真实上传链路。',
                              attachments: _draft.attachments,
                              onRemoveAttachment: _removeAttachment,
                            ),
                            if (_statusMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _statusMessage!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _draft.hasPublishableContent
                                    ? '草稿可发送'
                                    : '请先输入正文、插入折叠说明/图片，或在开启视频扩展后添加视频',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).maybePop(),
                              child: const Text('取消'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _isSubmitting ? null : _submit,
                              icon: _isSubmitting
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(widget.submitLabel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerContextPreviewCard extends StatefulWidget {
  static const double _collapsedPreviewHeight = 132;

  final String? contextLabel;
  final String? contextPreview;

  const _ComposerContextPreviewCard({
    required this.contextLabel,
    required this.contextPreview,
  });

  @override
  State<_ComposerContextPreviewCard> createState() =>
      _ComposerContextPreviewCardState();
}

class _ComposerContextPreviewCardState
    extends State<_ComposerContextPreviewCard> {
  final GlobalKey _measurementKey = GlobalKey();
  bool _needsCollapse = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCollapsedState());
  }

  @override
  void didUpdateWidget(covariant _ComposerContextPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contextLabel != widget.contextLabel ||
        oldWidget.contextPreview != widget.contextPreview) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncCollapsedState(),
      );
    }
  }

  void _syncCollapsedState() {
    final renderObject = _measurementKey.currentContext?.findRenderObject();
    if (!mounted || renderObject is! RenderBox) {
      return;
    }

    final shouldCollapse =
        renderObject.size.height >
        _ComposerContextPreviewCard._collapsedPreviewHeight;
    if (shouldCollapse == _needsCollapse) {
      return;
    }

    setState(() {
      _needsCollapse = shouldCollapse;
      if (!shouldCollapse) {
        _isExpanded = false;
      }
    });
  }

  void _toggleExpanded() {
    if (!_needsCollapse) {
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final previewText = widget.contextPreview?.trim();
    final hasPreview = previewText != null && previewText.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewBody = _ComposerContextPreviewBody(
          label: widget.contextLabel,
          preview: previewText,
        );
        final previewContent = _needsCollapse && !_isExpanded
            ? SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: previewBody,
              )
            : previewBody;

        return Stack(
          children: [
            Offstage(
              child: SizedBox(
                width: constraints.maxWidth,
                child: _ComposerContextPreviewBody(
                  key: _measurementKey,
                  label: widget.contextLabel,
                  preview: previewText,
                ),
              ),
            ),
            Container(
              key: const ValueKey('reply-composer-context-card'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: ClipRect(
                      child: SizedBox(
                        key: const ValueKey('reply-composer-context-preview'),
                        width: double.infinity,
                        height: _needsCollapse && !_isExpanded
                            ? _ComposerContextPreviewCard
                                  ._collapsedPreviewHeight
                            : null,
                        child: Stack(
                          children: [
                            previewContent,
                            if (_needsCollapse && !_isExpanded && hasPreview)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          colorScheme.surfaceContainerLow
                                              .withValues(alpha: 0),
                                          colorScheme.surfaceContainerLow,
                                        ],
                                      ),
                                    ),
                                    child: const SizedBox(height: 52),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_needsCollapse) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('reply-composer-context-toggle'),
                        onPressed: _toggleExpanded,
                        icon: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        label: Text(_isExpanded ? '收起回复' : '展开回复'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          textStyle: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ComposerContextPreviewBody extends StatelessWidget {
  final String? label;
  final String? preview;

  const _ComposerContextPreviewBody({super.key, this.label, this.preview});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final trimmedLabel = label?.trim();
    final trimmedPreview = preview?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trimmedLabel != null && trimmedLabel.isNotEmpty)
          Text(
            trimmedLabel,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (trimmedPreview != null && trimmedPreview.isNotEmpty) ...[
          if (trimmedLabel != null && trimmedLabel.isNotEmpty)
            const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Text(
                trimmedPreview,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

int _replyComposerIdCounter = 0;

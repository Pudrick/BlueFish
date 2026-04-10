import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/composer/quill_embed_models.dart';
import '../../models/composer/reply_draft.dart';
import '../../services/composer/composer_image_picker_service.dart';
import 'package:bluefish/services/composer/thread_publish_service.dart';
import 'package:bluefish/services/composer/thread_video_upload_service.dart';
import '../../viewModels/rich_text_composer_controller.dart';
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

  late final RichTextComposerController _composer;
  bool _isSubmitting = false;
  late final ThreadPublishService _publishService;
  late final AnimationController _fullscreenController;
  late final AnimationController _dismissOffsetController;

  ReplyDraft get _draft => ReplyDraft.fromComposerContent(_composer.content);

  @override
  void initState() {
    super.initState();
    _publishService = widget.publishService ?? const StubThreadPublishService();
    _composer = RichTextComposerController(
      initialContent: widget.initialDraft.composerContent,
      videoUploadService: widget.videoUploadService,
      imagePickerService: widget.imagePickerService,
      imageAttachmentLabelPrefix: '回复图片',
      videoAttachmentLabel: '回复视频草稿',
      videoUploadStartedMessage: '正在模拟为回复附件上传视频。',
      videoUploadReadyMessage: '回复视频草稿已就绪，后续接线时可直接沿用。',
      videoUploadFailedMessage: '回复视频草稿上传失败。',
    )..addListener(_handleComposerChanged);
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

  void _handleComposerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _insertDetailsEmbed() {
    _composer.insertDetailsEmbed();
  }

  Future<void> _pickAndInsertImage() {
    return _composer.pickAndInsertImage();
  }

  Future<void> _addVideoPlaceholder() {
    return _composer.addVideoAttachment();
  }

  void _updateDetailsEmbed(int offset, BluefishDetailsEmbedData data) {
    _composer.updateDetailsEmbed(offset, data);
  }

  void _updateImagePlaceholderEmbed(
    int offset,
    BluefishImagePlaceholderEmbedData data,
  ) {
    _composer.updateImagePlaceholderEmbed(offset, data);
  }

  void _removeEmbed(int offset) {
    _composer.removeEmbed(offset);
  }

  void _removeAttachment(String attachmentId) {
    _composer.removeAttachment(attachmentId);
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_composer.hasPublishableContent) {
      _composer.setStatusMessage('回复草稿还没有可发送内容。');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    _composer.clearStatusMessage();

    final draftForSubmit = ReplyDraft.fromComposerContent(
      _composer.buildExportedContent(),
    );

    try {
      String? successMessage;
      if (widget.onSubmit != null) {
        await widget.onSubmit!(draftForSubmit);
      } else {
        final receipt = await _publishService.publishReply(draftForSubmit);
        successMessage = receipt.summary;
      }

      if (!mounted) {
        return;
      }
      if (widget.closeOnSubmit) {
        Navigator.of(context).pop(draftForSubmit);
      } else {
        _composer.replaceContent(
          draftForSubmit.composerContent,
          reloadDocument: false,
        );
        _composer.setStatusMessage(successMessage ?? '回复草稿已保存。');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _composer.setStatusMessage('回复草稿发送失败。');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
    _composer
      ..removeListener(_handleComposerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final statusMessage = _composer.statusMessage;
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
                              controller: _composer.controller,
                              onInsertDetails: _insertDetailsEmbed,
                              onInsertImagePlaceholder: _pickAndInsertImage,
                              onInsertVideoPlaceholder:
                                  widget.allowVideoAttachments
                                  ? _addVideoPlaceholder
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            QuillComposerEditor(
                              controller: _composer.controller,
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
                              attachments: draft.attachments,
                              onRemoveAttachment: _removeAttachment,
                            ),
                            if (statusMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                statusMessage,
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
                                _composer.hasPublishableContent
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

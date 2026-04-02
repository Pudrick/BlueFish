import 'package:flutter/material.dart';

import '../../models/composer/composer_attachment.dart';
import '../../models/composer/composer_document.dart';
import '../../models/composer/reply_draft.dart';
import '../../services/thread_publish_service.dart';
import '../../services/thread_video_upload_service.dart';
import 'composer_accessory_panel.dart';
import 'composer_editor.dart';
import 'composer_toolbar.dart';

Future<ReplyDraft?> showReplyComposerSheet({
  required BuildContext context,
  String title = '发送回复',
  String submitLabel = '发送',
  String? contextLabel,
  String? contextPreview,
  ReplyDraft? initialDraft,
  bool allowVideoAttachments = false,
  Future<void> Function(ReplyDraft draft)? onSubmit,
  ThreadPublishService? publishService,
  ThreadVideoUploadService? videoUploadService,
}) {
  return showGeneralDialog<ReplyDraft>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return ReplyComposerSheet(
        title: title,
        submitLabel: submitLabel,
        contextLabel: contextLabel,
        contextPreview: contextPreview,
        initialDraft: initialDraft ?? ReplyDraft.empty(),
        allowVideoAttachments: allowVideoAttachments,
        onSubmit: onSubmit,
        publishService: publishService,
        videoUploadService: videoUploadService,
      );
    },
  );
}

class ReplyComposerSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String? contextLabel;
  final String? contextPreview;
  final ReplyDraft initialDraft;
  final bool allowVideoAttachments;
  final Future<void> Function(ReplyDraft draft)? onSubmit;
  final ThreadPublishService? publishService;
  final ThreadVideoUploadService? videoUploadService;

  const ReplyComposerSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.initialDraft,
    this.contextLabel,
    this.contextPreview,
    this.allowVideoAttachments = false,
    this.onSubmit,
    this.publishService,
    this.videoUploadService,
  });

  @override
  State<ReplyComposerSheet> createState() => _ReplyComposerSheetState();
}

class _ReplyComposerSheetState extends State<ReplyComposerSheet> {
  late ReplyDraft _draft;
  bool _isSubmitting = false;
  String? _statusMessage;
  late final ThreadPublishService _publishService;
  late final ThreadVideoUploadService _videoUploadService;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _publishService = widget.publishService ?? const StubThreadPublishService();
    _videoUploadService =
        widget.videoUploadService ?? const StubThreadVideoUploadService();
  }

  void _addParagraphBlock() {
    setState(() {
      _draft = _draft.copyWith(
        document: _draft.document.append(ComposerParagraphBlock.empty()),
      );
    });
  }

  void _addDetailsBlock() {
    setState(() {
      _draft = _draft.copyWith(
        document: _draft.document.append(ComposerDetailsBlock.empty()),
      );
    });
  }

  void _addImagePlaceholder() {
    final attachmentId = createComposerId('reply-image-attachment');
    final attachment = ComposerAttachment(
      id: attachmentId,
      type: ComposerAttachmentType.image,
      uploadState: ComposerUploadState.pending,
      label: '回复图片占位',
    );
    final block = ComposerImageBlock.placeholder(attachmentId: attachmentId);

    setState(() {
      _draft = _draft.copyWith(
        document: _draft.document.append(block),
        attachments: <ComposerAttachment>[..._draft.attachments, attachment],
      );
      _statusMessage = '已插入回复图片占位。';
    });
  }

  Future<void> _addVideoPlaceholder() async {
    final pendingVideo = ComposerAttachment(
      id: createComposerId('reply-video-attachment'),
      type: ComposerAttachmentType.video,
      uploadState: ComposerUploadState.uploading,
      label: '回复视频草稿',
      duration: const Duration(seconds: 42),
      progress: 0.18,
    );

    setState(() {
      _draft = _draft.copyWith(
        attachments: <ComposerAttachment>[..._draft.attachments, pendingVideo],
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
              .map((attachment) {
                return attachment.id == pendingVideo.id ? uploaded : attachment;
              })
              .toList(growable: false),
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
        );
        _statusMessage = '回复视频草稿上传失败。';
      });
    }
  }

  void _updateParagraph(String blockId, String value) {
    final block = _draft.document.findBlock<ComposerParagraphBlock>(blockId);
    if (block == null) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        document: _draft.document.replaceBlock(
          block.copyWith(
            children: <ComposerInlineNode>[ComposerTextNode(value)],
          ),
        ),
      );
    });
  }

  void _updateDetailsSummary(String blockId, String value) {
    final block = _draft.document.findBlock<ComposerDetailsBlock>(blockId);
    if (block == null) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        document: _draft.document.replaceBlock(
          block.copyWith(
            summary: <ComposerInlineNode>[ComposerTextNode(value)],
          ),
        ),
      );
    });
  }

  void _updateDetailsBody(String blockId, String value) {
    final block = _draft.document.findBlock<ComposerDetailsBlock>(blockId);
    if (block == null) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        document: _draft.document.replaceBlock(
          block.copyWith(
            children: <ComposerBlockNode>[
              ComposerParagraphBlock(
                id:
                    block.children
                        .whereType<ComposerParagraphBlock>()
                        .firstOrNull
                        ?.id ??
                    createComposerId('reply-details-body'),
                children: <ComposerInlineNode>[ComposerTextNode(value)],
              ),
            ],
          ),
        ),
      );
    });
  }

  void _updateImageCaption(String blockId, String value) {
    final block = _draft.document.findBlock<ComposerImageBlock>(blockId);
    if (block == null) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        document: _draft.document.replaceBlock(block.copyWith(caption: value)),
      );
    });
  }

  void _removeBlock(String blockId) {
    final imageBlock = _draft.document.findBlock<ComposerImageBlock>(blockId);
    if (imageBlock != null) {
      _removeAttachment(imageBlock.attachmentId);
      return;
    }

    final nextDocument = _draft.document.removeBlock(blockId);
    setState(() {
      _draft = _draft.copyWith(
        document: nextDocument.blocks.isEmpty
            ? ComposerDocument.withSingleParagraph()
            : nextDocument,
      );
    });
  }

  void _removeAttachment(String attachmentId) {
    final nextDocument = ComposerDocument(
      blocks: _draft.document.blocks
          .where(
            (block) =>
                block is! ComposerImageBlock ||
                block.attachmentId != attachmentId,
          )
          .toList(growable: false),
    );

    setState(() {
      _draft = _draft.copyWith(
        attachments: _draft.attachments
            .where((attachment) => attachment.id != attachmentId)
            .toList(growable: false),
        document: nextDocument.blocks.isEmpty
            ? ComposerDocument.withSingleParagraph()
            : nextDocument,
      );
    });
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

    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(_draft);
      } else {
        final receipt = await _publishService.publishReply(_draft);
        _statusMessage = receipt.summary;
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_draft);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
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
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
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
                                      ? '当前回复壳子已预留视频附件扩展。'
                                      : '当前回复壳子先只开放富文本与图片占位。',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
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
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        children: [
                          if (hasContext)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.contextLabel != null &&
                                      widget.contextLabel!.trim().isNotEmpty)
                                    Text(
                                      widget.contextLabel!,
                                      style: textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  if (widget.contextPreview != null &&
                                      widget.contextPreview!
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.contextPreview!,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          if (hasContext) const SizedBox(height: 12),
                          ComposerToolbar(
                            onAddParagraph: _addParagraphBlock,
                            onAddDetails: _addDetailsBlock,
                            onAddImage: _addImagePlaceholder,
                            onAddVideo: widget.allowVideoAttachments
                                ? _addVideoPlaceholder
                                : null,
                          ),
                          const SizedBox(height: 12),
                          ComposerEditor(
                            document: _draft.document,
                            onParagraphChanged: _updateParagraph,
                            onDetailsSummaryChanged: _updateDetailsSummary,
                            onDetailsBodyChanged: _updateDetailsBody,
                            onImageCaptionChanged: _updateImageCaption,
                            onRemoveBlock: _removeBlock,
                          ),
                          const SizedBox(height: 12),
                          ComposerAccessoryPanel(
                            title: '附件与状态',
                            description:
                                '这里先提供回复骨架，不接入现有 reply 模块。视频附件能力已经在数据层和 stub 上传链路中预留。',
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
                                  : '请先输入正文、插入图片，或在未来开启视频附件后添加视频',
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
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

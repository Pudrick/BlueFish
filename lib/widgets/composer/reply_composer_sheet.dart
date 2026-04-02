import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/composer/composer_attachment.dart';
import '../../models/composer/quill_embed_models.dart';
import '../../models/composer/reply_draft.dart';
import '../../services/composer/html_export_service.dart';
import '../../services/thread_publish_service.dart';
import '../../services/thread_video_upload_service.dart';
import 'composer_accessory_panel.dart';
import 'quill_composer_editor.dart';
import 'quill_composer_toolbar.dart';

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
        placeholder: placeholder,
        contextLabel: contextLabel,
        contextPreview: contextPreview,
        initialDraft: initialDraft ?? ReplyDraft.empty(),
        allowVideoAttachments: allowVideoAttachments,
        closeOnSubmit: closeOnSubmit,
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
  final String placeholder;
  final String? contextLabel;
  final String? contextPreview;
  final ReplyDraft initialDraft;
  final bool allowVideoAttachments;
  final bool closeOnSubmit;
  final Future<void> Function(ReplyDraft draft)? onSubmit;
  final ThreadPublishService? publishService;
  final ThreadVideoUploadService? videoUploadService;

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
  final HtmlExportService _htmlExportService = const HtmlExportService();

  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _publishService = widget.publishService ?? const StubThreadPublishService();
    _videoUploadService =
        widget.videoUploadService ?? const StubThreadVideoUploadService();
    _controller = quill.QuillController(
      document: _documentFromDeltaJson(_draft.deltaJson),
      selection: const TextSelection.collapsed(offset: 0),
    )..addListener(_handleRichTextChanged);
  }

  void _insertDetailsEmbed() {
    _insertEmbed(BluefishDetailsEmbed(BluefishDetailsEmbedData.initial()));
  }

  void _insertImagePlaceholder() {
    final attachmentId = _createComposerId('reply-image-attachment');
    final attachment = ComposerAttachment(
      id: attachmentId,
      type: ComposerAttachmentType.image,
      uploadState: ComposerUploadState.pending,
      label: '回复图片占位 ${_draft.attachments.length + 1}',
    );

    setState(() {
      _draft = _draft.copyWith(
        attachments: <ComposerAttachment>[..._draft.attachments, attachment],
        clearBodyHtml: true,
      );
      _statusMessage = '已插入回复图片占位。';
    });

    _insertEmbed(
      BluefishImagePlaceholderEmbed(
        BluefishImagePlaceholderEmbedData(
          attachmentId: attachmentId,
          label: attachment.label,
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

  void _insertEmbed(quill.Embeddable embed) {
    final selection = _normalizedSelection();
    final replaceLength = selection.end - selection.start;
    _controller.replaceText(
      selection.start,
      replaceLength,
      embed,
      TextSelection.collapsed(offset: selection.start + 1),
    );
  }

  void _replaceEmbed(int offset, quill.Embeddable embed) {
    _controller.replaceText(
      offset,
      1,
      embed,
      TextSelection.collapsed(offset: offset + 1),
    );
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

  @override
  void dispose() {
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
                                      ? '支持富文本、折叠说明、图片占位和视频附件草稿。'
                                      : '支持富文本、折叠说明和图片占位。',
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
                          QuillComposerToolbar(
                            controller: _controller,
                            onInsertDetails: _insertDetailsEmbed,
                            onInsertImagePlaceholder: _insertImagePlaceholder,
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
                            description: '已添加的图片和视频附件会显示在这里，后续可以直接接入真实上传链路。',
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
                                  : '请先输入正文、插入折叠说明/图片占位，或在开启视频扩展后添加视频',
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

int _replyComposerIdCounter = 0;

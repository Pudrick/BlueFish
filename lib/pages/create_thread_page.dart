import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/composer/composer_attachment.dart';
import '../models/composer/thread_draft.dart';
import '../router/app_routes.dart';
import '../viewModels/thread_compose_view_model.dart';
import '../widgets/composer/composer_accessory_panel.dart';
import '../widgets/composer/composer_editor.dart';
import '../widgets/composer/composer_preview.dart';
import '../widgets/composer/composer_toolbar.dart';

class CreateThreadPage extends StatelessWidget {
  final ThreadComposeViewModel? viewModel;
  final bool showAppBar;

  const CreateThreadPage({super.key, this.viewModel, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final child = _CreateThreadPageScaffold(showAppBar: showAppBar);
    final currentViewModel = viewModel;

    if (currentViewModel != null) {
      return ChangeNotifierProvider<ThreadComposeViewModel>.value(
        value: currentViewModel,
        child: child,
      );
    }

    return ChangeNotifierProvider<ThreadComposeViewModel>(
      create: (_) => ThreadComposeViewModel(),
      child: child,
    );
  }
}

class _CreateThreadPageScaffold extends StatefulWidget {
  final bool showAppBar;

  const _CreateThreadPageScaffold({required this.showAppBar});

  @override
  State<_CreateThreadPageScaffold> createState() =>
      _CreateThreadPageScaffoldState();
}

class _CreateThreadPageScaffoldState extends State<_CreateThreadPageScaffold> {
  final TextEditingController _titleController = TextEditingController();
  bool _showPreview = true;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleModeChanged(
    BuildContext context,
    ThreadComposeMode nextMode,
  ) async {
    final viewModel = context.read<ThreadComposeViewModel>();
    final warning = viewModel.describeModeSwitch(nextMode);
    if (warning == null) {
      viewModel.setMode(nextMode);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认切换模式'),
          content: Text(warning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续切换'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    viewModel.setMode(nextMode, discardCurrentModeContent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThreadComposeViewModel>(
      builder: (context, viewModel, child) {
        if (_titleController.text != viewModel.currentTitle) {
          _titleController.value = TextEditingValue(
            text: viewModel.currentTitle,
            selection: TextSelection.collapsed(
              offset: viewModel.currentTitle.length,
            ),
          );
        }

        final richTextDraft = viewModel.richTextDraft;
        final videoDraft = viewModel.videoDraft;
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final publishIcon = viewModel.isSubmitting
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: viewModel.canPublish
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              )
            : Icon(
                viewModel.mode == ThreadComposeMode.videoOnly
                    ? Icons.smart_display_outlined
                    : Icons.send_rounded,
              );
        final publishLabel = Text(
          viewModel.mode == ThreadComposeMode.videoOnly ? '发布视频主贴' : '发布图文主贴',
        );

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  automaticallyImplyLeading: false,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leadingWidth: 72,
                  leading: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        key: const ValueKey('create_thread_back_button'),
                        tooltip: '返回帖子列表',
                        onPressed: () {
                          context.popOrGoThreadList();
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  ),
                  title: const Text('发送主贴'),
                )
              : null,
          floatingActionButton: FloatingActionButton.extended(
            key: const ValueKey('create_thread_publish_button'),
            onPressed: viewModel.canPublish
                ? viewModel.publishCurrentDraft
                : null,
            icon: publishIcon,
            label: publishLabel,
            elevation: 2,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 124),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '当前是独立部署阶段：只搭建 composer 骨架、主贴双模式和回复弹层壳子，不接入现有路由、接口或其他模块。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('create_thread_title_field'),
                  controller: _titleController,
                  onChanged: viewModel.updateTitle,
                  decoration: InputDecoration(
                    labelText: '主贴标题',
                    hintText: '输入标题',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ModeSelector(
                  currentMode: viewModel.mode,
                  onModeSelected: (mode) => _handleModeChanged(context, mode),
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: viewModel.mode == ThreadComposeMode.richText
                      ? _RichTextModeSection(
                          key: const ValueKey('rich-text-mode'),
                          draft: richTextDraft,
                          showPreview: _showPreview,
                          onPreviewChanged: (value) {
                            setState(() {
                              _showPreview = value;
                            });
                          },
                        )
                      : _VideoModeSection(
                          key: const ValueKey('video-only-mode'),
                          draft: videoDraft,
                        ),
                ),
                const SizedBox(height: 18),
                if (viewModel.statusMessage != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      viewModel.statusMessage!,
                      style: textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final ThreadComposeMode currentMode;
  final ValueChanged<ThreadComposeMode> onModeSelected;

  const _ModeSelector({
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThreadComposeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment<ThreadComposeMode>(
          value: ThreadComposeMode.richText,
          icon: Icon(Icons.edit_note_rounded),
          label: Text('图文主贴'),
        ),
        ButtonSegment<ThreadComposeMode>(
          value: ThreadComposeMode.videoOnly,
          icon: Icon(Icons.ondemand_video_outlined),
          label: Text('视频主贴'),
        ),
      ],
      selected: <ThreadComposeMode>{currentMode},
      onSelectionChanged: (selection) {
        final nextMode = selection.firstOrNull;
        if (nextMode != null) {
          onModeSelected(nextMode);
        }
      },
    );
  }
}

class _RichTextModeSection extends StatelessWidget {
  final RichTextThreadDraft draft;
  final bool showPreview;
  final ValueChanged<bool> onPreviewChanged;

  const _RichTextModeSection({
    super.key,
    required this.draft,
    required this.showPreview,
    required this.onPreviewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ThreadComposeViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '图文主贴编辑区',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ComposerToolbar(
          onAddParagraph: viewModel.addParagraphBlock,
          onAddDetails: viewModel.addDetailsBlock,
          onAddImage: viewModel.addImagePlaceholder,
        ),
        const SizedBox(height: 12),
        ComposerEditor(
          document: draft.document,
          onParagraphChanged: viewModel.updateParagraphText,
          onDetailsSummaryChanged: viewModel.updateDetailsSummaryText,
          onDetailsBodyChanged: viewModel.updateDetailsBodyText,
          onImageCaptionChanged: viewModel.updateImageCaption,
          onRemoveBlock: viewModel.removeRichTextBlock,
        ),
        const SizedBox(height: 12),
        ComposerAccessoryPanel(
          title: '附件与后续扩展',
          description: '这里先保留图片附件占位；视频能力先只开放给视频主贴，但附件层已经按后续“回贴发视频”预留。',
          attachments: draft.attachments,
          onRemoveAttachment: viewModel.removeRichTextAttachment,
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: showPreview,
          onChanged: onPreviewChanged,
          contentPadding: EdgeInsets.zero,
          title: const Text('显示 HTML 预览'),
        ),
        if (showPreview) ...[
          const SizedBox(height: 8),
          ComposerPreview(title: draft.title, document: draft.document),
        ],
      ],
    );
  }
}

class _VideoModeSection extends StatelessWidget {
  final VideoThreadDraft draft;

  const _VideoModeSection({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ThreadComposeViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final attachment = draft.video;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '视频主贴编辑区',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ComposerToolbar(onAddVideo: viewModel.selectVideoPlaceholder),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '视频草稿',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (attachment == null)
                Text(
                  '当前还没有视频。视频主贴模式只保留标题和一段视频，不包含正文。',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                )
              else
                _VideoDraftCard(attachment: attachment),
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: viewModel.selectVideoPlaceholder,
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(attachment == null ? '选择视频' : '替换视频'),
                  ),
                  const SizedBox(width: 10),
                  if (attachment != null)
                    TextButton.icon(
                      onPressed: viewModel.clearVideoDraft,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('移除视频'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ComposerAccessoryPanel(
          title: '模式规则',
          description:
              '视频主贴当前只允许“标题 + 单视频”。这里不接入正文编辑器，后续如果要支持回贴发视频，会复用同一套视频附件层。',
          attachments: attachment == null
              ? const <ComposerAttachment>[]
              : <ComposerAttachment>[attachment],
        ),
      ],
    );
  }
}

class _VideoDraftCard extends StatelessWidget {
  final ComposerAttachment attachment;

  const _VideoDraftCard({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final duration = attachment.duration;
    final durationText = duration == null
        ? '未知时长'
        : '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.smart_display_outlined,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '状态：${switch (attachment.uploadState) {
                    ComposerUploadState.pending => '待处理',
                    ComposerUploadState.uploading => '上传中',
                    ComposerUploadState.uploaded => '已就绪',
                    ComposerUploadState.failed => '失败',
                  }} · 时长：$durationText',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension<T> on Set<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

import 'package:flutter/material.dart';

import '../../models/composer/quill_embed_models.dart';
import 'composer_image_preview_provider.dart';

class DetailsEmbedCard extends StatefulWidget {
  final BluefishDetailsEmbedData data;
  final bool readOnly;
  final ValueChanged<BluefishDetailsEmbedData>? onChanged;
  final VoidCallback? onRemove;

  const DetailsEmbedCard({
    super.key,
    required this.data,
    required this.readOnly,
    this.onChanged,
    this.onRemove,
  });

  @override
  State<DetailsEmbedCard> createState() => _DetailsEmbedCardState();
}

class _DetailsEmbedCardState extends State<DetailsEmbedCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.data.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant DetailsEmbedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.initiallyExpanded != widget.data.initiallyExpanded) {
      _expanded = widget.data.initiallyExpanded;
    }
  }

  Future<void> _editDetails(BuildContext context) async {
    final summaryController = TextEditingController(text: widget.data.summary);
    final bodyController = TextEditingController(text: widget.data.body);

    final nextData = await showModalBottomSheet<BluefishDetailsEmbedData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '编辑折叠说明',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: summaryController,
                minLines: 1,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: '折叠标题',
                  hintText: '输入折叠标题',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                minLines: 4,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: '折叠内容',
                  hintText: '输入折叠内容',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      widget.data.copyWith(
                        summary: summaryController.text,
                        body: bodyController.text,
                        initiallyExpanded: _expanded,
                      ),
                    );
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        );
      },
    );

    summaryController.dispose();
    bodyController.dispose();

    if (nextData != null) {
      widget.onChanged?.call(nextData);
    }
  }

  void _toggleExpanded() {
    final nextExpanded = !_expanded;
    setState(() {
      _expanded = nextExpanded;
    });
    widget.onChanged?.call(
      widget.data.copyWith(initiallyExpanded: nextExpanded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summary = widget.data.summary.trim().isEmpty
        ? '补充说明'
        : widget.data.summary.trim();
    final body = widget.data.body.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleExpanded,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          AnimatedRotation(
                            turns: _expanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.keyboard_arrow_right_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              summary,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!widget.readOnly)
                TextButton.icon(
                  onPressed: () => _editDetails(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('编辑'),
                ),
              if (!widget.readOnly && widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  tooltip: '移除折叠说明',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeOutCubic,
                  sizeCurve: Curves.easeOutCubic,
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    '点击展开查看内容',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  secondChild: Text(
                    body.isEmpty ? '当前还没有补充内容。' : body,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePlaceholderEmbedCard extends StatelessWidget {
  final BluefishImagePlaceholderEmbedData data;
  final bool readOnly;
  final ValueChanged<BluefishImagePlaceholderEmbedData>? onChanged;
  final VoidCallback? onRemove;

  const ImagePlaceholderEmbedCard({
    super.key,
    required this.data,
    required this.readOnly,
    this.onChanged,
    this.onRemove,
  });

  Future<void> _editCaption(BuildContext context) async {
    final controller = TextEditingController(text: data.caption ?? '');
    final nextCaption = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('图片说明'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: null,
            decoration: const InputDecoration(hintText: '可选：补一句图片说明'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (nextCaption != null) {
      onChanged?.call(data.copyWith(caption: nextCaption));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final caption = data.caption?.trim();
    final sourceLabel = data.sourceUrl?.trim();
    final hasSourceLabel = sourceLabel != null && sourceLabel.isNotEmpty;
    final imageProvider = hasSourceLabel
        ? resolveComposerImageProvider(sourceLabel)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                color: colorScheme.surfaceContainerLow,
                child: imageProvider == null
                    ? _ComposerImageFallback(
                        label: data.label,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: Image(
                          key: const ValueKey('composer-image-preview'),
                          image: imageProvider,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return _ComposerImageFallback(
                              label: data.label,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            );
                          },
                        ),
                      ),
              ),
            ),
            if (!readOnly)
              Positioned(
                top: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editCaption(context),
                        tooltip: '编辑图片说明',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      if (onRemove != null)
                        IconButton(
                          onPressed: onRemove,
                          tooltip: '移除图片',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (caption != null && caption.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            caption,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _ComposerImageFallback extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ComposerImageFallback({
    required this.label,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

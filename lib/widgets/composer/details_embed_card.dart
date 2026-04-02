import 'package:flutter/material.dart';

import '../../models/composer/quill_embed_models.dart';

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
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  hintText: '输入折叠标题',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                minLines: 4,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Details Body',
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
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                color: colorScheme.primary,
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
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                _expanded ? (body.isEmpty ? '当前还没有补充内容。' : body) : '点击展开查看内容',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.sourceUrl == null || data.sourceUrl!.trim().isEmpty
                          ? '当前还是图片占位，后续接入真实选择器后会显示实际图片。'
                          : data.sourceUrl!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!readOnly)
                TextButton.icon(
                  onPressed: () => _editCaption(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('说明'),
                ),
              if (!readOnly && onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  tooltip: '移除图片占位',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(caption, style: textTheme.bodyMedium?.copyWith(height: 1.45)),
          ],
        ],
      ),
    );
  }
}

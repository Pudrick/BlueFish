import 'package:flutter/material.dart';

import '../../models/composer/composer_document.dart';

class ComposerEditor extends StatelessWidget {
  final ComposerDocument document;
  final ValueChanged<String>? onRemoveBlock;
  final void Function(String blockId, String value) onParagraphChanged;
  final void Function(String blockId, String value) onDetailsSummaryChanged;
  final void Function(String blockId, String value) onDetailsBodyChanged;
  final void Function(String blockId, String value) onImageCaptionChanged;

  const ComposerEditor({
    super.key,
    required this.document,
    required this.onParagraphChanged,
    required this.onDetailsSummaryChanged,
    required this.onDetailsBodyChanged,
    required this.onImageCaptionChanged,
    this.onRemoveBlock,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = document.blocks;
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          _ComposerBlockCard(
            block: blocks[index],
            onRemove: onRemoveBlock == null
                ? null
                : () => onRemoveBlock!(blocks[index].id),
            onParagraphChanged: onParagraphChanged,
            onDetailsSummaryChanged: onDetailsSummaryChanged,
            onDetailsBodyChanged: onDetailsBodyChanged,
            onImageCaptionChanged: onImageCaptionChanged,
          ),
          if (index != blocks.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ComposerBlockCard extends StatelessWidget {
  final ComposerBlockNode block;
  final VoidCallback? onRemove;
  final void Function(String blockId, String value) onParagraphChanged;
  final void Function(String blockId, String value) onDetailsSummaryChanged;
  final void Function(String blockId, String value) onDetailsBodyChanged;
  final void Function(String blockId, String value) onImageCaptionChanged;

  const _ComposerBlockCard({
    required this.block,
    required this.onParagraphChanged,
    required this.onDetailsSummaryChanged,
    required this.onDetailsBodyChanged,
    required this.onImageCaptionChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                switch (block) {
                  ComposerParagraphBlock() => '段落块',
                  ComposerDetailsBlock() => '详情块',
                  ComposerImageBlock() => '图片块',
                },
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  tooltip: '移除块',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          switch (block) {
            ComposerParagraphBlock(:final id, :final plainText) =>
              _ComposerValueField(
                key: ValueKey('paragraph-$id'),
                label: '正文',
                hintText: '输入正文内容',
                value: plainText,
                minLines: 4,
                onChanged: (value) => onParagraphChanged(id, value),
              ),
            ComposerDetailsBlock(
              :final id,
              :final summaryText,
              :final bodyText,
            ) =>
              Column(
                children: [
                  _ComposerValueField(
                    key: ValueKey('details-summary-$id'),
                    label: 'Summary',
                    hintText: '输入 summary 文本',
                    value: summaryText,
                    minLines: 1,
                    onChanged: (value) => onDetailsSummaryChanged(id, value),
                  ),
                  const SizedBox(height: 12),
                  _ComposerValueField(
                    key: ValueKey('details-body-$id'),
                    label: 'Details Body',
                    hintText: '输入 details 内容',
                    value: bodyText,
                    minLines: 4,
                    onChanged: (value) => onDetailsBodyChanged(id, value),
                  ),
                ],
              ),
            ComposerImageBlock(:final id, :final sourceUrl, :final caption) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Row(
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
                          child: Text(
                            sourceUrl == null || sourceUrl.isEmpty
                                ? '当前图片块还是占位状态，后续接入选择器后会替换成真实资源。'
                                : sourceUrl,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ComposerValueField(
                    key: ValueKey('image-caption-$id'),
                    label: '图片说明',
                    hintText: '可选：给图片补一句说明',
                    value: caption ?? '',
                    minLines: 2,
                    onChanged: (value) => onImageCaptionChanged(id, value),
                  ),
                ],
              ),
          },
        ],
      ),
    );
  }
}

class _ComposerValueField extends StatefulWidget {
  final String label;
  final String hintText;
  final String value;
  final int minLines;
  final ValueChanged<String> onChanged;

  const _ComposerValueField({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    required this.minLines,
    required this.onChanged,
  });

  @override
  State<_ComposerValueField> createState() => _ComposerValueFieldState();
}

class _ComposerValueFieldState extends State<_ComposerValueField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ComposerValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) {
      return;
    }
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          maxLines: null,
          minLines: widget.minLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

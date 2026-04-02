import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class QuillComposerToolbar extends StatelessWidget {
  final quill.QuillController controller;
  final VoidCallback onInsertImagePlaceholder;
  final VoidCallback onInsertDetails;
  final VoidCallback? onInsertVideoPlaceholder;

  const QuillComposerToolbar({
    super.key,
    required this.controller,
    required this.onInsertImagePlaceholder,
    required this.onInsertDetails,
    this.onInsertVideoPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
          Text(
            '编辑工具',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          quill.QuillSimpleToolbar(
            controller: controller,
            config: const quill.QuillSimpleToolbarConfig(
              multiRowsDisplay: true,
              showDividers: false,
              showFontFamily: false,
              showFontSize: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showAlignmentButtons: false,
              showHeaderStyle: false,
              showListCheck: false,
              showDirection: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              showLineHeightButton: false,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onInsertImagePlaceholder,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('图片占位'),
              ),
              FilledButton.tonalIcon(
                onPressed: onInsertDetails,
                icon: const Icon(Icons.unfold_more_rounded, size: 18),
                label: const Text('折叠说明'),
              ),
              if (onInsertVideoPlaceholder != null)
                FilledButton.tonalIcon(
                  onPressed: onInsertVideoPlaceholder,
                  icon: const Icon(Icons.smart_display_outlined, size: 18),
                  label: const Text('视频'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/composer/composer_document.dart';
import '../html/bluefish_html_widget.dart';

class ComposerPreview extends StatelessWidget {
  final String title;
  final ComposerDocument document;

  const ComposerPreview({
    super.key,
    required this.title,
    required this.document,
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HTML 预览',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (title.trim().isNotEmpty)
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          if (title.trim().isNotEmpty) const SizedBox(height: 14),
          if (document.isEmpty)
            Text(
              '当前还没有可预览的富文本内容。',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            BluefishHtmlWidget(
              document.toHtml(),
              textStyle: textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
        ],
      ),
    );
  }
}

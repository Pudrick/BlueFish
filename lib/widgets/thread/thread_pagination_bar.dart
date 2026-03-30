// lib/pages/thread/widgets/thread_pagination_bar.dart

import 'package:flutter/material.dart';

class ThreadPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const ThreadPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          FilledButton.tonalIcon(
            onPressed: onPrev,
            style: _commonButtonStyle(colorScheme),
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('上一页'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '第$currentPage页',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: onNext,
            style: _commonButtonStyle(colorScheme),
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('下一页'),
          ),
        ],
      ),
    );
  }

  ButtonStyle _commonButtonStyle(ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      minimumSize: const Size(104, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      visualDensity: VisualDensity.compact,
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.surfaceContainerHighest;
        }
        return null;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.45);
        }
        return null;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        return null;
      }),
    );
  }
}

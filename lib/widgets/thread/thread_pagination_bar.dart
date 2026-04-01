// lib/pages/thread/widgets/thread_pagination_bar.dart

import 'package:flutter/material.dart';

class ThreadPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String? firstButtonLabel;
  final String? lastButtonLabel;
  final VoidCallback? onFirst;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onLast;

  const ThreadPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.firstButtonLabel,
    this.lastButtonLabel,
    this.onFirst,
    this.onPrev,
    this.onNext,
    this.onLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool showsJumpButtons =
        firstButtonLabel != null || lastButtonLabel != null;

    if (!showsJumpButtons) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildActionButton(
              colorScheme: colorScheme,
              onPressed: onPrev,
              icon: Icons.chevron_left_rounded,
              label: '上一页',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Center(child: _buildPageChip(context, colorScheme)),
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              colorScheme: colorScheme,
              onPressed: onNext,
              icon: Icons.chevron_right_rounded,
              label: '下一页',
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPageChip(context, colorScheme),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              if (firstButtonLabel != null)
                _buildActionButton(
                  colorScheme: colorScheme,
                  onPressed: onFirst,
                  icon: Icons.first_page_rounded,
                  label: firstButtonLabel!,
                ),
              _buildActionButton(
                colorScheme: colorScheme,
                onPressed: onPrev,
                icon: Icons.chevron_left_rounded,
                label: '上一页',
              ),
              _buildActionButton(
                colorScheme: colorScheme,
                onPressed: onNext,
                icon: Icons.chevron_right_rounded,
                label: '下一页',
              ),
              if (lastButtonLabel != null)
                _buildActionButton(
                  colorScheme: colorScheme,
                  onPressed: onLast,
                  icon: Icons.last_page_rounded,
                  label: lastButtonLabel!,
                ),
            ],
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

  Widget _buildActionButton({
    required ColorScheme colorScheme,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: _commonButtonStyle(colorScheme),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildPageChip(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }
}

import 'package:flutter/material.dart';

class ThreadBottomBar extends StatelessWidget {
  final bool hasRecommended;
  final bool hasFavorated;

  const ThreadBottomBar({
    super.key,
    required this.hasRecommended,
    required this.hasFavorated,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            _BottomActionPill(
              icon: hasRecommended ? Icons.thumb_up : Icons.thumb_up_outlined,
              label: '推荐',
              selected: hasRecommended,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _BottomActionPill(
              icon: hasFavorated ? Icons.star : Icons.star_outline,
              label: '收藏',
              selected: hasFavorated,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _BottomActionPill(
              icon: Icons.share_outlined,
              label: '分享',
              selected: false,
              onTap: () {},
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _BottomActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomActionPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

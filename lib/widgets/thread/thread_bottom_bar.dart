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
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          IconButton(
            onPressed: () {},
            icon: hasRecommended
                ? const Icon(Icons.thumb_up)
                : const Icon(Icons.thumb_up_outlined),
            color: hasRecommended
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: hasFavorated
                ? const Icon(Icons.star_outline)
                : const Icon(Icons.star),
            color: hasFavorated
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
            color: colorScheme.onSurfaceVariant,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

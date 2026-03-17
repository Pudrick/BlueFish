import 'package:flutter/material.dart';

class MentionGroupedSliverList<T> extends StatelessWidget {
  final List<T> newItems;
  final List<T> oldItems;
  final bool hasNextPage;
  final bool isLoading;
  final Widget Function(BuildContext context, T item) itemBuilder;

  const MentionGroupedSliverList({
    super.key,
    required this.newItems,
    required this.oldItems,
    required this.hasNextPage,
    required this.isLoading,
    required this.itemBuilder,
  });

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: !hasNextPage
          ? Text(
              '—— 后面没有了 ——',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            )
          : isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              '上滑加载更多',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNewItems = newItems.isNotEmpty;
    final hasOldItems = oldItems.isNotEmpty;

    if (!hasNewItems && !hasOldItems) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: [
        if (hasNewItems) ...[
          const SliverToBoxAdapter(child: _SectionDivider(title: '新消息')),
          SliverList.builder(
            itemCount: newItems.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, newItems[index]),
          ),
        ],
        if (hasOldItems) ...[
          const SliverToBoxAdapter(child: _SectionDivider(title: '历史消息')),
          SliverList.builder(
            itemCount: oldItems.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, oldItems[index]),
          ),
        ],
        SliverToBoxAdapter(child: _buildFooter(context)),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String title;

  const _SectionDivider({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: textTheme.labelLarge?.copyWith(color: colorScheme.outline),
            ),
          ),
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, thickness: 1),
          ),
        ],
      ),
    );
  }
}

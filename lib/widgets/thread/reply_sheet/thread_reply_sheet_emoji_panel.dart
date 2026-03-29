import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'interactive_icon_surface.dart';
import 'thread_reply_sheet_models.dart';

const double kThreadReplySheetEmojiCellExtent = 44;
const double kThreadReplySheetEmojiGridSpacing = 8;
const double kThreadReplySheetEmojiPanelPadding = 10;
const double kThreadReplySheetEmojiCategoryBarHeight = 36;
const double kThreadReplySheetEmojiPanelFooterSpacing = 8;
const double kThreadReplySheetEmojiPanelDividerHeight = 1;
const double kThreadReplySheetEmojiPanelFooterHeight =
    kThreadReplySheetEmojiCategoryBarHeight +
    kThreadReplySheetEmojiPanelFooterSpacing +
    kThreadReplySheetEmojiPanelDividerHeight +
    kThreadReplySheetEmojiPanelFooterSpacing;

class ThreadReplySheetEmojiPanel extends StatelessWidget {
  final List<ThreadReplySheetEmojiCategory> categories;
  final String selectedCategoryKey;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<ThreadReplySheetEmojiItem> onEmojiSelected;
  final double maxHeight;
  final int crossAxisCount;

  const ThreadReplySheetEmojiPanel({
    super.key,
    required this.categories,
    required this.selectedCategoryKey,
    required this.onCategorySelected,
    required this.onEmojiSelected,
    required this.maxHeight,
    this.crossAxisCount = 7,
  }) : assert(crossAxisCount > 0),
       assert(maxHeight > 0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (categories.isEmpty) {
      return Container(
        key: const ValueKey('thread_reply_sheet_emoji_panel_empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '暂无表情可用',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    var selectedCategory = categories.first;
    for (final category in categories) {
      if (category.key == selectedCategoryKey) {
        selectedCategory = category;
        break;
      }
    }
    final emojis = selectedCategory.items;
    final rowCount = emojis.isEmpty
        ? 1
        : ((emojis.length - 1) ~/ crossAxisCount) + 1;
    final preferredGridHeight =
        (rowCount * kThreadReplySheetEmojiCellExtent) +
        ((rowCount - 1) * kThreadReplySheetEmojiGridSpacing);
    final gridMaxHeight = math.max(
      72.0,
      maxHeight - kThreadReplySheetEmojiPanelFooterHeight,
    );
    final gridHeight = math.min(preferredGridHeight, gridMaxHeight).toDouble();

    return Container(
      key: const ValueKey('thread_reply_sheet_emoji_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(kThreadReplySheetEmojiPanelPadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: gridHeight,
            child: GridView.builder(
              key: ValueKey(
                'thread_reply_sheet_emoji_grid_${selectedCategory.key}',
              ),
              physics: const ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: kThreadReplySheetEmojiGridSpacing,
                mainAxisSpacing: kThreadReplySheetEmojiGridSpacing,
                mainAxisExtent: kThreadReplySheetEmojiCellExtent,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                final item = emojis[index];
                final displayStyle = textTheme.titleMedium?.copyWith(
                  height: 1,
                  fontSize: item.display.runes.length > 2 ? 18 : 22,
                );

                return ThreadReplyInteractiveIconSurface(
                  key: ValueKey(
                    'thread_reply_sheet_emoji_${selectedCategory.key}_${item.key}',
                  ),
                  semanticLabel: item.label,
                  tooltip: item.tooltip ?? item.label,
                  onTap: () => onEmojiSelected(item),
                  baseColor: Colors.transparent,
                  hoverColor: colorScheme.secondaryContainer.withValues(
                    alpha: 0.48,
                  ),
                  pressedColor: colorScheme.secondaryContainer.withValues(
                    alpha: 0.68,
                  ),
                  inkColor: colorScheme.onSurface,
                  width: kThreadReplySheetEmojiCellExtent,
                  height: kThreadReplySheetEmojiCellExtent,
                  borderRadius: 14,
                  child: Text(item.display, style: displayStyle),
                );
              },
            ),
          ),
          const SizedBox(height: kThreadReplySheetEmojiPanelFooterSpacing),
          Divider(
            height: kThreadReplySheetEmojiPanelDividerHeight,
            thickness: kThreadReplySheetEmojiPanelDividerHeight,
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: kThreadReplySheetEmojiPanelFooterSpacing),
          SizedBox(
            height: kThreadReplySheetEmojiCategoryBarHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _EmojiCategoryChip(
                        label: category.label,
                        selected: category.key == selectedCategory.key,
                        onTap: () => onCategorySelected(category.key),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EmojiCategoryChip({
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
          ? colorScheme.secondaryContainer.withValues(alpha: 0.92)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

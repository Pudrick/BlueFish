import 'package:flutter/material.dart';

import 'interactive_icon_surface.dart';
import 'thread_reply_sheet_models.dart';

class ThreadReplySheetActionRow extends StatelessWidget {
  final List<ThreadReplySheetAction> actions;
  final bool hasOverflowActions;
  final VoidCallback onToggleOverflow;

  const ThreadReplySheetActionRow({
    super.key,
    required this.actions,
    required this.hasOverflowActions,
    required this.onToggleOverflow,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ThreadReplySheetActionButton(action: action),
            );
          }),
          if (hasOverflowActions)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ThreadReplySheetOverflowToggleButton(
                expanded: false,
                onTap: onToggleOverflow,
              ),
            ),
        ],
      ),
    );
  }
}

class ThreadReplySheetActionButton extends StatelessWidget {
  final ThreadReplySheetAction action;
  final String? keyName;

  const ThreadReplySheetActionButton({
    super.key,
    required this.action,
    this.keyName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = action.enabled
        ? action.selected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return ThreadReplyInteractiveIconSurface(
      key: ValueKey(keyName ?? 'thread_reply_sheet_action_${action.label}'),
      semanticLabel: action.label,
      tooltip: action.tooltip ?? action.label,
      onTap: action.enabled ? action.onTap : null,
      baseColor: action.selected
          ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
          : Colors.transparent,
      hoverColor: action.selected
          ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
          : colorScheme.secondaryContainer.withValues(alpha: 0.4),
      pressedColor: action.selected
          ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
          : colorScheme.secondaryContainer.withValues(alpha: 0.58),
      inkColor: foregroundColor,
      child: Icon(action.icon, size: 22, color: foregroundColor),
    );
  }
}

class ThreadReplySheetExpandedActionPanel extends StatelessWidget {
  final List<ThreadReplySheetAction> actions;
  final VoidCallback onToggleOverflow;

  const ThreadReplySheetExpandedActionPanel({
    super.key,
    required this.actions,
    required this.onToggleOverflow,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('thread_reply_sheet_more_actions_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 8,
        children: [
          ...actions.map((action) {
            return ThreadReplySheetActionButton(
              action: action,
              keyName: 'thread_reply_sheet_expanded_${action.label}',
            );
          }),
          ThreadReplySheetOverflowToggleButton(
            expanded: true,
            onTap: onToggleOverflow,
          ),
        ],
      ),
    );
  }
}

class ThreadReplySheetOverflowToggleButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const ThreadReplySheetOverflowToggleButton({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = expanded
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;
    final baseColor = expanded
        ? colorScheme.errorContainer.withValues(alpha: 0.92)
        : Colors.transparent;
    final hoverColor = expanded
        ? Color.alphaBlend(
            colorScheme.error.withValues(alpha: 0.16),
            colorScheme.errorContainer.withValues(alpha: 0.92),
          )
        : colorScheme.secondaryContainer.withValues(alpha: 0.4);
    final pressedColor = expanded
        ? Color.alphaBlend(
            colorScheme.error.withValues(alpha: 0.28),
            colorScheme.errorContainer.withValues(alpha: 0.92),
          )
        : colorScheme.secondaryContainer.withValues(alpha: 0.58);
    final double iconSize = expanded ? 20 : 22;

    return ThreadReplyInteractiveIconSurface(
      key: const ValueKey('thread_reply_sheet_more_actions_toggle'),
      semanticLabel: expanded ? '收起更多功能' : '展开更多功能',
      tooltip: expanded ? '收起更多功能' : '展开更多功能',
      onTap: onTap,
      baseColor: baseColor,
      hoverColor: hoverColor,
      pressedColor: pressedColor,
      inkColor: foregroundColor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          expanded ? Icons.close_rounded : Icons.add_rounded,
          key: ValueKey(expanded),
          size: iconSize,
          color: foregroundColor,
        ),
      ),
    );
  }
}

import 'package:bluefish/models/thread/thread_recommend_state.dart';
import 'package:bluefish/userdata/pinned_thread_shortcut_store.dart';
import 'package:flutter/material.dart';

class ThreadBottomBar extends StatelessWidget {
  static const double _actionSpacing = 6;
  static const double _pillIconSize = 18;
  static const double _recommendSegmentHeight = 40;
  static const EdgeInsets _pillPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 8,
  );
  static const double _recommendRefreshSegmentWidth = 34;

  final ThreadRecommendState recommendState;
  final bool autoProbeThreadRecommendStatusEnabled;
  final bool hasFavorated;
  final String threadTid;
  final String threadTitle;
  final bool isOnlyOpMode;
  final VoidCallback? onOnlyOpTap;
  final VoidCallback? onRecommendTap;
  final VoidCallback? onRecommendRefreshTap;

  const ThreadBottomBar({
    super.key,
    required this.recommendState,
    required this.autoProbeThreadRecommendStatusEnabled,
    required this.hasFavorated,
    required this.threadTid,
    required this.threadTitle,
    this.isOnlyOpMode = false,
    this.onOnlyOpTap,
    this.onRecommendTap,
    this.onRecommendRefreshTap,
  });

  Future<void> _togglePinnedShortcut(BuildContext context) async {
    await pinnedThreadShortcutStore.ensureInitialized();

    final bool wasPinned = pinnedThreadShortcutStore.isPinned(threadTid);
    await pinnedThreadShortcutStore.toggle(
      PinnedThreadShortcut(tid: threadTid, title: threadTitle),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(wasPinned ? '已取消固定' : '已固定主贴')));
  }

  Future<void> _showOverflowActionSheet(
    BuildContext context,
    List<_ThreadBottomBarActionSpec> actions,
  ) {
    if (actions.isEmpty) {
      return Future<void>.value();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    '更多操作',
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final action in actions)
                  ListTile(
                    leading: Icon(
                      action.icon,
                      color: action.selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(action.label),
                    trailing: action.selected
                        ? Icon(Icons.check_rounded, color: colorScheme.primary)
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      action.onTap();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    ).then((_) {});
  }

  List<_ThreadBottomBarActionSpec> _buildActions({
    required BuildContext context,
    required bool hasPinned,
  }) {
    return [
      if (onOnlyOpTap != null)
        _ThreadBottomBarActionSpec(
          id: 'only-op',
          icon: isOnlyOpMode
              ? Icons.filter_alt_rounded
              : Icons.filter_alt_outlined,
          label: isOnlyOpMode ? '看全部' : '只看楼主',
          selected: isOnlyOpMode,
          onTap: onOnlyOpTap!,
        ),
      _ThreadBottomBarActionSpec(
        id: 'pin',
        icon: Icons.push_pin_rounded,
        label: '固定',
        selected: hasPinned,
        onTap: () {
          _togglePinnedShortcut(context);
        },
      ),
      _ThreadBottomBarActionSpec(
        id: 'share',
        icon: Icons.share_outlined,
        label: '分享',
        selected: false,
        onTap: () {},
      ),
      _ThreadBottomBarActionSpec(
        id: 'favorite',
        icon: hasFavorated ? Icons.star : Icons.star_outline,
        label: '收藏',
        selected: hasFavorated,
        onTap: () {},
      ),
    ];
  }

  _ThreadBottomBarActionLayout _resolveActionLayout({
    required BuildContext context,
    required List<_ThreadBottomBarActionSpec> actions,
    required double availableWidth,
  }) {
    if (actions.isEmpty || availableWidth <= 0) {
      return const _ThreadBottomBarActionLayout(
        visibleActions: <_ThreadBottomBarActionSpec>[],
        overflowActions: <_ThreadBottomBarActionSpec>[],
      );
    }

    final double moreButtonWidth = _measurePillWidth(context, '更多');
    final visibleActions = <_ThreadBottomBarActionSpec>[];
    double usedWidth = 0;

    for (var index = 0; index < actions.length; index += 1) {
      final action = actions[index];
      final double actionWidth = _measurePillWidth(context, action.label);
      final double nextWidth = visibleActions.isEmpty
          ? actionWidth
          : actionWidth + _actionSpacing;
      final bool willOverflow = index < actions.length - 1;
      final double overflowReserve = willOverflow
          ? visibleActions.isEmpty
                ? moreButtonWidth
                : moreButtonWidth + _actionSpacing
          : 0;

      if (usedWidth + nextWidth + overflowReserve <= availableWidth) {
        visibleActions.add(action);
        usedWidth += nextWidth;
        continue;
      }

      return _ThreadBottomBarActionLayout(
        visibleActions: visibleActions,
        overflowActions: actions.sublist(index),
      );
    }

    return _ThreadBottomBarActionLayout(
      visibleActions: visibleActions,
      overflowActions: const <_ThreadBottomBarActionSpec>[],
    );
  }

  double _measurePillWidth(BuildContext context, String label) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return _pillPadding.horizontal + _pillIconSize + 4 + textPainter.width + 2;
  }

  double _measureRecommendWidgetWidth(BuildContext context) {
    final mainWidth = _measurePillWidth(context, '推荐');
    if (autoProbeThreadRecommendStatusEnabled) {
      return mainWidth;
    }
    return mainWidth + _recommendRefreshSegmentWidth;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    pinnedThreadShortcutStore.ensureInitialized();

    // NOTE: Do NOT replace this Material with BottomAppBar.
    // BottomAppBar creates an internal _BottomAppBarClipper that accesses
    // _ScaffoldGeometryNotifier.value during hit testing, which can trigger
    // a re-entrant MouseTracker._deviceUpdatePhase call and cause:
    //   Failed assertion: '!_debugDuringDeviceUpdate': is not true
    // This results in intermittent mouse click failures.
    return AnimatedBuilder(
      animation: pinnedThreadShortcutStore,
      builder: (context, child) {
        final bool hasPinned = pinnedThreadShortcutStore.isPinned(threadTid);
        final actions = _buildActions(context: context, hasPinned: hasPinned);

        return Material(
          color: colorScheme.surfaceContainerLow,
          elevation: 0,
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 90),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final recommendWidth = _measureRecommendWidgetWidth(
                        context,
                      );
                      final remainingWidth =
                          constraints.maxWidth - recommendWidth;
                      final layout = _resolveActionLayout(
                        context: context,
                        actions: actions,
                        availableWidth: remainingWidth,
                      );
                      final children = <Widget>[
                        _ThreadRecommendActionPill(
                          key: ValueKey<String>(
                            autoProbeThreadRecommendStatusEnabled
                                ? 'thread-bottom-recommend-single'
                                : 'thread-bottom-recommend-segmented',
                          ),
                          state: recommendState,
                          useAutomaticProbeMode:
                              autoProbeThreadRecommendStatusEnabled,
                          onMainTap: onRecommendTap,
                          onRefreshTap: onRecommendRefreshTap,
                        ),
                        if (layout.visibleActions.isNotEmpty ||
                            layout.overflowActions.isNotEmpty)
                          const SizedBox(width: _actionSpacing),
                        for (
                          var index = 0;
                          index < layout.visibleActions.length;
                          index += 1
                        ) ...[
                          if (index > 0) const SizedBox(width: _actionSpacing),
                          _BottomActionPill(
                            key: ValueKey<String>(
                              'thread-bottom-bar-action-${layout.visibleActions[index].id}',
                            ),
                            icon: layout.visibleActions[index].icon,
                            label: layout.visibleActions[index].label,
                            selected: layout.visibleActions[index].selected,
                            onTap: layout.visibleActions[index].onTap,
                          ),
                        ],
                        if (layout.overflowActions.isNotEmpty) ...[
                          if (layout.visibleActions.isNotEmpty)
                            const SizedBox(width: _actionSpacing),
                          _BottomActionPill(
                            key: const ValueKey<String>(
                              'thread-bottom-bar-more-button',
                            ),
                            icon: Icons.more_horiz_rounded,
                            label: '更多',
                            selected: false,
                            onTap: () {
                              _showOverflowActionSheet(
                                context,
                                layout.overflowActions,
                              );
                            },
                          ),
                        ],
                      ];

                      // Keep intrinsic height; do not expand to Scaffold's
                      // full available bottom-navigation height.
                      return Row(children: children);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThreadRecommendActionPill extends StatelessWidget {
  final ThreadRecommendState state;
  final bool useAutomaticProbeMode;
  final VoidCallback? onMainTap;
  final VoidCallback? onRefreshTap;

  const _ThreadRecommendActionPill({
    super.key,
    required this.state,
    required this.useAutomaticProbeMode,
    this.onMainTap,
    this.onRefreshTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _ThreadRecommendVisual.resolve(context, state);
    if (useAutomaticProbeMode) {
      return _ThreadRecommendMainSegment(
        key: const ValueKey<String>('thread-bottom-recommend-main'),
        visual: visual,
        onTap: state.isChecking ? null : onMainTap,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: visual.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThreadRecommendMainSegment(
            key: const ValueKey<String>('thread-bottom-recommend-main'),
            visual: visual,
            onTap: state.isChecking ? null : onMainTap,
            useCustomShape: false,
          ),
          SizedBox(
            width: 1,
            height: ThreadBottomBar._recommendSegmentHeight,
            child: ColoredBox(color: visual.borderColor),
          ),
          Tooltip(
            message: '探测推荐状态',
            child: Material(
              color: colorScheme.surfaceContainerLow,
              child: InkWell(
                key: const ValueKey<String>('thread-bottom-recommend-refresh'),
                onTap: state.isChecking ? null : onRefreshTap,
                child: SizedBox(
                  width: ThreadBottomBar._recommendRefreshSegmentWidth,
                  height: ThreadBottomBar._recommendSegmentHeight,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: state.isChecking
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadRecommendMainSegment extends StatelessWidget {
  final _ThreadRecommendVisual visual;
  final VoidCallback? onTap;
  final bool useCustomShape;

  const _ThreadRecommendMainSegment({
    super.key,
    required this.visual,
    required this.onTap,
    this.useCustomShape = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = useCustomShape
        ? BorderRadius.circular(999)
        : const BorderRadius.horizontal(left: Radius.circular(999));
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: useCustomShape
          ? BorderSide(color: visual.borderColor)
          : BorderSide.none,
    );

    return Material(
      color: visual.backgroundColor,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ThreadBottomBar._recommendSegmentHeight,
          ),
          child: Padding(
            padding: ThreadBottomBar._pillPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (visual.showProgress)
                  SizedBox(
                    width: ThreadBottomBar._pillIconSize,
                    height: ThreadBottomBar._pillIconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        visual.foregroundColor,
                      ),
                    ),
                  )
                else
                  Icon(
                    visual.icon,
                    size: ThreadBottomBar._pillIconSize,
                    color: visual.foregroundColor,
                  ),
                const SizedBox(width: 4),
                Text(
                  '推荐',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: visual.foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadRecommendVisual {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final bool showProgress;

  const _ThreadRecommendVisual({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.showProgress,
  });

  factory _ThreadRecommendVisual.resolve(
    BuildContext context,
    ThreadRecommendState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (state) {
      ThreadRecommendState.recommended => _ThreadRecommendVisual(
        icon: Icons.thumb_up,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        borderColor: colorScheme.primary.withValues(alpha: 0.16),
        showProgress: false,
      ),
      ThreadRecommendState.notRecommended => _ThreadRecommendVisual(
        icon: Icons.thumb_up_outlined,
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        borderColor: colorScheme.outlineVariant.withValues(alpha: 0.55),
        showProgress: false,
      ),
      ThreadRecommendState.checking => _ThreadRecommendVisual(
        icon: Icons.thumb_up_outlined,
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        borderColor: colorScheme.outlineVariant.withValues(alpha: 0.55),
        showProgress: true,
      ),
      ThreadRecommendState.unknown => _ThreadRecommendVisual(
        icon: Icons.help_outline_rounded,
        backgroundColor: colorScheme.tertiaryContainer.withValues(alpha: 0.7),
        foregroundColor: colorScheme.onTertiaryContainer,
        borderColor: colorScheme.tertiary.withValues(alpha: 0.18),
        showProgress: false,
      ),
    };
  }
}

class _ThreadBottomBarActionSpec {
  final String id;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThreadBottomBarActionSpec({
    required this.id,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

class _ThreadBottomBarActionLayout {
  final List<_ThreadBottomBarActionSpec> visibleActions;
  final List<_ThreadBottomBarActionSpec> overflowActions;

  const _ThreadBottomBarActionLayout({
    required this.visibleActions,
    required this.overflowActions,
  });
}

class _BottomActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomActionPill({
    super.key,
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
          padding: ThreadBottomBar._pillPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ThreadBottomBar._pillIconSize,
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

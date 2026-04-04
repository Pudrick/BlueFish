import 'package:bluefish/userdata/pinned_thread_shortcut_store.dart';
import 'package:flutter/material.dart';

class ThreadBottomBar extends StatelessWidget {
  final bool hasRecommended;
  final bool hasFavorated;
  final String threadTid;
  final String threadTitle;
  final bool isOnlyOpMode;
  final VoidCallback? onOnlyOpTap;

  const ThreadBottomBar({
    super.key,
    required this.hasRecommended,
    required this.hasFavorated,
    required this.threadTid,
    required this.threadTitle,
    this.isOnlyOpMode = false,
    this.onOnlyOpTap,
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _BottomActionPill(
                          icon: hasRecommended
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
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
                        if (onOnlyOpTap != null) ...[
                          const SizedBox(width: 8),
                          _BottomActionPill(
                            icon: isOnlyOpMode
                                ? Icons.filter_alt_rounded
                                : Icons.filter_alt_outlined,
                            label: isOnlyOpMode ? '看全部' : '只看楼主',
                            selected: isOnlyOpMode,
                            onTap: onOnlyOpTap!,
                          ),
                        ],
                        const SizedBox(width: 8),
                        _BottomActionPill(
                          icon: Icons.push_pin_rounded,
                          label: '固定',
                          selected: hasPinned,
                          onTap: () async {
                            await _togglePinnedShortcut(context);
                          },
                        ),
                        const SizedBox(width: 8),
                        _BottomActionPill(
                          icon: Icons.share_outlined,
                          label: '分享',
                          selected: false,
                          onTap: () {},
                        ),
                      ],
                    ),
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

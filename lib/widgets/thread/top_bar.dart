import 'package:bluefish/models/thread/thread_list.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/userdata/pinned_thread_shortcut_store.dart';
import 'package:bluefish/viewModels/thread_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  Future<void> _handlePinnedShortcutTap(BuildContext context) async {
    await pinnedThreadShortcutStore.ensureInitialized();
    if (!context.mounted) {
      return;
    }

    final shortcuts = pinnedThreadShortcutStore.shortcuts;
    if (shortcuts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('还没有固定的主贴')));
      return;
    }

    if (shortcuts.length == 1) {
      context.pushThreadDetail(tid: shortcuts.first.tid);
      return;
    }

    final selectedShortcut = await showModalBottomSheet<PinnedThreadShortcut>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        final colorScheme = theme.colorScheme;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(bottomSheetContext).height * 0.65,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.push_pin_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '选择已固定主贴',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: shortcuts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final shortcut = shortcuts[index];

                      return ListTile(
                        leading: const Icon(Icons.push_pin_rounded),
                        title: Text(
                          shortcut.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('帖子 ${shortcut.tid}'),
                        onTap: () {
                          Navigator.of(context).pop(shortcut);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || selectedShortcut == null) {
      return;
    }

    context.pushThreadDetail(tid: selectedShortcut.tid);
  }

  Widget _buildCenterControl(
    BuildContext context,
    ThreadListViewModel titleList,
    ColorScheme colorScheme,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: titleList.showSortSwitcher
          ? Center(
              key: const ValueKey('sort-switcher'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SegmentedButton<SortType>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: SortType.newestReply,
                      icon: Icon(Icons.update_rounded),
                      label: Text('最新回复'),
                    ),
                    ButtonSegment(
                      value: SortType.newestPublish,
                      icon: Icon(Icons.fiber_new_outlined),
                      label: Text('最新发布'),
                    ),
                  ],
                  selected: {titleList.currentSortType},
                  onSelectionChanged: (selectionSet) {
                    titleList.setSortType(selectionSet.first);
                  },
                ),
              ),
            )
          : Center(
              key: const ValueKey('essence-note'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '精华列表按官方顺序展示',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    pinnedThreadShortcutStore.ensureInitialized();

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(126),
        child: Consumer<ThreadListViewModel>(
          builder: (context, titleList, child) {
            final currentBoardIndex = ThreadListBoard.values.indexOf(
              titleList.currentBoard,
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DefaultTabController(
                key: ValueKey(currentBoardIndex),
                length: ThreadListBoard.values.length,
                initialIndex: currentBoardIndex,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool compactPinnedShortcut =
                        constraints.maxWidth < 420;
                    final double pinnedSlotWidth = compactPinnedShortcut
                        ? 40
                        : 84;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBar(
                          indicatorSize: TabBarIndicatorSize.label,
                          indicatorWeight: 3,
                          dividerColor: colorScheme.outlineVariant.withValues(
                            alpha: 0.45,
                          ),
                          tabs: const [
                            Tab(
                              height: 56,
                              iconMargin: EdgeInsets.only(bottom: 1),
                              icon: Icon(Icons.dashboard_outlined, size: 18),
                              text: '主版',
                            ),
                            Tab(
                              height: 56,
                              iconMargin: EdgeInsets.only(bottom: 1),
                              icon: Icon(Icons.movie_outlined, size: 18),
                              text: '剧场',
                            ),
                            Tab(
                              height: 56,
                              iconMargin: EdgeInsets.only(bottom: 1),
                              icon: Icon(Icons.auto_awesome_outlined, size: 18),
                              text: '精华',
                            ),
                          ],
                          onTap: (index) {
                            final targetBoard = ThreadListBoard.values[index];
                            if (targetBoard != titleList.currentBoard) {
                              titleList.setBoard(targetBoard);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: pinnedThreadShortcutStore,
                          builder: (context, child) {
                            final bool hasPinnedThreads =
                                pinnedThreadShortcutStore.shortcuts.isNotEmpty;

                            return Row(
                              children: [
                                SizedBox(
                                  width: pinnedSlotWidth,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _PinnedShortcutButton(
                                      compact: compactPinnedShortcut,
                                      active: hasPinnedThreads,
                                      onTap: () async {
                                        await _handlePinnedShortcutTap(context);
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildCenterControl(
                                    context,
                                    titleList,
                                    colorScheme,
                                  ),
                                ),
                                SizedBox(width: pinnedSlotWidth),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(126);
}

class _PinnedShortcutButton extends StatelessWidget {
  final bool compact;
  final bool active;
  final VoidCallback onTap;

  const _PinnedShortcutButton({
    required this.compact,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Color backgroundColor = active
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final Color foregroundColor = active
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.push_pin_rounded, size: 16, color: foregroundColor),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  '氵楼',
                  style: textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

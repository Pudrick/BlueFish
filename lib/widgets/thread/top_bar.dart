import 'package:bluefish/models/thread_list.dart';
import 'package:bluefish/viewModels/thread_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                child: Column(
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: titleList.showSortSwitcher
                          ? Center(
                              key: const ValueKey('sort-switcher'),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 360,
                                ),
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
                          : Container(
                              key: const ValueKey('essence-note'),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
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

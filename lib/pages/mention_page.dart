import 'package:bluefish/pages/mention_list_page_base.dart';
import 'package:bluefish/viewModels/mention_light_view_model.dart';
import 'package:bluefish/viewModels/mention_reply_view_model.dart';
import 'package:bluefish/widgets/mention/mention_light_widget.dart';
import 'package:bluefish/widgets/mention/mention_reply_widget.dart';
import 'package:flutter/material.dart';

enum MentionTab { reply, light }

class MentionPage extends StatefulWidget {
  final MentionTab initialTab;

  const MentionPage({super.key, this.initialTab = MentionTab.reply});

  @override
  State<MentionPage> createState() => _MentionPageState();
}

class _MentionPageState extends State<MentionPage> {
  static const double _pillBottomSpacing = 16;
  static const double _pillHeight = 56;
  static const double _listBottomInset = _pillBottomSpacing + _pillHeight + 24;
  // TODO: replace these placeholders with the real unread counts.
  static const int _replyUnreadPlaceholder = 12;
  static const int _lightUnreadPlaceholder = 3;

  late MentionTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: _currentTab.index,
            children: const [_MentionReplySection(), _MentionLightSection()],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  _pillBottomSpacing,
                ),
                child: _MentionTabPill(
                  currentTab: _currentTab,
                  onChanged: (tab) {
                    if (_currentTab == tab) {
                      return;
                    }
                    setState(() {
                      _currentTab = tab;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MentionReplySection extends StatelessWidget {
  const _MentionReplySection();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MentionListSection(
        createViewModel: MentionReplyViewModel.new,
        titleIcon: Icons.alternate_email,
        title: '@我的',
        bottomInset: _MentionPageState._listBottomInset,
        buildListSliver: (context, viewModel) => MentionReplyListWidget(
          newReplies: viewModel.newList,
          oldReplies: viewModel.oldList,
          hasNextPage: viewModel.hasNextPage,
        ),
      ),
    );
  }
}

class _MentionLightSection extends StatelessWidget {
  const _MentionLightSection();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MentionListSection(
        createViewModel: MentionLightViewModel.new,
        titleIcon: Icons.thumb_up_outlined,
        title: '点亮我的',
        bottomInset: _MentionPageState._listBottomInset,
        buildListSliver: (context, viewModel) => MentionLightListWidget(
          newLights: viewModel.newList,
          oldLights: viewModel.oldList,
          hasNextPage: viewModel.hasNextPage,
        ),
      ),
    );
  }
}

class _MentionTabPill extends StatelessWidget {
  final MentionTab currentTab;
  final ValueChanged<MentionTab> onChanged;

  const _MentionTabPill({required this.currentTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 10,
      shadowColor: Colors.black26,
      color: colorScheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MentionTabButton(
              icon: Icons.alternate_email,
              label: '@我的',
              unreadCount: _MentionPageState._replyUnreadPlaceholder,
              emphasizeUnread: true,
              selected: currentTab == MentionTab.reply,
              onTap: () => onChanged(MentionTab.reply),
            ),
            _MentionTabButton(
              icon: Icons.thumb_up_outlined,
              label: '点亮我的',
              unreadCount: _MentionPageState._lightUnreadPlaceholder,
              emphasizeUnread: false,
              selected: currentTab == MentionTab.light,
              onTap: () => onChanged(MentionTab.light),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentionTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int unreadCount;
  final bool emphasizeUnread;
  final bool selected;
  final VoidCallback onTap;

  const _MentionTabButton({
    required this.icon,
    required this.label,
    required this.unreadCount,
    required this.emphasizeUnread,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                unreadCount > 0 ? 28 : 16,
                12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 5,
                right: 8,
                child: _MentionUnreadBadge(
                  count: unreadCount,
                  emphasized: emphasizeUnread,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MentionUnreadBadge extends StatelessWidget {
  final int count;
  final bool emphasized;

  const _MentionUnreadBadge({required this.count, required this.emphasized});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = emphasized
        ? colorScheme.error
        : colorScheme.secondaryContainer;
    final foregroundColor = emphasized
        ? colorScheme.onError
        : colorScheme.onSecondaryContainer;

    return Container(
      constraints: BoxConstraints(
        minWidth: emphasized ? 22 : 18,
        minHeight: emphasized ? 22 : 18,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: emphasized ? 6 : 5,
        vertical: emphasized ? 3 : 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: emphasized ? 0.18 : 0.1),
            blurRadius: emphasized ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
          fontSize: emphasized ? 11 : 10,
        ),
      ),
    );
  }
}

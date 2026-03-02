// this file is fully from vibe. is it reliable?

import 'package:bluefish/viewModels/mention_reply_view_model.dart';
import 'package:bluefish/widgets/mention_reply_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MentionReplyPage extends StatelessWidget {
  const MentionReplyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MentionReplyViewModel()..init(),
      child: const MentionReplyPageView(),
    );
  }
}

class MentionReplyPageView extends StatefulWidget {
  const MentionReplyPageView({super.key});

  @override
  State<MentionReplyPageView> createState() => _MentionReplyPageViewState();
}

class _MentionReplyPageViewState extends State<MentionReplyPageView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final vm = context.read<MentionReplyViewModel>();
      if (!vm.isLoading && vm.hasNextPage) {
        vm.getMoreReplies();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MentionReplyViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (viewModel.isLoading &&
        viewModel.newList.isEmpty &&
        viewModel.oldList.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (viewModel.newList.isEmpty && viewModel.oldList.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                "暂无消息",
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        // TODO: check if this indicator is necessary?
        child: RefreshIndicator(
          onRefresh: () => viewModel.init(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // TODO: maybe remove this head bar later.
              // 顶部标题栏
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  child: Container(
                    color: colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alternate_email,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "@我的",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),

                        // TODO: make sure whether keep this number.
                        // 新消息数量徽章
                        if (viewModel.newList.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${viewModel.newList.length}",
                              style: TextStyle(
                                color: colorScheme.onError,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              MentionReplyListWidget(
                newReplies: viewModel.newList,
                oldReplies: viewModel.oldList,
                isLoading: viewModel.isLoading,
                hasNextPage: viewModel.hasNextPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//TODO: know and learn more about this widget(or delegate).
/// 粘性头部代理
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
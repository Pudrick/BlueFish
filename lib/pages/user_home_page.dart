import 'package:bluefish/models/user_homepage/user_home.dart';
import 'package:bluefish/viewModels/user_home_view_model.dart';
import 'package:bluefish/widgets/user_home_display_select_widget.dart';
import 'package:bluefish/widgets/user_home_info_widget.dart';
import 'package:bluefish/widgets/user_home_reply_list_widget.dart';
import 'package:bluefish/widgets/user_home_thread_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserHomePage extends StatelessWidget {
  final int euid;
  const UserHomePage({super.key, required this.euid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserHomeViewModel>(
      create: (_) => UserHomeViewModel(euid: euid)..init(),
      child: const UserHomePageView(),
    );
  }
}

class UserHomePageView extends StatefulWidget {
  const UserHomePageView({super.key});

  @override
  State<UserHomePageView> createState() => _UserHomePageViewState();
}

class _UserHomePageViewState extends State<UserHomePageView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final vm = context.read<UserHomeViewModel>();
      switch (vm.displayStatus) {
        case DisplayStatus.threads:
        if(!vm.isLoadingThreads) {
          vm.loadMoreThreads();
        }
          break;
        case DisplayStatus.replies:
        if (!vm.isLoadingReplies) {
          vm.loadMoreReplies();
          break;
        }
        case DisplayStatus.recommends:
        if(!vm.isLoadingRecommends) {
          vm.loadMoreRecommends();
        }
          break;
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
    final viewModel = context.watch<UserHomeViewModel>();

    if (viewModel.data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    UserHome data = viewModel.data!;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: UserHomeInfoWidget(userHome: data),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: UserHomeDisplaySelectWidget(
                  onTabChanged: () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        // this height is measured on Windows. Android is same? 
                        260.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
            ),

            switch (viewModel.displayStatus) {
              DisplayStatus.threads => UserHomeThreadListWidget(
                threadsList: data.threads,
                isLoading: viewModel.isLoadingThreads,
                isLastPage: viewModel.isLastThreadPage,
              ),
              DisplayStatus.replies => UserHomeReplyListWidget(
                replyList: data.replies,
                isLoading: viewModel.isLoadingReplies,
                isLastPage: viewModel.isLastReplyPage,
              ),
              DisplayStatus.recommends => UserHomeThreadListWidget(
                threadsList: data.recommendThreads,
                isLoading: viewModel.isLoadingRecommends,
                isLastPage: viewModel.isLastRecommendPage,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

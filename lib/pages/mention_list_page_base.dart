import 'package:bluefish/viewModels/mention_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef MentionListSliverBuilder<T, VM extends MentionViewModel<T>> =
    Widget Function(BuildContext context, VM viewModel);

class MentionListPage<T, VM extends MentionViewModel<T>>
    extends StatelessWidget {
  final VM Function() createViewModel;
  final MentionListSliverBuilder<T, VM> buildListSliver;
  final IconData titleIcon;
  final String title;
  final double bottomInset;

  const MentionListPage({
    super.key,
    required this.createViewModel,
    required this.buildListSliver,
    required this.titleIcon,
    required this.title,
    this.bottomInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MentionListSection<T, VM>(
          createViewModel: createViewModel,
          buildListSliver: buildListSliver,
          titleIcon: titleIcon,
          title: title,
          bottomInset: bottomInset,
        ),
      ),
    );
  }
}

class MentionListSection<T, VM extends MentionViewModel<T>>
    extends StatelessWidget {
  final VM Function()? createViewModel;
  final VM? viewModel;
  final MentionListSliverBuilder<T, VM> buildListSliver;
  final IconData? titleIcon;
  final String? title;
  final double bottomInset;

  const MentionListSection({
    super.key,
    this.createViewModel,
    this.viewModel,
    required this.buildListSliver,
    this.titleIcon,
    this.title,
    this.bottomInset = 0,
  }) : assert(
         (createViewModel == null) != (viewModel == null),
         'Provide either createViewModel or viewModel.',
       );

  @override
  Widget build(BuildContext context) {
    final child = _MentionListSectionView<T, VM>(
      buildListSliver: buildListSliver,
      titleIcon: titleIcon,
      title: title,
      bottomInset: bottomInset,
    );

    if (viewModel != null) {
      return ChangeNotifierProvider<VM>.value(value: viewModel!, child: child);
    }

    return ChangeNotifierProvider<VM>(
      create: (_) => createViewModel!()..init(),
      child: child,
    );
  }
}

class _MentionListSectionView<T, VM extends MentionViewModel<T>>
    extends StatefulWidget {
  final MentionListSliverBuilder<T, VM> buildListSliver;
  final IconData? titleIcon;
  final String? title;
  final double bottomInset;

  const _MentionListSectionView({
    required this.buildListSliver,
    required this.titleIcon,
    required this.title,
    required this.bottomInset,
  });

  @override
  State<_MentionListSectionView<T, VM>> createState() =>
      _MentionListSectionViewState<T, VM>();
}

class _MentionListSectionViewState<T, VM extends MentionViewModel<T>>
    extends State<_MentionListSectionView<T, VM>> {
  static const double _loadMoreTriggerDistance = 80;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _maybeLoadMoreForViewport(context.read<VM>());
  }

  void _maybeLoadMoreForViewport(VM viewModel) {
    if (!_scrollController.hasClients ||
        viewModel.isLoading ||
        !viewModel.hasNextPage) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter <= _loadMoreTriggerDistance) {
      viewModel.loadMore();
    }
  }

  void _scheduleViewportFillCheck(VM viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _maybeLoadMoreForViewport(viewModel);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VM>();
    final colorScheme = Theme.of(context).colorScheme;

    if (viewModel.isLoading &&
        viewModel.newList.isEmpty &&
        viewModel.oldList.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (viewModel.newList.isEmpty && viewModel.oldList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => viewModel.init(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.only(bottom: widget.bottomInset),
                  child: Center(
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
                          '暂无消息',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    _scheduleViewportFillCheck(viewModel);

    return RefreshIndicator(
      onRefresh: () => viewModel.init(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.titleIcon != null && widget.title != null)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: _MentionListHeader<T, VM>(
                  titleIcon: widget.titleIcon!,
                  title: widget.title!,
                ),
              ),
            ),
          widget.buildListSliver(context, viewModel),
          if (widget.bottomInset > 0)
            SliverToBoxAdapter(child: SizedBox(height: widget.bottomInset)),
        ],
      ),
    );
  }
}

class _MentionListHeader<T, VM extends MentionViewModel<T>>
    extends StatelessWidget {
  final IconData titleIcon;
  final String title;

  const _MentionListHeader({required this.titleIcon, required this.title});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VM>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(titleIcon, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (viewModel.newList.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${viewModel.newList.length}',
                style: TextStyle(
                  color: colorScheme.onError,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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

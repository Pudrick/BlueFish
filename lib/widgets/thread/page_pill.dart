import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PagePill extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  final VoidCallback onPageTap;

  const PagePill({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
    const double height = 42;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.96),
      shape: StadiumBorder(
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      elevation: 2,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPageTap();
        },
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '$currentPage / $totalPages',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

void showPageMenu({
  required BuildContext context,
  required int currentPage,
  required int totalPages,
  required Function(int) onPageSelected,
  double bottomSpaceHeight = 80,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    useSafeArea: true,
    builder: (context) {
      return _PageSheet(
        currentPage: currentPage,
        totalpages: totalPages,
        onPageSelected: onPageSelected,
        bottomSpaceHeight: bottomSpaceHeight,
      );
    },
  );
}

class _PageSheet extends StatefulWidget {
  final int currentPage;
  final int totalpages;
  final Function(int) onPageSelected;
  final double bottomSpaceHeight;

  const _PageSheet({
    required this.currentPage,
    required this.totalpages,
    required this.onPageSelected,
    required this.bottomSpaceHeight,
  });

  @override
  State<StatefulWidget> createState() => _PageSheetState();
}

class _PageSheetState extends State<_PageSheet> {
  late double _sliderValue;

  ScrollController? _scrollController;
  double? _gridWidth;
  int _crossAxisCount = 5;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentPage.toDouble();
  }

  void _jumpTo(int page) {
    if (page < 1 || page > widget.totalpages) return;
    Navigator.pop(context);
    widget.onPageSelected(page);
  }

  double _calculateScrollOffset(
    int page,
    double gridWidth,
    int crossAxisCount,
  ) {
    const double crossAxisSpacing = 10.0;
    const double mainAxisSpacing = 10.0;
    const double childAspectRatio = 1.0;
    const double containerHeight = 180.0;

    final double itemWidth =
        (gridWidth - ((crossAxisCount - 1) * crossAxisSpacing)) /
        crossAxisCount;
    final double itemHeight = itemWidth / childAspectRatio;

    final int targetIndex = page - 1;
    final int targetRow = targetIndex ~/ crossAxisCount;

    final double rowTopOffset = targetRow * (itemHeight + mainAxisSpacing);

    double targetOffset =
        rowTopOffset - (containerHeight / 2) + (itemHeight / 2);

    return max(0, targetOffset);
  }

  void _onSliderChanged(double value) {
    setState(() => _sliderValue = value);
  }

  void _onSliderChangeEnd(double value) {
    if (_gridWidth != null &&
        _scrollController != null &&
        _scrollController!.hasClients) {
      final offset = _calculateScrollOffset(
        value.toInt(),
        _gridWidth!,
        _crossAxisCount,
      );
      _scrollController!.animateTo(
        offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '跳转到页码',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_sliderValue.toInt()} / ${widget.totalpages}',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Slider bar
                if (widget.totalpages > 1) ...[
                  Row(
                    children: [
                      Text(
                        "1",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _sliderValue,
                          min: 1,
                          max: widget.totalpages.toDouble(),
                          divisions: widget.totalpages > 1
                              ? widget.totalpages - 1
                              : 1,
                          label: _sliderValue.toInt().toString(),
                          onChanged: _onSliderChanged,
                          onChangeEnd: _onSliderChangeEnd,
                        ),
                      ),
                      Text(
                        "${widget.totalpages}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '当前第 ${_sliderValue.toInt()} 页',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                ],
                Flexible(
                  child: SizedBox(
                    height: 180,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _gridWidth = constraints.maxWidth;
                        _crossAxisCount = constraints.maxWidth < 360
                            ? 4
                            : constraints.maxWidth >= 480
                            ? 6
                            : 5;

                        if (_scrollController == null) {
                          final initialOffset = _calculateScrollOffset(
                            widget.currentPage,
                            constraints.maxWidth,
                            _crossAxisCount,
                          );
                          _scrollController = ScrollController(
                            initialScrollOffset: initialOffset,
                          );
                        }

                        return GridView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: widget.totalpages,
                          itemBuilder: (ctx, index) {
                            final page = index + 1;
                            final isCurrent = page == _sliderValue.toInt();

                            return Padding(
                              padding: const EdgeInsets.all(2),
                              child: Material(
                                color: isCurrent
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () async {
                                    setState(() {
                                      _sliderValue = page.toDouble();
                                    });
                                    await Future.delayed(
                                      const Duration(milliseconds: 150),
                                    );
                                    _jumpTo(page);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      "$page",
                                      style: TextStyle(
                                        color: isCurrent
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.translucent,
          child: SizedBox(height: widget.bottomSpaceHeight),
        ),
      ],
    );
  }
}

import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'dart:math';

class PagePill extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  final VoidCallback onPageTap;

  const PagePill(
      {super.key,
      required this.currentPage,
      required this.totalPages,
      required this.onPageTap});

  @override
  Widget build(BuildContext context) {
    const double height = 40;
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = colorScheme.inverseSurface;
    final defaultContentColor = colorScheme.onInverseSurface;

    final activeColor = colorScheme.primaryFixedDim;

    return Material(
      color: backgroundColor,
      shape: const StadiumBorder(),
      elevation: 6,
      shadowColor: Colors.black45,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VerticalDivider(
                width: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
                color: defaultContentColor.withValues(alpha: 0.3)),
            InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPageTap();
                },
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text("$currentPage / $totalPages",
                          style: TextStyle(
                            color: defaultContentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    )))
          ],
        ),
      ),
    );
  }
}

void showPageMenu(
    {required BuildContext context,
    required int currentPage,
    required int totalPages,
    required Function(int) onPageSelected,
    double bottomSpaceHeight = 80}) {
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
            bottomSpaceHeight: bottomSpaceHeight);
      });
}

class _PageSheet extends StatefulWidget {
  final int currentPage;
  final int totalpages;
  final Function(int) onPageSelected;
  final double bottomSpaceHeight;

  const _PageSheet(
      {required this.currentPage,
      required this.totalpages,
      required this.onPageSelected,
      required this.bottomSpaceHeight});

  @override
  State<StatefulWidget> createState() => _PageSheetState();
}

class _PageSheetState extends State<_PageSheet> {
  late double _sliderValue;

  ScrollController? _scrollController;
  double? _gridWidth;

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

  double _calculateScrollOffset(int page, double gridWidth) {
    const int crossAxisCount = 5;
    const double crossAxisSpacing = 10.0;
    const double mainAxisSpacing = 10.0;
    const double childAspectRatio = 1.1;
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
      final offset = _calculateScrollOffset(value.toInt(), _gridWidth!);
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
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ]),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "共${widget.totalpages}页",
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.outline),
                    ),
                    const SizedBox(
                      height: 24,
                    ),

                    // Slider bar
                    if (widget.totalpages > 1) ...[
                      Row(
                        children: [
                          Text(
                            "1",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary),
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
                          )),
                          Text(
                            "${widget.totalpages}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary),
                          )
                        ],
                      ),
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: colorScheme.onSecondaryContainer,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text("woo"),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                    Flexible(
                        child: SizedBox(
                      height: 180,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          _gridWidth = constraints.maxWidth;

                          if (_scrollController == null) {
                            final initialOffset = _calculateScrollOffset(
                                widget.currentPage, constraints.maxWidth);
                            _scrollController = ScrollController(
                                initialScrollOffset: initialOffset);
                          }

                          return GridView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 5,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.1),
                              itemCount: widget.totalpages,
                              itemBuilder: (ctx, index) {
                                final page = index + 1;
                                final isCurrent = page == _sliderValue.toInt();

                                return Material(
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
                                          const Duration(milliseconds: 150));
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
                                );
                              });
                        },
                      ),
                    )),
                  ])),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.translucent,
          child: SizedBox(
            height: widget.bottomSpaceHeight,
          ),
        )
      ],
    );
  }
}

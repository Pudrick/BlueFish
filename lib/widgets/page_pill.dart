import "package:flutter/material.dart";
import 'package:flutter/services.dart';

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


void showPageMenu({
  required BuildContext context, 
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
      builder: (context){
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
                        divisions:
                            widget.totalpages > 1 ? widget.totalpages - 1 : 1,
                        label: _sliderValue.toInt().toString(),
                        onChanged: (val) {
                          setState(() => _sliderValue = val);
                          HapticFeedback.selectionClick();
                        },
                        onChangeEnd: (value) => _jumpTo(value.toInt()),
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
                  child: GridView.builder(
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
                        final isCurrent = page == widget.currentPage;

                        return Material(
                          color: isCurrent ? colorScheme.primary: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),

                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () async { 
                              await Future.delayed(const Duration(milliseconds: 150));
                              _jumpTo(page);},
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
                      }),
                ))
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.translucent,
          child: SizedBox(height: widget.bottomSpaceHeight,),
        )
      ],
    );
  }
}

import "package:flutter/material.dart";
import 'package:flutter/services.dart';

class PagePill extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isReversed;

  final VoidCallback onToggleSort;

  const PagePill({super.key, required this.currentPage, required this.totalPages, required this.isReversed, required this.onToggleSort});

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
        child: Row (
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: isReversed ? "当前为倒序查看" : "当前为正序查看",
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggleSort();
                },
                child: Container(
                  width: height,
                  alignment: Alignment.center,
                  child: AnimatedRotation(
                    turns: isReversed ? 0.5 : 0, 
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.sort, 
                      size: 22, 
                      color: isReversed ? activeColor : defaultContentColor,
                    ),
                  ),
                ),
              ),
            ),

            VerticalDivider(
              width: 1, 
              thickness: 1, 
              indent: 12,
              endIndent: 12,
              color: defaultContentColor.withValues(alpha: 0.3)
            ),

            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // onPageTap();
              },
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "$currentPage / $totalPages",
                  style: TextStyle(
                    color: defaultContentColor,
                    fontWeight: FontWeight.w600, 
                    fontSize: 14, 
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
              )
              )
            )
          ],
        ),
      ),
    );
  }
}
import 'dart:ui';

import 'package:bluefish/utils/thread_title_mask_rules.dart';
import 'package:flutter/material.dart';

class ThreadTitleBlurMask extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  final double topOffset;
  final List<ThreadTitleMaskRule> rules;

  const ThreadTitleBlurMask({
    super.key,
    required this.title,
    required this.child,
    this.height = 96,
    this.topOffset = 0,
    this.rules = kThreadTitleMaskRules,
  });

  @override
  Widget build(BuildContext context) {
    final matchedRule = matchThreadTitleMaskRule(title, rules: rules);
    if (matchedRule == null) {
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: topOffset,
          right: 0,
          child: IgnorePointer(
            child: SizedBox(
              height: height,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.8),
                          colorScheme.surface.withValues(alpha: 0.56),
                          colorScheme.surface.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.62, 1],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.88),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 14,
                                  color: colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  matchedRule.label,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

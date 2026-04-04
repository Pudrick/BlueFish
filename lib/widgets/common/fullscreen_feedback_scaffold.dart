import 'package:flutter/material.dart';

class FullscreenFeedbackScaffold extends StatelessWidget {
  final VoidCallback onBackPressed;
  final Widget child;
  final String backTooltip;
  final EdgeInsetsGeometry contentPadding;

  const FullscreenFeedbackScaffold({
    super.key,
    required this.onBackPressed,
    required this.child,
    this.backTooltip = '返回',
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Padding(padding: contentPadding, child: child),
              ),
            ),
            PositionedDirectional(
              top: 8,
              start: 12,
              child: IconButton.filledTonal(
                onPressed: onBackPressed,
                tooltip: backTooltip,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

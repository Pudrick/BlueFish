import 'package:flutter/material.dart';

class ThreadReplyInteractiveIconSurface extends StatefulWidget {
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? tooltip;
  final Color baseColor;
  final Color hoverColor;
  final Color pressedColor;
  final Color inkColor;
  final double width;
  final double height;
  final double borderRadius;
  final Widget child;

  const ThreadReplyInteractiveIconSurface({
    super.key,
    required this.semanticLabel,
    required this.baseColor,
    required this.hoverColor,
    required this.pressedColor,
    required this.inkColor,
    required this.child,
    this.onTap,
    this.tooltip,
    this.width = 40,
    this.height = 40,
    this.borderRadius = 12,
  });

  @override
  State<ThreadReplyInteractiveIconSurface> createState() =>
      _ThreadReplyInteractiveIconSurfaceState();
}

class _ThreadReplyInteractiveIconSurfaceState
    extends State<ThreadReplyInteractiveIconSurface> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _pressed
        ? widget.pressedColor
        : _hovered
        ? widget.hoverColor
        : widget.baseColor;

    return Tooltip(
      message: widget.tooltip ?? widget.semanticLabel,
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (value) {
                if (widget.onTap == null || _hovered == value) {
                  return;
                }
                setState(() {
                  _hovered = value;
                });
              },
              onHighlightChanged: (value) {
                if (widget.onTap == null || _pressed == value) {
                  return;
                }
                setState(() {
                  _pressed = value;
                });
              },
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashFactory: InkRipple.splashFactory,
              hoverColor: widget.inkColor.withValues(alpha: 0.06),
              highlightColor: widget.inkColor.withValues(alpha: 0.08),
              splashColor: widget.inkColor.withValues(alpha: 0.14),
              child: SizedBox.expand(child: Center(child: widget.child)),
            ),
          ),
        ),
      ),
    );
  }
}

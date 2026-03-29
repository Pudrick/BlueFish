import 'package:flutter/material.dart';

class BluefishDetailsWidget extends StatefulWidget {
  final Widget summary;
  final Widget content;
  final bool hasContent;
  final bool initiallyOpen;

  const BluefishDetailsWidget({
    super.key,
    required this.summary,
    required this.content,
    required this.hasContent,
    this.initiallyOpen = false,
  });

  @override
  State<BluefishDetailsWidget> createState() => _BluefishDetailsWidgetState();
}

class _BluefishDetailsWidgetState extends State<BluefishDetailsWidget> {
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.initiallyOpen;
  }

  @override
  void didUpdateWidget(covariant BluefishDetailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyOpen != widget.initiallyOpen) {
      _isOpen = widget.initiallyOpen;
    }
  }

  void _toggle() {
    if (!widget.hasContent) {
      return;
    }

    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    const cornerRadius = Radius.circular(8);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detailsColor = colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.65,
    );
    final headerRadius = BorderRadius.vertical(
      top: cornerRadius,
      bottom: _isOpen && widget.hasContent ? Radius.zero : cornerRadius,
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(cornerRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: detailsColor,
            borderRadius: const BorderRadius.all(cornerRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggle,
                  borderRadius: headerRadius,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 180),
                            turns: _isOpen ? 0.25 : 0,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DefaultTextStyle.merge(
                            style:
                                textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ) ??
                                const TextStyle(fontWeight: FontWeight.w700),
                            child: IconTheme.merge(
                              data: IconThemeData(color: colorScheme.onSurface),
                              child: widget.summary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isOpen && widget.hasContent) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.9),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.content,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

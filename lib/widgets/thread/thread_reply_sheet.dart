import 'package:flutter/material.dart';

Future<String?> showThreadReplySheet({
  required BuildContext context,
  required Future<void> Function(String content) onSubmit,
  String title = '回复主题',
  String submitLabel = '发送',
  String hintText = '输入回复...',
  String? initialText,
  String? contextLabel,
  String? contextPreview,
  bool autofocus = true,
  bool closeOnSubmit = true,
  int minLines = 4,
  int maxLines = 8,
  List<ThreadReplySheetAction> actions = const [],
  List<ThreadReplySheetAction> overflowActions = const [],
  int collapsedContextPreviewLines = 3,
  double minChildSize = 0.36,
  double initialChildSize = 0.68,
  double maxChildSize = 1.0,
}) {
  final rootMediaQuery = MediaQuery.of(context);

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      minHeight: rootMediaQuery.size.height,
      maxHeight: rootMediaQuery.size.height,
    ),
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return ThreadReplySheet(
        title: title,
        submitLabel: submitLabel,
        hintText: hintText,
        initialText: initialText,
        contextLabel: contextLabel,
        contextPreview: contextPreview,
        autofocus: autofocus,
        closeOnSubmit: closeOnSubmit,
        minLines: minLines,
        maxLines: maxLines,
        actions: actions,
        overflowActions: overflowActions,
        collapsedContextPreviewLines: collapsedContextPreviewLines,
        minChildSize: minChildSize,
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        viewportHeight: rootMediaQuery.size.height,
        topSafePadding: rootMediaQuery.padding.top,
        onSubmit: onSubmit,
      );
    },
  );
}

class ThreadReplySheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String hintText;
  final String? initialText;
  final String? contextLabel;
  final String? contextPreview;
  final bool autofocus;
  final bool closeOnSubmit;
  final int minLines;
  final int maxLines;
  final List<ThreadReplySheetAction> actions;
  final List<ThreadReplySheetAction> overflowActions;
  final int collapsedContextPreviewLines;
  final double minChildSize;
  final double initialChildSize;
  final double maxChildSize;
  final double viewportHeight;
  final double topSafePadding;
  final Future<void> Function(String content) onSubmit;

  const ThreadReplySheet({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.hintText,
    required this.onSubmit,
    this.initialText,
    this.contextLabel,
    this.contextPreview,
    this.autofocus = true,
    this.closeOnSubmit = true,
    this.minLines = 4,
    this.maxLines = 8,
    this.actions = const [],
    this.overflowActions = const [],
    this.collapsedContextPreviewLines = 3,
    this.minChildSize = 0.36,
    this.initialChildSize = 0.68,
    this.maxChildSize = 1.0,
    required this.viewportHeight,
    this.topSafePadding = 0,
  }) : assert(minLines > 0),
       assert(maxLines >= minLines),
       assert(collapsedContextPreviewLines > 0),
       assert(minChildSize > 0),
       assert(initialChildSize >= minChildSize),
       assert(maxChildSize >= initialChildSize),
       assert(maxChildSize <= 1.0),
       assert(viewportHeight > 0),
       assert(topSafePadding >= 0);

  @override
  State<ThreadReplySheet> createState() => _ThreadReplySheetState();
}

class _ThreadReplySheetState extends State<ThreadReplySheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final DraggableScrollableController _sheetController;

  bool _isSubmitting = false;
  bool _isOverflowExpanded = false;
  late double _currentSheetExtent;

  bool get _canSubmit => !_isSubmitting && _controller.text.trim().isNotEmpty;
  List<ThreadReplySheetAction> get _allActions => [
    ...widget.actions,
    ...widget.overflowActions,
  ];
  double get _fullScreenProgress {
    final fullscreenStart = (widget.maxChildSize - 0.08).clamp(
      widget.initialChildSize,
      widget.maxChildSize,
    );
    final extentRange = widget.maxChildSize - fullscreenStart;
    if (extentRange <= 0.0001) {
      return _currentSheetExtent >= widget.maxChildSize ? 1.0 : 0.0;
    }
    return ((_currentSheetExtent - fullscreenStart) / extentRange).clamp(
      0.0,
      1.0,
    );
  }

  bool get _hasContextCard =>
      (widget.contextLabel?.trim().isNotEmpty ?? false) ||
      (widget.contextPreview?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _focusNode = FocusNode();
    _sheetController = DraggableScrollableController();
    _currentSheetExtent = widget.initialChildSize;
    _controller.addListener(_handleTextChanged);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    _focusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _closeSheet() {
    Navigator.of(context).maybePop();
  }

  void _toggleOverflowActions() {
    setState(() {
      _isOverflowExpanded = !_isOverflowExpanded;
    });
  }

  Future<void> _collapseToInitialExtent() async {
    if (!_sheetController.isAttached) {
      return;
    }
    await _sheetController.animateTo(
      widget.initialChildSize,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _handleSubmit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) {
      if (content.isEmpty) {
        _showSnackBar('回复内容不能为空');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(content);
      if (!mounted) {
        return;
      }
      if (widget.closeOnSubmit) {
        Navigator.of(context).pop(content);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('发送失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = widget.viewportHeight - keyboardInset;
    final sheetHostHeight = availableHeight
        .clamp(1.0, double.infinity)
        .toDouble();
    final shellPadding = EdgeInsets.lerp(
      const EdgeInsets.symmetric(horizontal: 12),
      EdgeInsets.zero,
      _fullScreenProgress,
    )!;
    final surfaceRadius =
        BorderRadius.lerp(
          const BorderRadius.vertical(top: Radius.circular(28)),
          BorderRadius.zero,
          _fullScreenProgress,
        ) ??
        BorderRadius.zero;
    final headerTopPadding = 12 + (widget.topSafePadding * _fullScreenProgress);
    final inputMinHeight = (widget.minLines * 24.0) + 32;
    final isFullScreen = _fullScreenProgress > 0.92;
    final surfaceBorderColor = Color.lerp(
      colorScheme.outlineVariant.withValues(alpha: 0.28),
      Colors.transparent,
      _fullScreenProgress,
    )!;
    final surfaceShadowColor = Color.lerp(
      Colors.black.withValues(alpha: 0.12),
      Colors.transparent,
      _fullScreenProgress,
    )!;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: shellPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SizedBox(
              width: double.infinity,
              height: sheetHostHeight,
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  if ((_currentSheetExtent - notification.extent).abs() >
                      0.0005) {
                    setState(() {
                      _currentSheetExtent = notification.extent;
                    });
                  }
                  return false;
                },
                child: DraggableScrollableSheet(
                  controller: _sheetController,
                  expand: false,
                  minChildSize: widget.minChildSize,
                  initialChildSize: widget.initialChildSize,
                  maxChildSize: widget.maxChildSize,
                  builder: (context, scrollController) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: surfaceRadius,
                        border: Border.all(color: surfaceBorderColor),
                        boxShadow: [
                          BoxShadow(
                            color: surfaceShadowColor,
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: surfaceRadius,
                        child: Material(
                          key: const ValueKey('thread_reply_sheet_surface'),
                          color: Colors.transparent,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final estimatedContextHeight = _hasContextCard
                                  ? 112.0
                                  : 0.0;
                              final estimatedActionsHeight =
                                  _allActions.isNotEmpty ? 56.0 : 0.0;
                              final availableInputHeight =
                                  constraints.maxHeight -
                                  headerTopPadding -
                                  116 -
                                  estimatedContextHeight -
                                  estimatedActionsHeight;
                              final usesCompactLayout =
                                  availableInputHeight < 72;
                              final effectiveInputMinHeight = usesCompactLayout
                                  ? 120.0
                                  : availableInputHeight
                                        .clamp(72.0, inputMinHeight)
                                        .toDouble();

                              Widget buildHandle({required bool compact}) {
                                final showFullScreenHandle =
                                    isFullScreen && !compact;
                                return Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, -0.15),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: showFullScreenHandle
                                        ? Container(
                                            key: const ValueKey(
                                              'thread_reply_sheet_fullscreen_handle',
                                            ),
                                            width: 30,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: colorScheme.outline,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          )
                                        : Opacity(
                                            key: const ValueKey(
                                              'thread_reply_sheet_default_handle',
                                            ),
                                            opacity: 1 - _fullScreenProgress,
                                            child: Container(
                                              width: 40,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color:
                                                    colorScheme.outlineVariant,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ),
                                  ),
                                );
                              }

                              Widget buildHeader({required bool compact}) {
                                final headerActionBaseColor =
                                    isFullScreen && !compact
                                    ? colorScheme.surfaceContainerLow
                                    : Colors.transparent;
                                final headerActionHoverColor =
                                    isFullScreen && !compact
                                    ? colorScheme.surfaceContainerHighest
                                    : colorScheme.surfaceContainerLow
                                          .withValues(alpha: 0.72);
                                final headerActionPressedColor =
                                    isFullScreen && !compact
                                    ? colorScheme.surfaceContainerHighest
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.92);
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            style:
                                                (isFullScreen && !compact
                                                        ? textTheme.titleLarge
                                                        : textTheme.titleMedium)
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ) ??
                                                const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                            child: Text(widget.title),
                                          ),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            child: isFullScreen && !compact
                                                ? const SizedBox.shrink()
                                                : Padding(
                                                    key: const ValueKey(
                                                      'thread_reply_sheet_subtitle',
                                                    ),
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      '默认保留顶部留白，可继续上滑展开；发送前会自动去除首尾空白',
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          transitionBuilder:
                                              (child, animation) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SizeTransition(
                                                    sizeFactor: animation,
                                                    axis: Axis.horizontal,
                                                    axisAlignment: 1,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                          child: isFullScreen && !compact
                                              ? Padding(
                                                  key: const ValueKey(
                                                    'thread_reply_sheet_collapse_button_wrapper',
                                                  ),
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 4,
                                                      ),
                                                  child: _InteractiveIconSurface(
                                                    key: const ValueKey(
                                                      'thread_reply_sheet_collapse_button',
                                                    ),
                                                    semanticLabel: '收起到默认高度',
                                                    tooltip: '收起到默认高度',
                                                    onTap: _isSubmitting
                                                        ? null
                                                        : _collapseToInitialExtent,
                                                    baseColor:
                                                        headerActionBaseColor,
                                                    hoverColor:
                                                        headerActionHoverColor,
                                                    pressedColor:
                                                        headerActionPressedColor,
                                                    inkColor:
                                                        colorScheme.onSurface,
                                                    child: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      size: 22,
                                                      color:
                                                          colorScheme.onSurface,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink(
                                                  key: ValueKey(
                                                    'thread_reply_sheet_collapse_button_hidden',
                                                  ),
                                                ),
                                        ),
                                        _InteractiveIconSurface(
                                          key: const ValueKey(
                                            'thread_reply_sheet_close_button',
                                          ),
                                          semanticLabel: '关闭',
                                          tooltip: '关闭',
                                          onTap: _isSubmitting
                                              ? null
                                              : _closeSheet,
                                          baseColor: headerActionBaseColor,
                                          hoverColor: headerActionHoverColor,
                                          pressedColor:
                                              headerActionPressedColor,
                                          inkColor: colorScheme.onSurface,
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 22,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              Widget buildActionSection() {
                                if (_allActions.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SizeTransition(
                                            sizeFactor: animation,
                                            axisAlignment: -1,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _isOverflowExpanded
                                          ? _ExpandedActionPanel(
                                              key: const ValueKey(
                                                'thread_reply_sheet_all_actions_panel',
                                              ),
                                              actions: _allActions,
                                              onToggleOverflow:
                                                  _toggleOverflowActions,
                                            )
                                          : _ReplyActionRow(
                                              key: const ValueKey(
                                                'thread_reply_sheet_primary_actions',
                                              ),
                                              actions: widget.actions,
                                              hasOverflowActions: widget
                                                  .overflowActions
                                                  .isNotEmpty,
                                              onToggleOverflow:
                                                  _toggleOverflowActions,
                                            ),
                                    ),
                                  ],
                                );
                              }

                              Widget buildFooter() {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '当前字数 ${_controller.text.length}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _closeSheet,
                                      child: const Text('取消'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      key: const ValueKey(
                                        'thread_reply_sheet_submit',
                                      ),
                                      onPressed: _canSubmit
                                          ? _handleSubmit
                                          : null,
                                      icon: _isSubmitting
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : const Icon(Icons.send_rounded),
                                      label: Text(widget.submitLabel),
                                    ),
                                  ],
                                );
                              }

                              final contentPadding = EdgeInsets.fromLTRB(
                                20,
                                headerTopPadding,
                                20,
                                16,
                              );

                              if (!usesCompactLayout) {
                                return ListView(
                                  controller: scrollController,
                                  physics: const ClampingScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: constraints.maxHeight,
                                      child: Padding(
                                        padding: contentPadding,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            buildHandle(compact: false),
                                            const SizedBox(height: 16),
                                            buildHeader(compact: false),
                                            if (_hasContextCard) ...[
                                              const SizedBox(height: 12),
                                              _ReplyContextCard(
                                                label: widget.contextLabel,
                                                preview: widget.contextPreview,
                                                collapsedMaxLines: widget
                                                    .collapsedContextPreviewLines,
                                              ),
                                            ],
                                            const SizedBox(height: 16),
                                            Expanded(
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minHeight:
                                                      effectiveInputMinHeight,
                                                ),
                                                child: _ReplyInputBox(
                                                  controller: _controller,
                                                  focusNode: _focusNode,
                                                  hintText: widget.hintText,
                                                  cornerRadius:
                                                      20 -
                                                      (4 * _fullScreenProgress),
                                                  elevated: isFullScreen,
                                                ),
                                              ),
                                            ),
                                            buildActionSection(),
                                            const SizedBox(height: 12),
                                            buildFooter(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return ListView(
                                controller: scrollController,
                                physics: const ClampingScrollPhysics(),
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Padding(
                                      padding: contentPadding,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          buildHandle(compact: true),
                                          const SizedBox(height: 16),
                                          buildHeader(compact: true),
                                          if (_hasContextCard) ...[
                                            const SizedBox(height: 12),
                                            _ReplyContextCard(
                                              label: widget.contextLabel,
                                              preview: widget.contextPreview,
                                              collapsedMaxLines: widget
                                                  .collapsedContextPreviewLines,
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            height: effectiveInputMinHeight,
                                            child: _ReplyInputBox(
                                              controller: _controller,
                                              focusNode: _focusNode,
                                              hintText: widget.hintText,
                                            ),
                                          ),
                                          buildActionSection(),
                                          const SizedBox(height: 12),
                                          buildFooter(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ThreadReplySheetAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool enabled;
  final bool selected;

  const ThreadReplySheetAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.tooltip,
    this.enabled = true,
    this.selected = false,
  });
}

class _ReplyContextCard extends StatefulWidget {
  final String? label;
  final String? preview;
  final int collapsedMaxLines;

  const _ReplyContextCard({
    this.label,
    this.preview,
    required this.collapsedMaxLines,
  });

  @override
  State<_ReplyContextCard> createState() => _ReplyContextCardState();
}

class _ReplyContextCardState extends State<_ReplyContextCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null && widget.label!.trim().isNotEmpty)
            Text(
              widget.label!,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (widget.preview != null && widget.preview!.trim().isNotEmpty) ...[
            if (widget.label != null && widget.label!.trim().isNotEmpty)
              const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final previewText = widget.preview!.trim();
                final previewStyle = textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                );

                final textPainter = TextPainter(
                  text: TextSpan(text: previewText, style: previewStyle),
                  maxLines: widget.collapsedMaxLines,
                  textDirection: Directionality.of(context),
                )..layout(maxWidth: constraints.maxWidth);

                final hasOverflow = textPainter.didExceedMaxLines;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Text(
                        previewText,
                        maxLines: _isExpanded ? null : widget.collapsedMaxLines,
                        overflow: _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: previewStyle,
                      ),
                    ),
                    if (hasOverflow) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey(
                          'thread_reply_sheet_context_toggle',
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                        ),
                        icon: Icon(
                          _isExpanded
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          size: 18,
                        ),
                        label: Text(_isExpanded ? '收起引用' : '展开引用'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ReplyInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final double cornerRadius;
  final bool elevated;

  const _ReplyInputBox({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.cornerRadius = 20,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: elevated
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(cornerRadius),
        border: elevated
            ? Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              )
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        key: const ValueKey('thread_reply_sheet_input'),
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        expands: true,
        minLines: null,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration.collapsed(
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _ReplyActionRow extends StatelessWidget {
  final List<ThreadReplySheetAction> actions;
  final bool hasOverflowActions;
  final VoidCallback onToggleOverflow;

  const _ReplyActionRow({
    super.key,
    required this.actions,
    required this.hasOverflowActions,
    required this.onToggleOverflow,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _ReplyActionButton(action: action),
            );
          }),
          if (hasOverflowActions)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _OverflowToggleButton(
                expanded: false,
                onTap: onToggleOverflow,
              ),
            ),
        ],
      ),
    );
  }
}

class _InteractiveIconSurface extends StatefulWidget {
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? tooltip;
  final Color baseColor;
  final Color hoverColor;
  final Color pressedColor;
  final Color inkColor;
  final Widget child;

  const _InteractiveIconSurface({
    super.key,
    required this.semanticLabel,
    required this.baseColor,
    required this.hoverColor,
    required this.pressedColor,
    required this.inkColor,
    required this.child,
    this.onTap,
    this.tooltip,
  });

  @override
  State<_InteractiveIconSurface> createState() =>
      _InteractiveIconSurfaceState();
}

class _InteractiveIconSurfaceState extends State<_InteractiveIconSurface> {
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
          width: 40,
          height: 40,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
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

class _ReplyActionButton extends StatelessWidget {
  final ThreadReplySheetAction action;
  final String? keyName;

  const _ReplyActionButton({required this.action, this.keyName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = action.enabled
        ? action.selected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return _InteractiveIconSurface(
      key: ValueKey(keyName ?? 'thread_reply_sheet_action_${action.label}'),
      semanticLabel: action.label,
      tooltip: action.tooltip ?? action.label,
      onTap: action.enabled ? action.onTap : null,
      baseColor: action.selected
          ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
          : Colors.transparent,
      hoverColor: action.selected
          ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
          : colorScheme.secondaryContainer.withValues(alpha: 0.4),
      pressedColor: action.selected
          ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
          : colorScheme.secondaryContainer.withValues(alpha: 0.58),
      inkColor: foregroundColor,
      child: Icon(action.icon, size: 22, color: foregroundColor),
    );
  }
}

class _ExpandedActionPanel extends StatelessWidget {
  final List<ThreadReplySheetAction> actions;
  final VoidCallback onToggleOverflow;

  const _ExpandedActionPanel({
    super.key,
    required this.actions,
    required this.onToggleOverflow,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('thread_reply_sheet_more_actions_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 8,
        children: [
          ...actions.map((action) {
            return _ReplyActionButton(
              action: action,
              keyName: 'thread_reply_sheet_expanded_${action.label}',
            );
          }),
          _OverflowToggleButton(expanded: true, onTap: onToggleOverflow),
        ],
      ),
    );
  }
}

class _OverflowToggleButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _OverflowToggleButton({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = expanded
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;
    final baseColor = expanded
        ? colorScheme.errorContainer.withValues(alpha: 0.92)
        : Colors.transparent;
    final hoverColor = expanded
        ? Color.alphaBlend(
            colorScheme.error.withValues(alpha: 0.16),
            colorScheme.errorContainer.withValues(alpha: 0.92),
          )
        : colorScheme.secondaryContainer.withValues(alpha: 0.4);
    final pressedColor = expanded
        ? Color.alphaBlend(
            colorScheme.error.withValues(alpha: 0.28),
            colorScheme.errorContainer.withValues(alpha: 0.92),
          )
        : colorScheme.secondaryContainer.withValues(alpha: 0.58);
    final double iconSize = expanded ? 20 : 22;

    return _InteractiveIconSurface(
      key: const ValueKey('thread_reply_sheet_more_actions_toggle'),
      semanticLabel: expanded ? '收起更多功能' : '展开更多功能',
      tooltip: expanded ? '收起更多功能' : '展开更多功能',
      onTap: onTap,
      baseColor: baseColor,
      hoverColor: hoverColor,
      pressedColor: pressedColor,
      inkColor: foregroundColor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          expanded ? Icons.close_rounded : Icons.add_rounded,
          key: ValueKey(expanded),
          size: iconSize,
          color: foregroundColor,
        ),
      ),
    );
  }
}

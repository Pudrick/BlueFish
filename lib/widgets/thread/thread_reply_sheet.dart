import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'reply_sheet/interactive_icon_surface.dart';
import 'reply_sheet/thread_reply_sheet_actions.dart';
import 'reply_sheet/thread_reply_sheet_context_card.dart';
import 'reply_sheet/thread_reply_sheet_emoji_panel.dart';
import 'reply_sheet/thread_reply_sheet_input_box.dart';
import 'reply_sheet/thread_reply_sheet_models.dart';

export 'reply_sheet/thread_reply_sheet_models.dart';

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
  List<ThreadReplySheetEmojiCategory> emojiCategories =
      ThreadReplySheetEmojiCategory.defaultCategories,
  bool keepEmojiPanelOpenOnInsert = true,
  double emojiPanelMaxHeight = 240,
  int emojiGridCrossAxisCount = 7,
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
        emojiCategories: emojiCategories,
        keepEmojiPanelOpenOnInsert: keepEmojiPanelOpenOnInsert,
        emojiPanelMaxHeight: emojiPanelMaxHeight,
        emojiGridCrossAxisCount: emojiGridCrossAxisCount,
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
  final List<ThreadReplySheetEmojiCategory> emojiCategories;
  final bool keepEmojiPanelOpenOnInsert;
  final double emojiPanelMaxHeight;
  final int emojiGridCrossAxisCount;
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
    this.emojiCategories = ThreadReplySheetEmojiCategory.defaultCategories,
    this.keepEmojiPanelOpenOnInsert = true,
    this.emojiPanelMaxHeight = 240,
    this.emojiGridCrossAxisCount = 7,
    this.collapsedContextPreviewLines = 3,
    this.minChildSize = 0.36,
    this.initialChildSize = 0.68,
    this.maxChildSize = 1.0,
    required this.viewportHeight,
    this.topSafePadding = 0,
  }) : assert(minLines > 0),
       assert(maxLines >= minLines),
       assert(emojiPanelMaxHeight > 0),
       assert(emojiGridCrossAxisCount > 0),
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

enum _ThreadReplySheetAccessoryPanel { none, overflow, emoji }

class _ThreadReplySheetAnimatedAccessoryPanel extends StatefulWidget {
  final bool visible;
  final Object? identity;
  final Widget? child;

  const _ThreadReplySheetAnimatedAccessoryPanel({
    required this.visible,
    required this.identity,
    required this.child,
  });

  @override
  State<_ThreadReplySheetAnimatedAccessoryPanel> createState() =>
      _ThreadReplySheetAnimatedAccessoryPanelState();
}

class _ThreadReplySheetAnimatedAccessoryPanelState
    extends State<_ThreadReplySheetAnimatedAccessoryPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  Widget? _displayedChild;
  Object? _displayedIdentity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    if (widget.visible && widget.child != null) {
      _displayedChild = widget.child;
      _displayedIdentity = widget.identity;
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(
    covariant _ThreadReplySheetAnimatedAccessoryPanel oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final identityChanged = widget.identity != _displayedIdentity;
    final nextChild = widget.child;

    if (widget.visible && nextChild != null) {
      if (!oldWidget.visible || identityChanged || _displayedChild == null) {
        setState(() {
          _displayedChild = nextChild;
          _displayedIdentity = widget.identity;
        });
        _controller.forward(from: 0);
      } else {
        setState(() {
          _displayedChild = nextChild;
          _displayedIdentity = widget.identity;
        });
      }
      return;
    }

    if (_displayedChild != null && _controller.value > 0) {
      _controller.reverse().whenCompleteOrCancel(() {
        if (!mounted || widget.visible) {
          return;
        }
        setState(() {
          _displayedChild = null;
          _displayedIdentity = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedChild == null && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _curve,
      child: IgnorePointer(
        ignoring: _curve.value <= 0.001,
        child: _displayedChild ?? const SizedBox.shrink(),
      ),
      builder: (context, child) {
        final progress = _curve.value;

        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: progress,
            child: Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, (1 - progress) * 20),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThreadReplySheetState extends State<ThreadReplySheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final DraggableScrollableController _sheetController;

  bool _isSubmitting = false;
  _ThreadReplySheetAccessoryPanel _activeAccessoryPanel =
      _ThreadReplySheetAccessoryPanel.none;
  String? _selectedEmojiCategoryKey;
  late double _currentSheetExtent;

  bool get _canSubmit => !_isSubmitting && _controller.text.trim().isNotEmpty;
  List<ThreadReplySheetAction> get _allActions => [
    ...widget.actions,
    ...widget.overflowActions,
  ];
  bool get _hasEmojiPicker => widget.emojiCategories.isNotEmpty;
  bool get _isEmojiPanelExpanded =>
      _activeAccessoryPanel == _ThreadReplySheetAccessoryPanel.emoji &&
      _hasEmojiPicker;
  bool get _isOverflowExpanded =>
      _activeAccessoryPanel == _ThreadReplySheetAccessoryPanel.overflow &&
      widget.overflowActions.isNotEmpty;
  bool get _hasActionControls => _allActions.isNotEmpty || _hasEmojiPicker;
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
  ThreadReplySheetEmojiCategory? get _selectedEmojiCategory {
    if (!_hasEmojiPicker) {
      return null;
    }

    for (final category in widget.emojiCategories) {
      if (category.key == _selectedEmojiCategoryKey) {
        return category;
      }
    }

    return widget.emojiCategories.first;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _focusNode = FocusNode();
    _sheetController = DraggableScrollableController();
    _currentSheetExtent = widget.initialChildSize;
    _selectedEmojiCategoryKey = widget.emojiCategories.isNotEmpty
        ? widget.emojiCategories.first.key
        : null;
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
  void didUpdateWidget(covariant ThreadReplySheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_hasEmojiPicker) {
      final hasMatchingCategory = widget.emojiCategories.any(
        (category) => category.key == _selectedEmojiCategoryKey,
      );
      if (!hasMatchingCategory) {
        _selectedEmojiCategoryKey = widget.emojiCategories.first.key;
      }
    } else {
      _selectedEmojiCategoryKey = null;
      if (_activeAccessoryPanel == _ThreadReplySheetAccessoryPanel.emoji) {
        _activeAccessoryPanel = _ThreadReplySheetAccessoryPanel.none;
      }
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

  Future<void> _toggleEmojiPanel() async {
    if (!_hasEmojiPicker) {
      return;
    }

    final shouldOpen = !_isEmojiPanelExpanded;
    setState(() {
      _activeAccessoryPanel = shouldOpen
          ? _ThreadReplySheetAccessoryPanel.emoji
          : _ThreadReplySheetAccessoryPanel.none;
      _selectedEmojiCategoryKey ??= _selectedEmojiCategory?.key;
    });

    if (shouldOpen) {
      await _ensureExtentForAccessoryPanel();
    }
  }

  Future<void> _toggleOverflowActions() async {
    if (widget.overflowActions.isEmpty) {
      return;
    }

    final shouldOpen = !_isOverflowExpanded;
    setState(() {
      _activeAccessoryPanel = shouldOpen
          ? _ThreadReplySheetAccessoryPanel.overflow
          : _ThreadReplySheetAccessoryPanel.none;
    });

    if (shouldOpen) {
      await _ensureExtentForAccessoryPanel();
    }
  }

  Future<void> _ensureExtentForAccessoryPanel() async {
    if (!_sheetController.isAttached) {
      return;
    }

    final targetExtent = math.min(
      widget.maxChildSize,
      math.max(widget.initialChildSize, 0.8),
    );
    if (_currentSheetExtent >= targetExtent - 0.0005) {
      return;
    }

    await _sheetController.animateTo(
      targetExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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

  void _setSelectedEmojiCategory(String key) {
    if (_selectedEmojiCategoryKey == key) {
      return;
    }
    setState(() {
      _selectedEmojiCategoryKey = key;
    });
  }

  void _insertEmoji(ThreadReplySheetEmojiItem item) {
    final textValue = _controller.value;
    final selection = textValue.selection;
    final text = textValue.text;
    final textLength = text.length;

    final start = selection.isValid
        ? selection.start.clamp(0, textLength).toInt()
        : textLength;
    final end = selection.isValid
        ? selection.end.clamp(0, textLength).toInt()
        : textLength;
    final insertionStart = math.min(start, end);
    final insertionEnd = math.max(start, end);
    final replacementText = item.insertText;
    final nextText = text.replaceRange(
      insertionStart,
      insertionEnd,
      replacementText,
    );
    final caretOffset = insertionStart + replacementText.length;

    _controller.value = textValue.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: caretOffset),
      composing: TextRange.empty,
    );
    _focusNode.requestFocus();

    if (!widget.keepEmojiPanelOpenOnInsert) {
      setState(() {
        _activeAccessoryPanel = _ThreadReplySheetAccessoryPanel.none;
      });
    }
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
                              final estimatedActionsHeight = _hasActionControls
                                  ? 56.0
                                  : 0.0;
                              final estimatedAccessoryPanelHeight =
                                  _isEmojiPanelExpanded
                                  ? widget.emojiPanelMaxHeight + 12
                                  : _isOverflowExpanded
                                  ? 92.0
                                  : 0.0;
                              final availableInputHeight =
                                  constraints.maxHeight -
                                  headerTopPadding -
                                  116 -
                                  estimatedContextHeight -
                                  estimatedActionsHeight -
                                  estimatedAccessoryPanelHeight;
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
                                                  child: ThreadReplyInteractiveIconSurface(
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
                                        ThreadReplyInteractiveIconSurface(
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
                                if (!_hasActionControls) {
                                  return const SizedBox.shrink();
                                }

                                final selectedEmojiCategory =
                                    _selectedEmojiCategory;
                                final accessoryPanelVisible =
                                    _isEmojiPanelExpanded ||
                                    _isOverflowExpanded;
                                final accessoryPanelIdentity =
                                    _isEmojiPanelExpanded
                                    ? _ThreadReplySheetAccessoryPanel.emoji
                                    : _isOverflowExpanded
                                    ? _ThreadReplySheetAccessoryPanel.overflow
                                    : null;
                                final Widget? accessoryPanel =
                                    _isEmojiPanelExpanded &&
                                        selectedEmojiCategory != null
                                    ? ThreadReplySheetEmojiPanel(
                                        key: const ValueKey(
                                          'thread_reply_sheet_emoji_panel_wrapper',
                                        ),
                                        categories: widget.emojiCategories,
                                        selectedCategoryKey:
                                            selectedEmojiCategory.key,
                                        onCategorySelected:
                                            _setSelectedEmojiCategory,
                                        onEmojiSelected: _insertEmoji,
                                        maxHeight: widget.emojiPanelMaxHeight,
                                        crossAxisCount:
                                            widget.emojiGridCrossAxisCount,
                                      )
                                    : _isOverflowExpanded
                                    ? ThreadReplySheetExpandedActionPanel(
                                        key: const ValueKey(
                                          'thread_reply_sheet_all_actions_panel',
                                        ),
                                        actions: widget.overflowActions,
                                        onToggleOverflow: _isSubmitting
                                            ? null
                                            : () {
                                                _toggleOverflowActions();
                                              },
                                      )
                                    : null;

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    ThreadReplySheetActionRow(
                                      key: const ValueKey(
                                        'thread_reply_sheet_primary_actions',
                                      ),
                                      actions: widget.actions,
                                      showEmojiToggle: _hasEmojiPicker,
                                      emojiExpanded: _isEmojiPanelExpanded,
                                      onToggleEmoji: _isSubmitting
                                          ? null
                                          : () {
                                              _toggleEmojiPanel();
                                            },
                                      hasOverflowActions:
                                          widget.overflowActions.isNotEmpty,
                                      overflowExpanded: _isOverflowExpanded,
                                      onToggleOverflow: _isSubmitting
                                          ? null
                                          : () {
                                              _toggleOverflowActions();
                                            },
                                    ),
                                    const SizedBox(height: 8),
                                    _ThreadReplySheetAnimatedAccessoryPanel(
                                      visible: accessoryPanelVisible,
                                      identity: accessoryPanelIdentity,
                                      child: accessoryPanel,
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
                                              ThreadReplySheetContextCard(
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
                                                child: ThreadReplySheetInputBox(
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
                                            ThreadReplySheetContextCard(
                                              label: widget.contextLabel,
                                              preview: widget.contextPreview,
                                              collapsedMaxLines: widget
                                                  .collapsedContextPreviewLines,
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            height: effectiveInputMinHeight,
                                            child: ThreadReplySheetInputBox(
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

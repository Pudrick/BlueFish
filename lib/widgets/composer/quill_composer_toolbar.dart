import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

const quill.QuillSimpleToolbarButtonOptions _toolbarButtonOptions =
    quill.QuillSimpleToolbarButtonOptions();
const double _toolbarButtonSpacing = 4;
const Duration _toolbarAnimationDuration = Duration(milliseconds: 220);
const Curve _toolbarAnimationCurve = Curves.easeOutCubic;

class QuillComposerToolbar extends StatefulWidget {
  final quill.QuillController controller;
  final VoidCallback onInsertImagePlaceholder;
  final VoidCallback onInsertDetails;
  final VoidCallback? onInsertVideoPlaceholder;

  const QuillComposerToolbar({
    super.key,
    required this.controller,
    required this.onInsertImagePlaceholder,
    required this.onInsertDetails,
    this.onInsertVideoPlaceholder,
  });

  @override
  State<QuillComposerToolbar> createState() => _QuillComposerToolbarState();
}

class _QuillComposerToolbarState extends State<QuillComposerToolbar> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Widget _buildToggleStyleButton({
    required quill.Attribute attribute,
    required quill.QuillToolbarToggleStyleButtonOptions options,
  }) {
    return quill.QuillToolbarToggleStyleButton(
      controller: widget.controller,
      attribute: attribute,
      options: options,
      baseOptions: _toolbarButtonOptions.base,
    );
  }

  Widget _buildHistoryButton({
    required bool isUndo,
    required quill.QuillToolbarHistoryButtonOptions options,
  }) {
    return quill.QuillToolbarHistoryButton(
      controller: widget.controller,
      isUndo: isUndo,
      options: options,
      baseOptions: _toolbarButtonOptions.base,
    );
  }

  Widget _buildIndentButton({
    required bool isIncrease,
    required quill.QuillToolbarIndentButtonOptions options,
  }) {
    return quill.QuillToolbarIndentButton(
      controller: widget.controller,
      isIncrease: isIncrease,
      options: options,
      baseOptions: _toolbarButtonOptions.base,
    );
  }

  Widget _buildCustomActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
  }) {
    return quill.QuillToolbarCustomButton(
      controller: widget.controller,
      options: quill.QuillToolbarCustomButtonOptions(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 18),
      ),
      baseOptions: _toolbarButtonOptions.base,
    );
  }

  Widget _buildPrimaryFormattingStrip() {
    return Wrap(
      spacing: _toolbarButtonSpacing,
      runSpacing: _toolbarButtonSpacing,
      children: [
        _buildToggleStyleButton(
          attribute: quill.Attribute.bold,
          options: _toolbarButtonOptions.bold,
        ),
        _buildToggleStyleButton(
          attribute: quill.Attribute.italic,
          options: _toolbarButtonOptions.italic,
        ),
        quill.QuillToolbarSelectHeaderStyleButtons(
          controller: widget.controller,
          options: const quill.QuillToolbarSelectHeaderStyleButtonsOptions(
            attributes: [quill.Attribute.h1, quill.Attribute.h2],
          ),
          baseOptions: _toolbarButtonOptions.base,
        ),
        _buildToggleStyleButton(
          attribute: quill.Attribute.underline,
          options: _toolbarButtonOptions.underLine,
        ),
        _buildToggleStyleButton(
          attribute: quill.Attribute.strikeThrough,
          options: _toolbarButtonOptions.strikeThrough,
        ),
        _buildToggleStyleButton(
          attribute: quill.Attribute.ol,
          options: _toolbarButtonOptions.listNumbers,
        ),
        _buildToggleStyleButton(
          attribute: quill.Attribute.leftAlignment,
          options: const quill.QuillToolbarToggleStyleButtonOptions(),
        ),
        _buildToggleStyleButton(
          attribute: quill.Attribute.centerAlignment,
          options: const quill.QuillToolbarToggleStyleButtonOptions(),
        ),
        _buildToggleStyleButton(
          attribute: quill.Attribute.rightAlignment,
          options: const quill.QuillToolbarToggleStyleButtonOptions(),
        ),
        quill.QuillToolbarColorButton(
          controller: widget.controller,
          isBackground: false,
          options: _toolbarButtonOptions.color,
          baseOptions: _toolbarButtonOptions.base,
        ),
        quill.QuillToolbarColorButton(
          controller: widget.controller,
          isBackground: true,
          options: _toolbarButtonOptions.backgroundColor,
          baseOptions: _toolbarButtonOptions.base,
        ),
        _buildCustomActionButton(
          onPressed: widget.onInsertImagePlaceholder,
          icon: Icons.image_outlined,
          tooltip: '图片',
        ),
        quill.QuillToolbarLinkStyleButton(
          controller: widget.controller,
          options: _toolbarButtonOptions.linkStyle,
          baseOptions: _toolbarButtonOptions.base,
        ),
        if (widget.onInsertVideoPlaceholder != null)
          _buildCustomActionButton(
            onPressed: widget.onInsertVideoPlaceholder!,
            icon: Icons.smart_display_outlined,
            tooltip: '视频',
          ),
        _buildHistoryButton(
          isUndo: true,
          options: _toolbarButtonOptions.undoHistory,
        ),
        _buildHistoryButton(
          isUndo: false,
          options: _toolbarButtonOptions.redoHistory,
        ),
      ],
    );
  }

  Widget _buildExpandedFormattingPanel() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Wrap(
        spacing: _toolbarButtonSpacing,
        runSpacing: _toolbarButtonSpacing,
        children: [
          _buildToggleStyleButton(
            attribute: quill.Attribute.inlineCode,
            options: _toolbarButtonOptions.inlineCode,
          ),
          quill.QuillToolbarClearFormatButton(
            controller: widget.controller,
            options: _toolbarButtonOptions.clearFormat,
            baseOptions: _toolbarButtonOptions.base,
          ),
          _buildToggleStyleButton(
            attribute: quill.Attribute.ul,
            options: _toolbarButtonOptions.listBullets,
          ),
          _buildToggleStyleButton(
            attribute: quill.Attribute.blockQuote,
            options: _toolbarButtonOptions.quote,
          ),
          _buildToggleStyleButton(
            attribute: quill.Attribute.codeBlock,
            options: _toolbarButtonOptions.codeBlock,
          ),
          _buildIndentButton(
            isIncrease: true,
            options: _toolbarButtonOptions.indentIncrease,
          ),
          _buildIndentButton(
            isIncrease: false,
            options: _toolbarButtonOptions.indentDecrease,
          ),
          _buildCustomActionButton(
            onPressed: widget.onInsertDetails,
            icon: Icons.unfold_more_rounded,
            tooltip: '折叠说明',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '编辑工具',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: _toggleExpanded,
                icon: AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: _toolbarAnimationDuration,
                  curve: _toolbarAnimationCurve,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                  ),
                ),
                label: AnimatedSwitcher(
                  duration: _toolbarAnimationDuration,
                  switchInCurve: _toolbarAnimationCurve,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    _isExpanded ? '收起非兼容格式' : '展开非兼容格式',
                    key: ValueKey<bool>(_isExpanded),
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildPrimaryFormattingStrip(),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildExpandedFormattingPanel(),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: _toolbarAnimationDuration,
            firstCurve: _toolbarAnimationCurve,
            secondCurve: _toolbarAnimationCurve,
            sizeCurve: _toolbarAnimationCurve,
            alignment: Alignment.topLeft,
          ),
        ],
      ),
    );
  }
}

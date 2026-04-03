import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

const quill.QuillSimpleToolbarButtonOptions _toolbarButtonOptions =
    quill.QuillSimpleToolbarButtonOptions();
const double _toolbarButtonSpacing = 4;

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

  Widget _buildPrimaryFormattingStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildToggleStyleButton(
            attribute: quill.Attribute.bold,
            options: _toolbarButtonOptions.bold,
          ),
          const SizedBox(width: _toolbarButtonSpacing),
          _buildToggleStyleButton(
            attribute: quill.Attribute.italic,
            options: _toolbarButtonOptions.italic,
          ),
          const SizedBox(width: _toolbarButtonSpacing),
          _buildToggleStyleButton(
            attribute: quill.Attribute.underline,
            options: _toolbarButtonOptions.underLine,
          ),
          const SizedBox(width: _toolbarButtonSpacing),
          _buildToggleStyleButton(
            attribute: quill.Attribute.strikeThrough,
            options: _toolbarButtonOptions.strikeThrough,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedFormattingPanel() {
    return Wrap(
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
          attribute: quill.Attribute.ol,
          options: _toolbarButtonOptions.listNumbers,
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
        quill.QuillToolbarLinkStyleButton(
          controller: widget.controller,
          options: _toolbarButtonOptions.linkStyle,
          baseOptions: _toolbarButtonOptions.base,
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
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(_isExpanded ? '收起排版' : '更多排版'),
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: widget.onInsertImagePlaceholder,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('图片占位'),
              ),
              FilledButton.tonalIcon(
                onPressed: widget.onInsertDetails,
                icon: const Icon(Icons.unfold_more_rounded, size: 18),
                label: const Text('折叠说明'),
              ),
              if (widget.onInsertVideoPlaceholder != null)
                FilledButton.tonalIcon(
                  onPressed: widget.onInsertVideoPlaceholder,
                  icon: const Icon(Icons.smart_display_outlined, size: 18),
                  label: const Text('视频'),
                ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            _buildExpandedFormattingPanel(),
          ],
        ],
      ),
    );
  }
}

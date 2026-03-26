import 'package:flutter/material.dart';

class ThreadReplySheetInputBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final double cornerRadius;
  final bool elevated;

  const ThreadReplySheetInputBox({
    super.key,
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

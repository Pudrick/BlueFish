import 'package:flutter/material.dart';

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

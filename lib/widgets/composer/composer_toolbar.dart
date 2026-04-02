import 'package:flutter/material.dart';

class ComposerToolbar extends StatelessWidget {
  final VoidCallback? onAddParagraph;
  final VoidCallback? onAddDetails;
  final VoidCallback? onAddImage;
  final VoidCallback? onAddVideo;

  const ComposerToolbar({
    super.key,
    this.onAddParagraph,
    this.onAddDetails,
    this.onAddImage,
    this.onAddVideo,
  });

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
          Text(
            '工具栏',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onAddParagraph != null)
                _ToolbarActionButton(
                  icon: Icons.notes_rounded,
                  label: '段落',
                  onPressed: onAddParagraph!,
                ),
              if (onAddDetails != null)
                _ToolbarActionButton(
                  icon: Icons.unfold_more_rounded,
                  label: '详情块',
                  onPressed: onAddDetails!,
                ),
              if (onAddImage != null)
                _ToolbarActionButton(
                  icon: Icons.image_outlined,
                  label: '图片',
                  onPressed: onAddImage!,
                ),
              if (onAddVideo != null)
                _ToolbarActionButton(
                  icon: Icons.smart_display_outlined,
                  label: '视频',
                  onPressed: onAddVideo!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolbarActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

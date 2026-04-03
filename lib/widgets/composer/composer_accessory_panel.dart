import 'package:flutter/material.dart';

import '../../models/composer/composer_attachment.dart';

class ComposerAccessoryPanel extends StatelessWidget {
  final String title;
  final String description;
  final List<ComposerAttachment> attachments;
  final ValueChanged<String>? onRemoveAttachment;

  const ComposerAccessoryPanel({
    super.key,
    required this.title,
    required this.description,
    required this.attachments,
    this.onRemoveAttachment,
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
            title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final attachment in attachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AttachmentTile(
                  attachment: attachment,
                  onRemove: onRemoveAttachment == null
                      ? null
                      : () => onRemoveAttachment!(attachment.id),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final ComposerAttachment attachment;
  final VoidCallback? onRemove;

  const _AttachmentTile({required this.attachment, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusLabel = switch (attachment.uploadState) {
      ComposerUploadState.pending => '待处理',
      ComposerUploadState.uploading =>
        '上传中 ${(attachment.progress * 100).round()}%',
      ComposerUploadState.uploaded => '已就绪',
      ComposerUploadState.failed => '失败',
    };
    final secondaryLabel = switch (attachment.type) {
      ComposerAttachmentType.image =>
        attachment.localPath?.trim().isNotEmpty == true
            ? attachment.localPath!.trim()
            : null,
      ComposerAttachmentType.video => null,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              attachment.type == ComposerAttachmentType.video
                  ? Icons.smart_display_outlined
                  : Icons.image_outlined,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (secondaryLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              tooltip: '移除',
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

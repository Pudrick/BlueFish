import 'package:bluefish/models/private_message/private_message_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

import 'private_message_detail_attachment.dart';
import 'private_message_detail_header.dart';
import 'private_message_detail_utils.dart';

class PrivateMessageBubble extends StatelessWidget {
  final SinglePrivateMessage message;
  final int? loginPuid;

  const PrivateMessageBubble({
    super.key,
    required this.message,
    required this.loginPuid,
  });

  bool get _isMine => loginPuid != null && message.puid == loginPuid;

  Future<void> _copyMessage(BuildContext context) async {
    final plainText = buildPrivateMessageCopyableText(message);
    if (plainText.isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: plainText));
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('已复制消息'), duration: Duration(seconds: 1)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = _isMine
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final foregroundColor = _isMine
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: _isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isMine) ...[
            PrivateMessageConversationAvatar(avatarUrl: message.avatarUrlStr),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: _isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'yyyy-MM-dd HH:mm:ss',
                          ).format(message.createTime),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          onPressed: () => _copyMessage(context),
                          tooltip: '复制消息',
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          iconSize: 16,
                          color: colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.content_copy_outlined),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(_isMine ? 20 : 8),
                      bottomRight: Radius.circular(_isMine ? 8 : 20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: SelectionArea(
                        child: PrivateMessageBody(
                          message: message,
                          textColor: foregroundColor,
                          attachmentTone: _isMine
                              ? PrivateMessageCardAttachmentTone.mine
                              : PrivateMessageCardAttachmentTone.other,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isMine) ...[
            const SizedBox(width: 8),
            PrivateMessageConversationAvatar(avatarUrl: message.avatarUrlStr),
          ],
        ],
      ),
    );
  }
}

class PrivateMessageBody extends StatelessWidget {
  final SinglePrivateMessage message;
  final Color textColor;
  final PrivateMessageCardAttachmentTone attachmentTone;

  const PrivateMessageBody({
    super.key,
    required this.message,
    required this.textColor,
    required this.attachmentTone,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasContent = message.content.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasContent)
          HtmlWidget(
            message.content,
            textStyle: textTheme.bodyLarge?.copyWith(
              color: textColor,
              height: 1.5,
            ),
          ),
        if (hasContent && message.cardPm != null) const SizedBox(height: 12),
        if (message.cardPm != null)
          PrivateMessageCardAttachment(
            cardPm: message.cardPm!,
            messageId: message.pmid,
            tone: attachmentTone,
          ),
      ],
    );
  }
}

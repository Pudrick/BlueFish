import 'package:bluefish/models/private_message_detail.dart';
import 'package:html/parser.dart' as html_parser;

String buildPrivateMessageCopyableText(SinglePrivateMessage message) {
  final segments = <String>[];

  final plainContent = privateMessageHtmlToPlainText(message.content);
  if (plainContent.isNotEmpty) {
    segments.add(plainContent);
  }

  final cardPm = message.cardPm;
  if (cardPm != null) {
    final title = cardPm.title.trim();
    if (title.isNotEmpty) {
      segments.add(title);
    }

    final intro = cardPm.intro.trim();
    if (intro.isNotEmpty) {
      segments.add(intro);
    }

    final redirectText = cardPm.redirection.text.trim();
    if (redirectText.isNotEmpty) {
      segments.add(redirectText);
    }

    final redirectUrl = cardPm.redirection.redirUrl.toString().trim();
    if (redirectUrl.isNotEmpty) {
      segments.add(redirectUrl);
    }
  }

  return segments.join('\n\n').trim();
}

String privateMessageHtmlToPlainText(String html) {
  if (html.trim().isEmpty) {
    return '';
  }

  final normalizedHtml = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n');

  final plainText = html_parser.parseFragment(normalizedHtml).text ?? '';
  return plainText
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

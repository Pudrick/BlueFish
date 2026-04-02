import 'package:flutter/foundation.dart';

enum ComposerTextStyle { bold, italic, underline, code }

String createComposerId(String prefix) {
  _composerIdCounter += 1;
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_composerIdCounter';
}

int _composerIdCounter = 0;

@immutable
sealed class ComposerInlineNode {
  const ComposerInlineNode();
}

@immutable
class ComposerTextNode extends ComposerInlineNode {
  final String text;
  final Set<ComposerTextStyle> styles;

  const ComposerTextNode(
    this.text, {
    this.styles = const <ComposerTextStyle>{},
  });

  ComposerTextNode copyWith({String? text, Set<ComposerTextStyle>? styles}) {
    return ComposerTextNode(text ?? this.text, styles: styles ?? this.styles);
  }
}

@immutable
class ComposerLinkNode extends ComposerInlineNode {
  final String text;
  final String href;

  const ComposerLinkNode({required this.text, required this.href});

  ComposerLinkNode copyWith({String? text, String? href}) {
    return ComposerLinkNode(text: text ?? this.text, href: href ?? this.href);
  }
}

@immutable
sealed class ComposerBlockNode {
  final String id;

  const ComposerBlockNode({required this.id});
}

@immutable
class ComposerParagraphBlock extends ComposerBlockNode {
  final List<ComposerInlineNode> children;

  const ComposerParagraphBlock({
    required super.id,
    this.children = const <ComposerInlineNode>[],
  });

  factory ComposerParagraphBlock.empty() =>
      ComposerParagraphBlock(id: createComposerId('paragraph'));

  String get plainText => serializeComposerInlineText(children);

  ComposerParagraphBlock copyWith({List<ComposerInlineNode>? children}) {
    return ComposerParagraphBlock(id: id, children: children ?? this.children);
  }
}

@immutable
class ComposerDetailsBlock extends ComposerBlockNode {
  final List<ComposerInlineNode> summary;
  final List<ComposerBlockNode> children;
  final bool initiallyOpen;

  const ComposerDetailsBlock({
    required super.id,
    this.summary = const <ComposerInlineNode>[],
    this.children = const <ComposerBlockNode>[],
    this.initiallyOpen = false,
  });

  factory ComposerDetailsBlock.empty() => ComposerDetailsBlock(
    id: createComposerId('details'),
    summary: const <ComposerInlineNode>[ComposerTextNode('补充说明')],
    children: <ComposerBlockNode>[ComposerParagraphBlock.empty()],
  );

  String get summaryText => serializeComposerInlineText(summary);

  String get bodyText {
    return children
        .whereType<ComposerParagraphBlock>()
        .map((block) => block.plainText)
        .join('\n\n')
        .trim();
  }

  ComposerDetailsBlock copyWith({
    List<ComposerInlineNode>? summary,
    List<ComposerBlockNode>? children,
    bool? initiallyOpen,
  }) {
    return ComposerDetailsBlock(
      id: id,
      summary: summary ?? this.summary,
      children: children ?? this.children,
      initiallyOpen: initiallyOpen ?? this.initiallyOpen,
    );
  }
}

@immutable
class ComposerImageBlock extends ComposerBlockNode {
  final String attachmentId;
  final String? sourceUrl;
  final String? caption;

  const ComposerImageBlock({
    required super.id,
    required this.attachmentId,
    this.sourceUrl,
    this.caption,
  });

  factory ComposerImageBlock.placeholder({
    required String attachmentId,
    String? sourceUrl,
  }) {
    return ComposerImageBlock(
      id: createComposerId('image'),
      attachmentId: attachmentId,
      sourceUrl: sourceUrl,
    );
  }

  ComposerImageBlock copyWith({
    String? attachmentId,
    String? sourceUrl,
    String? caption,
  }) {
    return ComposerImageBlock(
      id: id,
      attachmentId: attachmentId ?? this.attachmentId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      caption: caption ?? this.caption,
    );
  }
}

@immutable
class ComposerDocument {
  final List<ComposerBlockNode> blocks;

  const ComposerDocument({this.blocks = const <ComposerBlockNode>[]});

  factory ComposerDocument.withSingleParagraph() => ComposerDocument(
    blocks: <ComposerBlockNode>[ComposerParagraphBlock.empty()],
  );

  bool get isEmpty {
    if (blocks.isEmpty) {
      return true;
    }

    for (final block in blocks) {
      if (block is ComposerParagraphBlock) {
        if (block.plainText.trim().isNotEmpty) {
          return false;
        }
        continue;
      }

      if (block is ComposerDetailsBlock) {
        if (block.summaryText.trim().isNotEmpty || block.bodyText.isNotEmpty) {
          return false;
        }
        continue;
      }

      if (block is ComposerImageBlock) {
        return false;
      }
    }

    return true;
  }

  ComposerDocument copyWith({List<ComposerBlockNode>? blocks}) {
    return ComposerDocument(blocks: blocks ?? this.blocks);
  }

  ComposerDocument append(ComposerBlockNode block) {
    return copyWith(blocks: <ComposerBlockNode>[...blocks, block]);
  }

  ComposerDocument replaceBlock(ComposerBlockNode nextBlock) {
    return copyWith(
      blocks: blocks
          .map((block) => block.id == nextBlock.id ? nextBlock : block)
          .toList(growable: false),
    );
  }

  ComposerDocument removeBlock(String blockId) {
    return copyWith(
      blocks: blocks
          .where((block) => block.id != blockId)
          .toList(growable: false),
    );
  }

  T? findBlock<T extends ComposerBlockNode>(String blockId) {
    for (final block in blocks) {
      if (block.id == blockId && block is T) {
        return block;
      }
    }
    return null;
  }

  String toHtml() {
    return blocks.map((block) => serializeComposerBlock(block)).join();
  }
}

String serializeComposerInlineText(List<ComposerInlineNode> children) {
  final buffer = StringBuffer();
  for (final child in children) {
    if (child is ComposerTextNode) {
      buffer.write(child.text);
      continue;
    }

    if (child is ComposerLinkNode) {
      buffer.write(child.text);
    }
  }
  return buffer.toString();
}

String serializeComposerBlock(ComposerBlockNode block) {
  switch (block) {
    case ComposerParagraphBlock():
      final content = serializeComposerInlineHtml(block.children);
      return '<p>${content.isEmpty ? '<br>' : content}</p>';
    case ComposerDetailsBlock():
      final openAttr = block.initiallyOpen ? ' open' : '';
      final summary = serializeComposerInlineHtml(block.summary);
      final body = block.children.map(serializeComposerBlock).join();
      final normalizedSummary = summary.isEmpty ? '补充说明' : summary;
      return '<details$openAttr><summary>$normalizedSummary</summary>$body</details>';
    case ComposerImageBlock():
      final source = block.sourceUrl?.trim();
      if (source == null || source.isEmpty) {
        final caption = _escapeHtml(block.caption?.trim() ?? '图片待上传');
        return '<p><strong>[$caption]</strong></p>';
      }
      final caption = block.caption?.trim();
      final captionHtml = caption == null || caption.isEmpty
          ? ''
          : '<p>${_escapeHtml(caption)}</p>';
      return '<div data-hupu-node="image"><img src="${_escapeHtml(source)}"></div>$captionHtml';
  }
}

String serializeComposerInlineHtml(List<ComposerInlineNode> children) {
  if (children.isEmpty) {
    return '';
  }

  final buffer = StringBuffer();
  for (final child in children) {
    if (child is ComposerTextNode) {
      var html = _escapeHtml(child.text);
      if (child.styles.contains(ComposerTextStyle.code)) {
        html = '<code>$html</code>';
      }
      if (child.styles.contains(ComposerTextStyle.bold)) {
        html = '<strong>$html</strong>';
      }
      if (child.styles.contains(ComposerTextStyle.italic)) {
        html = '<em>$html</em>';
      }
      if (child.styles.contains(ComposerTextStyle.underline)) {
        html = '<u>$html</u>';
      }
      buffer.write(html);
      continue;
    }

    if (child is ComposerLinkNode) {
      final text = _escapeHtml(child.text);
      final href = _escapeHtml(child.href);
      buffer.write('<a href="$href">$text</a>');
    }
  }
  return buffer.toString();
}

String _escapeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

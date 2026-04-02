import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../../models/composer/quill_embed_models.dart';

class HtmlExportService {
  const HtmlExportService();

  String exportRichText(List<Map<String, dynamic>> deltaJson) {
    if (deltaJson.isEmpty) {
      return '';
    }

    final normalizedOps = deltaJson
        .map(_normalizeOperation)
        .toList(growable: false);

    final converter = QuillDeltaToHtmlConverter(normalizedOps);
    converter.renderCustomWith = (customOp, contextOp) {
      switch (customOp.insert.type) {
        case bluefishDetailsEmbedType:
          final data = BluefishDetailsEmbedData.fromJsonString(
            customOp.insert.value.toString(),
          );
          return _renderDetails(data);
        case bluefishImagePlaceholderEmbedType:
          final data = BluefishImagePlaceholderEmbedData.fromJsonString(
            customOp.insert.value.toString(),
          );
          return _renderImagePlaceholder(data);
        default:
          return '';
      }
    };

    return converter.convert().trim();
  }

  Map<String, dynamic> _normalizeOperation(Map<String, dynamic> operation) {
    final normalized = Map<String, dynamic>.from(operation);
    final insert = normalized['insert'];
    if (insert is! Map) {
      return normalized;
    }

    final attributes = Map<String, dynamic>.from(
      normalized['attributes'] as Map? ?? const <String, dynamic>{},
    );
    final customEmbedType = insert.keys
        .cast<Object?>()
        .whereType<String>()
        .firstWhere(
          (key) =>
              key == bluefishDetailsEmbedType ||
              key == bluefishImagePlaceholderEmbedType,
          orElse: () => '',
        );
    if (customEmbedType.isEmpty) {
      return normalized;
    }

    attributes['renderAsBlock'] = true;
    normalized['attributes'] = attributes;
    return normalized;
  }

  String _renderDetails(BluefishDetailsEmbedData data) {
    final summary = _escapeHtml(
      data.summary.trim().isEmpty ? '补充说明' : data.summary.trim(),
    );
    final body = data.body.trim();
    final openAttr = data.initiallyExpanded ? ' open' : '';

    if (body.isEmpty) {
      return '<details$openAttr><summary>$summary</summary><p><br></p></details>';
    }

    final bodyHtml = body
        .split('\n')
        .map((line) => '<p>${_escapeHtml(line.trim())}</p>')
        .join();
    return '<details$openAttr><summary>$summary</summary>$bodyHtml</details>';
  }

  String _renderImagePlaceholder(BluefishImagePlaceholderEmbedData data) {
    final source = data.sourceUrl?.trim();
    final caption = data.caption?.trim();
    final captionHtml = caption == null || caption.isEmpty
        ? ''
        : '<p>${_escapeHtml(caption)}</p>';

    if (source == null || source.isEmpty) {
      final label = _escapeHtml(
        caption == null || caption.isEmpty ? data.label : caption,
      );
      return '<p><strong>[$label]</strong></p>';
    }

    return '<div data-hupu-node="image"><img src="${_escapeHtml(source)}"></div>$captionHtml';
  }

  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

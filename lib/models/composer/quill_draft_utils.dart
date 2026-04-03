import 'package:flutter/services.dart';

import 'quill_embed_models.dart';

List<Map<String, dynamic>> emptyQuillDeltaJson() {
  return const <Map<String, dynamic>>[
    <String, dynamic>{'insert': '\n'},
  ];
}

bool isQuillDeltaMeaningfullyEmpty(List<Map<String, dynamic>> deltaJson) {
  for (final operation in deltaJson) {
    final insert = operation['insert'];
    if (insert is String) {
      final normalized = insert.replaceAll('\n', '').trim();
      if (normalized.isNotEmpty) {
        return false;
      }
      continue;
    }

    if (insert is Map && insert.isNotEmpty) {
      return false;
    }
  }

  return true;
}

TextSelection collapsedSelectionBeforeBlockEmbed({
  required String plainText,
  required int embedOffset,
}) {
  final hasLeadingNewline =
      embedOffset > 0 && plainText[embedOffset - 1] == '\n';
  if (hasLeadingNewline) {
    return TextSelection.collapsed(
      offset: embedOffset - 1,
      affinity: TextAffinity.upstream,
    );
  }

  return TextSelection.collapsed(
    offset: embedOffset.clamp(0, plainText.length),
    affinity: TextAffinity.downstream,
  );
}

TextSelection collapsedSelectionAfterBlockEmbed({
  required String plainText,
  required int embedOffset,
}) {
  final embedEnd = embedOffset + 1;
  final hasTrailingNewline =
      embedEnd < plainText.length && plainText[embedEnd] == '\n';
  if (hasTrailingNewline) {
    return TextSelection.collapsed(
      offset: embedEnd + 1,
      affinity: TextAffinity.downstream,
    );
  }

  return TextSelection.collapsed(
    offset: embedEnd.clamp(0, plainText.length),
    affinity: TextAffinity.downstream,
  );
}

TextSelection? normalizedCollapsedSelectionForBlockEmbeds({
  required List<Map<String, dynamic>> deltaJson,
  required String plainText,
  required TextSelection selection,
}) {
  if (!selection.isValid || !selection.isCollapsed) {
    return null;
  }

  final selectionOffset = selection.extentOffset;
  if (selectionOffset < 0 || selectionOffset > plainText.length) {
    return null;
  }

  var offset = 0;
  for (final operation in deltaJson) {
    final insert = operation['insert'];
    if (insert is String) {
      offset += insert.length;
      continue;
    }

    if (insert is! Map) {
      continue;
    }

    final isBlockEmbed = bluefishBlockEmbedTypes.any(insert.containsKey);
    if (!isBlockEmbed) {
      offset += 1;
      continue;
    }

    final embedStart = offset;
    final embedEnd = embedStart + 1;
    final hasLeadingNewline =
        embedStart > 0 && plainText[embedStart - 1] == '\n';
    final hasTrailingNewline =
        embedEnd < plainText.length && plainText[embedEnd] == '\n';

    if (selectionOffset == embedStart && hasLeadingNewline) {
      return collapsedSelectionBeforeBlockEmbed(
        plainText: plainText,
        embedOffset: embedStart,
      );
    }

    if (selectionOffset == embedStart - 1 &&
        hasLeadingNewline &&
        selection.affinity != TextAffinity.upstream) {
      return collapsedSelectionBeforeBlockEmbed(
        plainText: plainText,
        embedOffset: embedStart,
      );
    }

    if (selectionOffset == embedEnd && hasTrailingNewline) {
      return collapsedSelectionAfterBlockEmbed(
        plainText: plainText,
        embedOffset: embedStart,
      );
    }

    if (selectionOffset == embedEnd + 1 &&
        hasTrailingNewline &&
        selection.affinity != TextAffinity.downstream) {
      return collapsedSelectionAfterBlockEmbed(
        plainText: plainText,
        embedOffset: embedStart,
      );
    }

    offset = embedEnd;
  }

  return null;
}

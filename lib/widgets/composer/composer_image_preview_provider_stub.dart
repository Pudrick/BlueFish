import 'package:flutter/widgets.dart';

ImageProvider<Object>? resolveComposerImageProvider(String source) {
  final normalized = source.trim();
  if (normalized.isEmpty) {
    return null;
  }

  return NetworkImage(normalized);
}

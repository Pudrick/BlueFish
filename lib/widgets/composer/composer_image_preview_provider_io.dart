import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object>? resolveComposerImageProvider(String source) {
  final normalized = source.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(normalized);
  final scheme = uri?.scheme.toLowerCase();
  if (scheme == 'http' ||
      scheme == 'https' ||
      scheme == 'data' ||
      scheme == 'blob') {
    return NetworkImage(normalized);
  }

  return FileImage(File(normalized));
}

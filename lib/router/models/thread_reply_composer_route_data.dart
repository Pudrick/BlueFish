import 'package:flutter/foundation.dart';

@immutable
class ThreadReplyComposerRouteData {
  static const String _contextLabelKey = 'contextLabel';
  static const String _contextPreviewKey = 'contextPreview';

  final String? contextLabel;
  final String? contextPreview;

  const ThreadReplyComposerRouteData({this.contextLabel, this.contextPreview});

  Object? toExtra() {
    final extra = <String, Object?>{};
    final trimmedContextLabel = contextLabel?.trim();
    final trimmedContextPreview = contextPreview?.trim();

    if (trimmedContextLabel != null && trimmedContextLabel.isNotEmpty) {
      extra[_contextLabelKey] = trimmedContextLabel;
    }
    if (trimmedContextPreview != null && trimmedContextPreview.isNotEmpty) {
      extra[_contextPreviewKey] = trimmedContextPreview;
    }

    if (extra.isEmpty) {
      return null;
    }
    return extra;
  }

  static ThreadReplyComposerRouteData? tryParse(Object? extra) {
    if (extra == null) {
      return const ThreadReplyComposerRouteData();
    }
    if (extra is! Map) {
      return null;
    }

    final rawContextLabel = extra[_contextLabelKey];
    final rawContextPreview = extra[_contextPreviewKey];

    if ((rawContextLabel != null && rawContextLabel is! String) ||
        (rawContextPreview != null && rawContextPreview is! String)) {
      return null;
    }

    return ThreadReplyComposerRouteData(
      contextLabel: (rawContextLabel as String?)?.trim(),
      contextPreview: (rawContextPreview as String?)?.trim(),
    );
  }
}

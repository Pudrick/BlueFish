import 'package:flutter/widgets.dart';

import 'composer_image_preview_provider_stub.dart'
    if (dart.library.io) 'composer_image_preview_provider_io.dart'
    as provider;

ImageProvider<Object>? resolveComposerImageProvider(String source) {
  return provider.resolveComposerImageProvider(source);
}

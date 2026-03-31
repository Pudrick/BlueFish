import 'dart:collection';

import 'package:bluefish/widgets/html/details/bluefish_details_build_op.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;
import 'package:flutter/widgets.dart';

class BluefishHtmlWidgetFactory extends fwfh.WidgetFactory {
  fwfh.BuildOp? _detailsBuildOp;
  final Map<String, Queue<Object>> _imageHeroTagsByUrl;

  BluefishHtmlWidgetFactory({
    Map<String, List<Object>> imageHeroTagsByUrl = const {},
  }) : _imageHeroTagsByUrl = imageHeroTagsByUrl.map(
         (url, tags) => MapEntry(url, Queue<Object>.of(tags)),
       );

  @override
  void parse(fwfh.BuildTree meta) {
    if (meta.element.localName == BluefishDetailsBuildOp.tagName) {
      meta.register(_detailsBuildOp ??= BluefishDetailsBuildOp(this).buildOp);
      return;
    }

    super.parse(meta);
  }

  @override
  Widget? onLoadingBuilder(
    BuildContext context,
    fwfh.BuildTree tree, [
    double? loadingProgress,
    dynamic data,
  ]) {
    final isImage = data is fwfh.ImageSource || tree.element.localName == 'img';
    if (isImage) {
      // Avoid centered loading placeholder to keep image position stable.
      return const SizedBox.shrink();
    }

    return super.onLoadingBuilder(context, tree, loadingProgress, data);
  }

  @override
  Widget? buildImageWidget(fwfh.BuildTree meta, fwfh.ImageSource src) {
    final built = super.buildImageWidget(meta, src);
    if (built == null) {
      return null;
    }

    final normalizedUrl = _normalizeImageUrl(src.url);
    final heroTagQueue = _imageHeroTagsByUrl[normalizedUrl];
    final heroTag = heroTagQueue != null && heroTagQueue.isNotEmpty
        ? heroTagQueue.removeFirst()
        : null;
    if (heroTag == null) {
      return built;
    }

    return Hero(tag: heroTag, child: built);
  }

  String _normalizeImageUrl(String rawUrl) {
    if (rawUrl.startsWith('//')) {
      return 'https:$rawUrl';
    }

    return rawUrl;
  }
}

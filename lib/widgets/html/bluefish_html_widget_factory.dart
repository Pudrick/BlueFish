import 'package:bluefish/widgets/html/details/bluefish_details_build_op.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;
import 'package:flutter/widgets.dart';

const bluefishGalleryIndexAttribute = 'data-bluefish-gallery-index';
const bluefishHeroTagAttribute = 'data-bluefish-hero-tag';

typedef BluefishHtmlImageTapCallback =
    void Function(BuildContext context, int galleryIndex);

class BluefishHtmlWidgetFactory extends fwfh.WidgetFactory {
  fwfh.BuildOp? _detailsBuildOp;
  final BluefishHtmlImageTapCallback? _onTapImageAtIndex;

  BluefishHtmlWidgetFactory({BluefishHtmlImageTapCallback? onTapImageAtIndex})
    : _onTapImageAtIndex = onTapImageAtIndex;

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
  Widget? buildImage(fwfh.BuildTree tree, fwfh.ImageMetadata data) {
    final src = data.sources.isNotEmpty ? data.sources.first : null;
    if (src == null) {
      return null;
    }

    final builtImage = super.buildImageWidget(tree, src);
    if (builtImage == null) {
      return null;
    }
    Widget built = builtImage;

    final heroTag = tree.element.attributes[bluefishHeroTagAttribute];
    if (heroTag != null && heroTag.isNotEmpty) {
      built = Hero(tag: heroTag, child: built);
    }

    final title = data.title;
    if (title != null) {
      built = buildTooltip(tree, built, title) ?? built;
    }

    final height = src.height;
    final width = src.width;
    if (height != null && height > 0 && width != null && width > 0) {
      built = buildAspectRatio(tree, built, width / height) ?? built;
    }

    final galleryIndex = int.tryParse(
      tree.element.attributes[bluefishGalleryIndexAttribute] ?? '',
    );
    final onTapImageAtIndex = _onTapImageAtIndex;
    if (galleryIndex == null || onTapImageAtIndex == null) {
      return built;
    }

    final child = built;
    return Builder(
      builder: (context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onTapImageAtIndex(context, galleryIndex),
          child: child,
        ),
      ),
    );
  }
}

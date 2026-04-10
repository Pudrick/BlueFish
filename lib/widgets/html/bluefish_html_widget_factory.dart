import 'dart:math' as math;

import 'package:bluefish/models/app_settings.dart';
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
  final bool _enableImageShrink;
  final double _imageShrinkTriggerMaxEdgeDp;
  final double _imageShrinkTargetMaxEdgeDp;

  BluefishHtmlWidgetFactory({
    BluefishHtmlImageTapCallback? onTapImageAtIndex,
    bool enableImageShrink = true,
    double? imageShrinkTriggerMaxEdgeDp,
    double? imageShrinkTargetMaxEdgeDp,
  }) : _onTapImageAtIndex = onTapImageAtIndex,
       _enableImageShrink = enableImageShrink,
       _imageShrinkTriggerMaxEdgeDp = _resolveImageShrinkTriggerMaxEdgeDp(
         imageShrinkTriggerMaxEdgeDp,
       ),
       _imageShrinkTargetMaxEdgeDp = _resolveImageShrinkTargetMaxEdgeDp(
         imageShrinkTargetMaxEdgeDp,
         imageShrinkTriggerMaxEdgeDp,
       );

  static double _resolveImageShrinkTriggerMaxEdgeDp(double? rawValue) {
    final resolvedValue =
        rawValue ?? AppSettings.defaultImageShrinkTriggerMaxEdgeDp;
    if (!resolvedValue.isFinite) {
      return AppSettings.defaultImageShrinkTriggerMaxEdgeDp;
    }

    return resolvedValue.clamp(
      AppSettings.minImageShrinkTriggerMaxEdgeDp,
      AppSettings.maxImageShrinkTriggerMaxEdgeDp,
    );
  }

  static double _resolveImageShrinkTargetMaxEdgeDp(
    double? rawTarget,
    double? rawTrigger,
  ) {
    final resolvedTrigger = _resolveImageShrinkTriggerMaxEdgeDp(rawTrigger);
    final resolvedTarget =
        rawTarget ?? AppSettings.defaultImageShrinkTargetMaxEdgeDp;
    if (!resolvedTarget.isFinite) {
      return AppSettings.defaultImageShrinkTargetMaxEdgeDp;
    }

    return resolvedTarget.clamp(
      AppSettings.minImageShrinkTargetMaxEdgeDp,
      math.min(AppSettings.maxImageShrinkTargetMaxEdgeDp, resolvedTrigger),
    );
  }

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

    final intrinsicHeight = src.height;
    final intrinsicWidth = src.width;
    final hasIntrinsicSize =
        intrinsicHeight != null &&
        intrinsicHeight > 0 &&
        intrinsicHeight.isFinite &&
        intrinsicWidth != null &&
        intrinsicWidth > 0 &&
        intrinsicWidth.isFinite;
    if (hasIntrinsicSize) {
      built =
          buildAspectRatio(tree, built, intrinsicWidth / intrinsicHeight) ??
          built;
    }

    final galleryIndex = int.tryParse(
      tree.element.attributes[bluefishGalleryIndexAttribute] ?? '',
    );
    final onTapImageAtIndex = _onTapImageAtIndex;
    if (!hasIntrinsicSize || !_enableImageShrink) {
      return _wrapWithImageTap(
        child: built,
        galleryIndex: galleryIndex,
        onTapImageAtIndex: onTapImageAtIndex,
      );
    }

    return _ShrinkableHtmlImage(
      intrinsicWidth: intrinsicWidth,
      intrinsicHeight: intrinsicHeight,
      shrinkTriggerMaxEdgeDp: _imageShrinkTriggerMaxEdgeDp,
      shrinkTargetMaxEdgeDp: _imageShrinkTargetMaxEdgeDp,
      galleryIndex: galleryIndex,
      onTapImageAtIndex: onTapImageAtIndex,
      child: built,
    );
  }

  Widget _wrapWithImageTap({
    required Widget child,
    required int? galleryIndex,
    required BluefishHtmlImageTapCallback? onTapImageAtIndex,
  }) {
    if (galleryIndex == null || onTapImageAtIndex == null) {
      return child;
    }

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

class _ShrinkableHtmlImage extends StatefulWidget {
  final Widget child;
  final double intrinsicWidth;
  final double intrinsicHeight;
  final double shrinkTriggerMaxEdgeDp;
  final double shrinkTargetMaxEdgeDp;
  final int? galleryIndex;
  final BluefishHtmlImageTapCallback? onTapImageAtIndex;

  const _ShrinkableHtmlImage({
    required this.child,
    required this.intrinsicWidth,
    required this.intrinsicHeight,
    required this.shrinkTriggerMaxEdgeDp,
    required this.shrinkTargetMaxEdgeDp,
    required this.galleryIndex,
    required this.onTapImageAtIndex,
  });

  @override
  State<_ShrinkableHtmlImage> createState() => _ShrinkableHtmlImageState();
}

class _ShrinkableHtmlImageState extends State<_ShrinkableHtmlImage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasGalleryTap =
        widget.galleryIndex != null && widget.onTapImageAtIndex != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQueryWidth = MediaQuery.maybeOf(context)?.size.width;
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : mediaQueryWidth;
        final effectiveAvailableWidth =
            availableWidth != null &&
                availableWidth.isFinite &&
                availableWidth > 0
            ? availableWidth
            : widget.intrinsicWidth;

        final widthScale = effectiveAvailableWidth < widget.intrinsicWidth
            ? effectiveAvailableWidth / widget.intrinsicWidth
            : 1.0;
        final renderedWidth = widget.intrinsicWidth * widthScale;
        final renderedHeight = widget.intrinsicHeight * widthScale;
        final renderedLongestEdge = math.max(renderedWidth, renderedHeight);

        final shouldShrink =
            !_expanded && renderedLongestEdge > widget.shrinkTriggerMaxEdgeDp;
        final canShrinkToEdge = math.min(
          widget.shrinkTargetMaxEdgeDp,
          renderedLongestEdge,
        );
        final shrinkScale = shouldShrink && renderedLongestEdge > 0
            ? canShrinkToEdge / renderedLongestEdge
            : 1.0;
        final shrinkWidth = renderedWidth * shrinkScale;
        final shrinkHeight = renderedHeight * shrinkScale;

        Widget display = widget.child;
        if (shouldShrink) {
          display = Align(
            alignment: Alignment.centerLeft,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: shrinkWidth,
                  height: shrinkHeight,
                  child: display,
                ),
                const Positioned(top: 8, right: 8, child: _ImageShrinkBadge()),
              ],
            ),
          );
        }

        final canHandleTap = shouldShrink || hasGalleryTap;
        if (!canHandleTap) {
          return display;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (shouldShrink) {
                setState(() {
                  _expanded = true;
                });
                return;
              }

              final galleryIndex = widget.galleryIndex;
              final onTapImageAtIndex = widget.onTapImageAtIndex;
              if (galleryIndex == null || onTapImageAtIndex == null) {
                return;
              }

              onTapImageAtIndex(context, galleryIndex);
            },
            child: display,
          ),
        );
      },
    );
  }
}

class _ImageShrinkBadge extends StatelessWidget {
  const _ImageShrinkBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '已缩小',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

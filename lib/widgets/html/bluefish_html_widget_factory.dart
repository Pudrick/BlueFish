import 'dart:math' as math;

import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/widgets/html/details/bluefish_details_build_op.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' as fwfh;

const bluefishGalleryIndexAttribute = 'data-bluefish-gallery-index';
const bluefishHeroTagAttribute = 'data-bluefish-hero-tag';

typedef BluefishHtmlImageTapCallback =
    void Function(BuildContext context, int galleryIndex);

class BluefishHtmlWidgetFactory extends fwfh.WidgetFactory {
  static final RegExp _imageSizeInUrlPattern = RegExp(
    r'[_/](?:o_)?w_(\d+)_h_(\d+)(?:_|$)',
    caseSensitive: false,
  );

  fwfh.BuildOp? _detailsBuildOp;
  final BluefishHtmlImageTapCallback? _onTapImageAtIndex;
  final bool _enableImageShrink;
  final double _imageShrinkTriggerWidthFactor;
  final double _imageShrinkTargetWidthFactor;

  BluefishHtmlWidgetFactory({
    BluefishHtmlImageTapCallback? onTapImageAtIndex,
    bool enableImageShrink = true,
    double? imageShrinkTriggerWidthFactor,
    double? imageShrinkTargetWidthFactor,
  }) : _onTapImageAtIndex = onTapImageAtIndex,
       _enableImageShrink = enableImageShrink,
       _imageShrinkTriggerWidthFactor =
           AppSettings.normalizeImageShrinkTriggerWidthFactor(
             imageShrinkTriggerWidthFactor ??
                 AppSettings.defaultImageShrinkTriggerWidthFactor,
           ),
       _imageShrinkTargetWidthFactor =
           AppSettings.normalizeImageShrinkTargetWidthFactor(
             imageShrinkTargetWidthFactor ??
                 AppSettings.defaultImageShrinkTargetWidthFactor,
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

    final intrinsicSize = _intrinsicSizeFromSource(src);
    if (intrinsicSize != null) {
      built =
          buildAspectRatio(
            tree,
            built,
            intrinsicSize.width / intrinsicSize.height,
          ) ??
          built;
    }

    final galleryIndex = int.tryParse(
      tree.element.attributes[bluefishGalleryIndexAttribute] ?? '',
    );
    final onTapImageAtIndex = _onTapImageAtIndex;
    if (!_enableImageShrink) {
      return _wrapWithImageTap(
        child: built,
        galleryIndex: galleryIndex,
        onTapImageAtIndex: onTapImageAtIndex,
      );
    }

    final imageProvider = _imageProviderForSource(src.url);
    if (imageProvider == null) {
      return _wrapWithImageTap(
        child: built,
        galleryIndex: galleryIndex,
        onTapImageAtIndex: onTapImageAtIndex,
      );
    }

    return _ShrinkableHtmlImage(
      imageProvider: imageProvider,
      fallbackIntrinsicSize: intrinsicSize ?? _intrinsicSizeFromUrl(src.url),
      shrinkTriggerWidthFactor: _imageShrinkTriggerWidthFactor,
      shrinkTargetWidthFactor: _imageShrinkTargetWidthFactor,
      galleryIndex: galleryIndex,
      onTapImageAtIndex: onTapImageAtIndex,
      child: built,
    );
  }

  ImageProvider<Object>? _imageProviderForSource(String url) {
    if (url.startsWith('asset:')) {
      return imageProviderFromAsset(url);
    }
    if (url.startsWith('data:image/')) {
      return imageProviderFromDataUri(url);
    }
    if (url.startsWith('file:')) {
      return imageProviderFromFileUri(url);
    }

    return imageProviderFromNetwork(url);
  }

  Size? _intrinsicSizeFromSource(fwfh.ImageSource src) {
    final width = src.width;
    final height = src.height;
    if (!_isPositiveFinite(width) || !_isPositiveFinite(height)) {
      return null;
    }

    return Size(width!, height!);
  }

  Size? _intrinsicSizeFromUrl(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) {
      return null;
    }

    final match = _imageSizeInUrlPattern.firstMatch(url);
    if (match == null) {
      return null;
    }

    final width = double.tryParse(match.group(1) ?? '');
    final height = double.tryParse(match.group(2) ?? '');
    if (!_isPositiveFinite(width) || !_isPositiveFinite(height)) {
      return null;
    }

    return Size(width!, height!);
  }

  bool _isPositiveFinite(double? value) {
    return value != null && value.isFinite && value > 0;
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
  final ImageProvider<Object> imageProvider;
  final Size? fallbackIntrinsicSize;
  final double shrinkTriggerWidthFactor;
  final double shrinkTargetWidthFactor;
  final int? galleryIndex;
  final BluefishHtmlImageTapCallback? onTapImageAtIndex;

  const _ShrinkableHtmlImage({
    required this.child,
    required this.imageProvider,
    required this.fallbackIntrinsicSize,
    required this.shrinkTriggerWidthFactor,
    required this.shrinkTargetWidthFactor,
    required this.galleryIndex,
    required this.onTapImageAtIndex,
  });

  @override
  State<_ShrinkableHtmlImage> createState() => _ShrinkableHtmlImageState();
}

class _ShrinkableHtmlImageState extends State<_ShrinkableHtmlImage> {
  bool _expanded = false;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _resolvedIntrinsicSize;

  @override
  void initState() {
    super.initState();
    _resolvedIntrinsicSize = widget.fallbackIntrinsicSize;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToImageStream();
  }

  @override
  void didUpdateWidget(covariant _ShrinkableHtmlImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.fallbackIntrinsicSize != oldWidget.fallbackIntrinsicSize &&
        _resolvedIntrinsicSize == null) {
      _resolvedIntrinsicSize = widget.fallbackIntrinsicSize;
    }

    if (widget.imageProvider != oldWidget.imageProvider) {
      _subscribeToImageStream();
    }
  }

  @override
  void dispose() {
    final imageStreamListener = _imageStreamListener;
    if (imageStreamListener != null) {
      _imageStream?.removeListener(imageStreamListener);
    }
    super.dispose();
  }

  void _subscribeToImageStream() {
    _imageStreamListener ??= ImageStreamListener((imageInfo, _) {
      final scale = imageInfo.scale > 0 ? imageInfo.scale : 1.0;
      final resolvedSize = Size(
        imageInfo.image.width / scale,
        imageInfo.image.height / scale,
      );
      if (!mounted || resolvedSize == _resolvedIntrinsicSize) {
        return;
      }

      setState(() {
        _resolvedIntrinsicSize = resolvedSize;
      });
    }, onError: (_, __) {});

    final nextStream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    if (_imageStream?.key == nextStream.key) {
      return;
    }

    _imageStream?.removeListener(_imageStreamListener!);
    _imageStream = nextStream;
    nextStream.addListener(_imageStreamListener!);
  }

  @override
  Widget build(BuildContext context) {
    final hasGalleryTap =
        widget.galleryIndex != null && widget.onTapImageAtIndex != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final intrinsicSize =
            _resolvedIntrinsicSize ?? widget.fallbackIntrinsicSize;
        if (intrinsicSize == null ||
            !intrinsicSize.width.isFinite ||
            !intrinsicSize.height.isFinite ||
            intrinsicSize.width <= 0 ||
            intrinsicSize.height <= 0) {
          return _buildTapWrapper(
            context: context,
            child: widget.child,
            shouldShrink: false,
            hasGalleryTap: hasGalleryTap,
          );
        }

        final mediaQueryWidth = MediaQuery.maybeOf(context)?.size.width;
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : mediaQueryWidth;
        final effectiveAvailableWidth =
            availableWidth != null &&
                availableWidth.isFinite &&
                availableWidth > 0
            ? availableWidth
            : intrinsicSize.width;

        final widthScale = effectiveAvailableWidth < intrinsicSize.width
            ? effectiveAvailableWidth / intrinsicSize.width
            : 1.0;
        final renderedWidth = intrinsicSize.width * widthScale;
        final renderedHeight = intrinsicSize.height * widthScale;
        final renderedLongestEdge = math.max(renderedWidth, renderedHeight);
        final shrinkTriggerEdge =
            effectiveAvailableWidth * widget.shrinkTriggerWidthFactor;
        final shrinkTargetEdge =
            effectiveAvailableWidth * widget.shrinkTargetWidthFactor;
        final shouldShrink =
            !_expanded && renderedLongestEdge > shrinkTriggerEdge;
        final canShrinkToEdge = math.min(shrinkTargetEdge, renderedLongestEdge);
        final shrinkScale = shouldShrink && renderedLongestEdge > 0
            ? canShrinkToEdge / renderedLongestEdge
            : 1.0;
        final shrinkWidth = renderedWidth * shrinkScale;
        final shrinkHeight = renderedHeight * shrinkScale;

        final naturalDisplay = SizedBox(
          width: renderedWidth,
          height: renderedHeight,
          child: widget.child,
        );

        Widget display = naturalDisplay;
        if (shouldShrink) {
          display = Align(
            alignment: Alignment.centerLeft,
            child: _ShrunkImageNotice(
              width: shrinkWidth,
              image: SizedBox(
                width: shrinkWidth,
                height: shrinkHeight,
                child: widget.child,
              ),
            ),
          );
        }

        return _buildTapWrapper(
          context: context,
          child: display,
          shouldShrink: shouldShrink,
          hasGalleryTap: hasGalleryTap,
        );
      },
    );
  }

  Widget _buildTapWrapper({
    required BuildContext context,
    required Widget child,
    required bool shouldShrink,
    required bool hasGalleryTap,
  }) {
    final canHandleTap = shouldShrink || hasGalleryTap;
    if (!canHandleTap) {
      return child;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(context, shouldShrink: shouldShrink),
        child: child,
      ),
    );
  }

  void _handleTap(BuildContext context, {required bool shouldShrink}) {
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
  }
}

class _ShrunkImageNotice extends StatelessWidget {
  final double width;
  final Widget image;

  const _ShrunkImageNotice({required this.width, required this.image});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.9),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              image,
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.open_in_full_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

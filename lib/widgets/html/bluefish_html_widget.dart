import 'package:bluefish/pages/photo_gallery_page.dart';
import 'package:bluefish/widgets/html/bluefish_html_widget_factory.dart';
import 'package:bluefish/widgets/html/vote/vote_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class BluefishHtmlWidget extends StatelessWidget {
  final String html;
  final TextStyle? textStyle;
  final bool enableImageGallery;
  final String? imageHeroScope;

  const BluefishHtmlWidget(
    this.html, {
    super.key,
    this.textStyle,
    this.enableImageGallery = false,
    this.imageHeroScope,
  });

  @override
  Widget build(BuildContext context) {
    final galleryData = enableImageGallery
        ? _prepareImageGalleryHtml()
        : const _PreparedImageGalleryHtml(
            html: null,
            imageUrls: <String>[],
            heroTags: null,
          );
    final renderedHtml = galleryData.html ?? html;

    return SelectionArea(
      child: HtmlWidget(
        renderedHtml,
        textStyle: textStyle,
        factoryBuilder: () => BluefishHtmlWidgetFactory(
          onTapImageAtIndex: enableImageGallery
              ? (context, galleryIndex) => _openPhotoGallery(
                  context,
                  imageUrls: galleryData.imageUrls,
                  heroTags: galleryData.heroTags,
                  initialIndex: galleryIndex,
                )
              : null,
        ),
        customWidgetBuilder: _buildCustomWidget,
      ),
    );
  }

  Widget? _buildCustomWidget(dom.Element element) {
    if (element.localName == 'span' &&
        element.attributes['data-type'] == 'vote') {
      final voteId = int.tryParse(element.attributes['data-vote-id'] ?? '');
      if (voteId != null) {
        return VoteWidget(voteId: voteId);
      }
    }

    return null;
  }

  _PreparedImageGalleryHtml _prepareImageGalleryHtml() {
    final fragment = html_parser.parseFragment(html);
    final imageUrls = <String>[];
    final imageHeroScope = this.imageHeroScope;
    final heroTags = imageHeroScope == null ? null : <Object>[];

    for (final element in fragment.querySelectorAll('img')) {
      final normalizedUrl = _normalizeImageUrl(element.attributes['src']);
      if (normalizedUrl == null) {
        continue;
      }

      final galleryIndex = imageUrls.length;
      imageUrls.add(normalizedUrl);
      element.attributes[bluefishGalleryIndexAttribute] = galleryIndex
          .toString();

      if (imageHeroScope != null) {
        final heroTag = '$imageHeroScope:image:$galleryIndex';
        element.attributes[bluefishHeroTagAttribute] = heroTag;
        heroTags!.add(heroTag);
      }
    }

    if (imageUrls.isEmpty) {
      return const _PreparedImageGalleryHtml(
        html: null,
        imageUrls: <String>[],
        heroTags: null,
      );
    }

    return _PreparedImageGalleryHtml(
      html: fragment.outerHtml,
      imageUrls: List.unmodifiable(imageUrls),
      heroTags: heroTags == null ? null : List.unmodifiable(heroTags),
    );
  }

  String? _normalizeImageUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    return trimmed;
  }

  void _openPhotoGallery(
    BuildContext context, {
    required List<String> imageUrls,
    required List<Object>? heroTags,
    required int initialIndex,
  }) {
    if (imageUrls.isEmpty ||
        initialIndex < 0 ||
        initialIndex >= imageUrls.length) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGalleryPage(
          imageUrls: imageUrls,
          heroTags: heroTags,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _PreparedImageGalleryHtml {
  final String? html;
  final List<String> imageUrls;
  final List<Object>? heroTags;

  const _PreparedImageGalleryHtml({
    required this.html,
    required this.imageUrls,
    required this.heroTags,
  });
}

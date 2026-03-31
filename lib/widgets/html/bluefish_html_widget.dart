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
    final imageUrls = enableImageGallery
        ? _extractImageUrls()
        : const <String>[];
    final heroTags = _buildHeroTags(imageUrls);

    return SelectionArea(
      child: HtmlWidget(
        html,
        textStyle: textStyle,
        factoryBuilder: () => BluefishHtmlWidgetFactory(
          imageHeroTagsByUrl: _groupHeroTagsByUrl(imageUrls, heroTags),
        ),
        customWidgetBuilder: _buildCustomWidget,
        onTapImage: enableImageGallery
            ? (imageMetadata) => _openPhotoGallery(
                context,
                imageUrls: imageUrls,
                heroTags: heroTags,
                imageMetadata: imageMetadata,
              )
            : null,
      ),
    );
  }

  Widget? _buildCustomWidget(dom.Element element) {
    if (element.localName == 'span' &&
        element.attributes['data-type'] == 'vote') {
      final voteId = int.tryParse(element.attributes['data-vote-id'] ?? '');
      if (voteId != null) {
        return VoteWidget(voteID: voteId);
      }
    }

    return null;
  }

  List<Object>? _buildHeroTags(List<String> imageUrls) {
    final imageHeroScope = this.imageHeroScope;
    if (imageHeroScope == null || imageUrls.isEmpty) {
      return null;
    }

    return List<Object>.generate(
      imageUrls.length,
      (index) => '$imageHeroScope:image:$index',
      growable: false,
    );
  }

  Map<String, List<Object>> _groupHeroTagsByUrl(
    List<String> imageUrls,
    List<Object>? heroTags,
  ) {
    if (heroTags == null || imageUrls.isEmpty) {
      return const {};
    }

    final groupedTags = <String, List<Object>>{};
    for (var i = 0; i < imageUrls.length; i++) {
      groupedTags.putIfAbsent(imageUrls[i], () => <Object>[]).add(heroTags[i]);
    }

    return groupedTags;
  }

  List<String> _extractImageUrls() {
    final fragment = html_parser.parseFragment(html);

    return fragment
        .querySelectorAll('img')
        .map((element) => _normalizeImageUrl(element.attributes['src']))
        .whereType<String>()
        .toList(growable: false);
  }

  String? _firstImageUrl(ImageMetadata imageMetadata) {
    for (final source in imageMetadata.sources) {
      final normalizedUrl = _normalizeImageUrl(source.url);
      if (normalizedUrl != null) {
        return normalizedUrl;
      }
    }

    return null;
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
    required ImageMetadata imageMetadata,
  }) {
    final tappedUrl = _firstImageUrl(imageMetadata);
    final galleryUrls = imageUrls.isNotEmpty
        ? imageUrls
        : <String>[if (tappedUrl != null) tappedUrl];
    if (galleryUrls.isEmpty) {
      return;
    }

    final initialIndex = tappedUrl == null ? 0 : galleryUrls.indexOf(tappedUrl);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGalleryPage(
          imageUrls: galleryUrls,
          heroTags: heroTags,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }
}

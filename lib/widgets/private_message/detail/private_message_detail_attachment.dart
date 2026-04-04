import 'package:bluefish/models/private_message_detail.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/theme/bluefish_semantic_colors.dart';
import 'package:flutter/material.dart';

enum PrivateMessageCardAttachmentTone { mine, other }

class PrivateMessageCardAttachment extends StatelessWidget {
  final CardPm cardPm;
  final int messageId;
  final PrivateMessageCardAttachmentTone tone;

  const PrivateMessageCardAttachment({
    super.key,
    required this.cardPm,
    required this.messageId,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semanticColors = context.semanticColors;
    final accentColor = switch (tone) {
      PrivateMessageCardAttachmentTone.mine => semanticColors.linkAccent,
      PrivateMessageCardAttachmentTone.other => semanticColors.linkAccentAlt,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cardPm.images.isNotEmpty) ...[
            PrivateMessageCardImageStrip(
              messageId: messageId,
              images: cardPm.images,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            cardPm.title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (cardPm.intro.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cardPm.intro,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.open_in_new, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cardPm.redirection.text,
                    style: textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivateMessageCardImageStrip extends StatefulWidget {
  final int messageId;
  final List<CardPmImage> images;

  const PrivateMessageCardImageStrip({
    super.key,
    required this.messageId,
    required this.images,
  });

  @override
  State<PrivateMessageCardImageStrip> createState() =>
      _PrivateMessageCardImageStripState();
}

class _PrivateMessageCardImageStripState
    extends State<PrivateMessageCardImageStrip> {
  final ScrollController _scrollController = ScrollController();

  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRightFade());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    _updateRightFade();
  }

  void _updateRightFade() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final shouldShowFade =
        widget.images.length > 1 &&
        position.maxScrollExtent > 0 &&
        position.pixels < position.maxScrollExtent - 4;

    if (_showRightFade != shouldShowFade) {
      setState(() {
        _showRightFade = shouldShowFade;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 164,
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _updateRightFade(),
          );

          final imageWidth = (constraints.maxWidth * 0.74)
              .clamp(140.0, 220.0)
              .toDouble();

          return Stack(
            children: [
              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final image = widget.images[index];
                  final imageUrl = image.imageUrl.toString();

                  return SizedBox(
                    width: imageWidth,
                    child: GestureDetector(
                      onTap: () {
                        context.pushPhotoGallery(
                          imageUrls: widget.images
                              .map((item) => item.imageUrl.toString())
                              .toList(growable: false),
                          initialIndex: index,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_showRightFade)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            colorScheme.surface.withValues(alpha: 0),
                            colorScheme.surface.withValues(alpha: 0.96),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

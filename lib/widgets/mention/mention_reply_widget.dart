// this widget is fully from vibe. so is it reliable?

import 'package:bluefish/models/mention_reply.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/widgets/mention/mention_card_components.dart';
import 'package:bluefish/widgets/mention/mention_grouped_sliver_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MentionReplyCard extends StatefulWidget {
  final MentionReply reply;

  const MentionReplyCard({super.key, required this.reply});

  @override
  State<MentionReplyCard> createState() => _MentionReplyCardState();
}

class _MentionReplyCardState extends State<MentionReplyCard> {
  MentionReply get reply => widget.reply;
  String? get _threaderLabel {
    final label = reply.threader?.trim();
    if (label == null || label.isEmpty) {
      return null;
    }
    return label;
  }

  // TODO: check what each status number's indicates.
  bool get _notDisplay =>
      reply.auditStatus != null && reply.auditStatus != 1 ||
      reply.delete != null && reply.delete != 0 ||
      reply.hide != null && reply.hide != 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MentionCardShell(
      onTap: () {
        // TODO: jump to thread detail.
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colorScheme, textTheme),
          if (_notDisplay)
            const MentionUnavailableBanner(message: "该回复当前可能无法查看"),
          const SizedBox(height: 16),
          _buildContent(context, colorScheme, textTheme),
          if (reply.imagesList.isNotEmpty) _buildImages(context),
          if (reply.quoteContent.isNotEmpty)
            _buildQuote(context, colorScheme, textTheme),
          const SizedBox(height: 12),
          MentionThreadSource(title: reply.threadTitle),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            reply.avatarUrl.toString(),
            fit: BoxFit.cover,
            height: 40,
            width: 40,
            errorBuilder: (context, error, stack) => Container(
              height: 40,
              width: 40,
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      reply.username,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_threaderLabel != null) ...[
                    const SizedBox(width: 8),
                    _ThreaderBadge(label: _threaderLabel!),
                  ],
                ],
              ),
              // check if there's Chinese characters in time str.
              RegExp(r"[\u4e00-\u9fa5]").hasMatch(reply.publishTimeFormatStr)
                  ? Text(
                      "${DateFormat("yyyy-MM-dd HH:mm:ss").format(reply.publishTime)} (${reply.publishTimeFormatStr})",
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Text(
                      DateFormat(
                        "yyyy-MM-dd HH:mm:ss",
                      ).format(reply.publishTime),
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return MentionExpandableTextSection(
      text: reply.content,
      maxLines: 4,
      textStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      style: MentionExpandableTextStyle.fade,
      fadeColor: colorScheme.surfaceContainerHigh,
    );
  }

  Widget _buildImages(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _MentionReplyImageStrip(reply: reply),
    );
  }

  Widget _buildQuote(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final displayQuote = _sanitizeQuoteContent(reply.quoteContent);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: colorScheme.tertiary, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: MentionExpandableTextSection(
          text: displayQuote,
          maxLines: 3,
          textStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          style: MentionExpandableTextStyle.fade,
          fadeColor: colorScheme.surfaceContainerHigh,
        ),
      ),
    );
  }

  String _sanitizeQuoteContent(String input) {
    return input.replaceAllMapped(
      RegExp(r'(\[(?:图片|多图|视频)\][^\/]*).*?/quality.*$'),
      (match) => match.group(1) ?? '',
    );
  }
}

class _ThreaderBadge extends StatelessWidget {
  final String label;

  const _ThreaderBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MentionReplyImageStrip extends StatefulWidget {
  final MentionReply reply;

  const _MentionReplyImageStrip({required this.reply});

  @override
  State<_MentionReplyImageStrip> createState() =>
      _MentionReplyImageStripState();
}

class _MentionReplyImageStripState extends State<_MentionReplyImageStrip> {
  final ScrollController _scrollController = ScrollController();
  bool _showRightFade = false;
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRightFade());
  }

  void _handleScroll() {
    if (!_hasScrolled &&
        _scrollController.hasClients &&
        _scrollController.position.pixels > 4) {
      setState(() {
        _hasScrolled = true;
      });
    }
    _updateRightFade();
  }

  void _updateRightFade() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final shouldShowFade =
        widget.reply.imagesList.length > 1 &&
        position.maxScrollExtent > 0 &&
        position.pixels < position.maxScrollExtent - 4;

    if (shouldShowFade != _showRightFade) {
      setState(() {
        _showRightFade = shouldShowFade;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 160,
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _updateRightFade(),
          );
          final imageWidth = (constraints.maxWidth * 0.72)
              .clamp(120.0, 180.0)
              .toDouble();

          return Stack(
            children: [
              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final imageUrl = widget.reply.imagesList[index].url
                      .toString();

                  return SizedBox(
                    width: imageWidth,
                    child: GestureDetector(
                      onTap: () {
                        context.pushPhotoGallery(
                          imageUrls: widget.reply.imagesList
                              .map((e) => e.url.toString())
                              .toList(growable: false),
                          initialIndex: index,
                        );
                      },
                      child: Hero(
                        tag: imageUrl,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox.expand(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemCount: widget.reply.imagesList.length,
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
                            colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0,
                            ),
                            colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.96,
                            ),
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

class MentionReplyListWidget extends StatelessWidget {
  final List<MentionReply> newReplies;
  final List<MentionReply> oldReplies;
  final bool hasNextPage;
  final bool isLoading;

  const MentionReplyListWidget({
    super.key,
    required this.newReplies,
    required this.oldReplies,
    required this.hasNextPage,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return MentionGroupedSliverList<MentionReply>(
      newItems: newReplies,
      oldItems: oldReplies,
      hasNextPage: hasNextPage,
      isLoading: isLoading,
      itemBuilder: (context, item) => MentionReplyCard(reply: item),
    );
  }
}

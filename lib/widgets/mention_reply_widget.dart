// this widget is fully from vibe. so is it reliable?

import 'package:bluefish/models/mention_reply.dart';
import 'package:bluefish/pages/photo_gallery_page.dart';
import 'package:bluefish/widgets/mention_grouped_sliver_list.dart';
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

  // TODO: check what each status number's indicates.
  bool get _notDisplay =>
      reply.auditStatus != null && reply.auditStatus != 1 ||
      reply.delete != null && reply.delete != 0 ||
      reply.hide != null && reply.hide != 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          // TODO: jump to thread detail.
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, colorScheme, textTheme),
              if (_notDisplay) _buildNotDisplayWarning(context, colorScheme, textTheme),
              const SizedBox(height: 16),
              _buildContent(context, colorScheme, textTheme),
              if (reply.imagesList.isNotEmpty) _buildImages(context),
              if (reply.quoteContent.isNotEmpty) _buildQuote(context, colorScheme, textTheme),
              const SizedBox(height: 12),
              _buildThreadSource(context, colorScheme, textTheme),
            ],
          ),
        ),
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
              Text(
                reply.username,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
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
                      DateFormat("yyyy-MM-dd HH:mm:ss").format(reply.publishTime),
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

  Widget _buildNotDisplayWarning(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.errorContainer,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(
              Icons.visibility_off,
              size: 16,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Text(
              "该回复当前可能无法查看",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return _ExpandableTextSection(
      text: reply.content,
      maxLines: 4,
      textStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final imageUrl = reply.imagesList[index].Url.toString();
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoGalleryPage(
                      imageUrls: reply.imagesList
                          .map((e) => e.Url.toString())
                          .toList(),
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Hero(
                tag: imageUrl,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemCount: reply.imagesList.length,
        ),
      ),
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
        child: _ExpandableTextSection(
          text: displayQuote,
          maxLines: 3,
          textStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
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

  Widget _buildThreadSource(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reply.threadTitle,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class MentionReplyListWidget extends StatelessWidget {
  final List<MentionReply> newReplies;
  final List<MentionReply> oldReplies;
  final bool hasNextPage;

  const MentionReplyListWidget({
    super.key,
    required this.newReplies,
    required this.oldReplies,
    required this.hasNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return MentionGroupedSliverList<MentionReply>(
      newItems: newReplies,
      oldItems: oldReplies,
      hasNextPage: hasNextPage,
      itemBuilder: (context, item) => MentionReplyCard(reply: item),
    );
  }
}

class _ExpandableTextSection extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? textStyle;

  const _ExpandableTextSection({
    required this.text,
    required this.maxLines,
    required this.textStyle,
  });

  @override
  State<_ExpandableTextSection> createState() => _ExpandableTextSectionState();
}

class _ExpandableTextSectionState extends State<_ExpandableTextSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.textStyle),
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOverflowing && !_expanded)
              Stack(
                children: [
                  Text(
                    widget.text,
                    textAlign: TextAlign.start,
                    style: widget.textStyle,
                    maxLines: widget.maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() {
                        _expanded = true;
                      }),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.surfaceContainerHigh.withValues(alpha: 0),
                              colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                widget.text,
                textAlign: TextAlign.start,
                style: widget.textStyle,
                maxLines: null,
              ),
            if (isOverflowing)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _expanded = !_expanded;
                  }),
                  child: _expanded
                      ? Center(
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        )
                      : const SizedBox.shrink(),
                  ),
                ),
          ],
        );
      },
    );
  }
}

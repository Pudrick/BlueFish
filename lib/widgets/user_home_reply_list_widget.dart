import 'package:bluefish/models/user_homepage/user_home_reply.dart';
import 'package:bluefish/pages/phoeo_gallery_page.dart';
import 'package:bluefish/utils/remove_string_tag_suffix.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class UserHomeReplyWidget extends StatelessWidget {
  final UserHomeReply reply;
  final bool isQuote;

  // final bool isLoading;
  // final bool isLastPage;
  const UserHomeReplyWidget({
    super.key,
    required this.reply,
    required this.isQuote,
    // required this.isLoading,
    // required this.isLastPage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final backgroundColor = isQuote
        ? colorScheme.tertiaryContainer.withValues(alpha: 0.3)
        : colorScheme.surfaceContainerHigh;

    final BoxBorder? innerBorder = isQuote
        ? Border(left: BorderSide(color: colorScheme.tertiary, width: 4))
        : null;

    final margin = isQuote
        ? const EdgeInsets.only(top: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    final borderRadius = BorderRadius.circular(isQuote ? 8 : 12);

    return Card(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: margin,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      // color: colorScheme.surfaceContainerHigh,
      color: backgroundColor,
      child: InkWell(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(border: innerBorder),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                // avatar, head, time.
                children: [
                  ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(6),
                    child: Image.network(
                      reply.avatarUrl.toString(),
                      fit: BoxFit.cover,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply.userName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),

                        // the regex means "whether formatTime contains Chinese Character."
                        RegExp(r"[\u4e00-\u9fa5]").hasMatch(reply.formatTime)
                            ? Text(
                                "${DateFormat("yyyy-MM-dd HH:mm:ss").format(reply.createTime)} (${reply.formatTime})",
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            : Text(
                                DateFormat(
                                  "yyyy-MM-dd HH:mm:ss",
                                ).format(reply.createTime),
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                textAlign: TextAlign.start,
                reply.replyContent.removeImageSuffixTag(),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),

              if (reply.replyPics.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final imageUrl = reply.replyPics[index].url.toString();

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoGalleryPage(
                                imageUrls: reply.replyPics
                                    .map((e) => e.url.toString())
                                    .toList(),
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: imageUrl,
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  ),
                            ),
                          ),
                        ),
                      );
                      // return ClipRRect(
                      //   borderRadius: BorderRadiusGeometry.circular(8),
                      //   clipBehavior: Clip.antiAlias,
                      //   child: Image.network(
                      //     reply.replyPics[index].url.toString(),
                      //   ),
                      // );
                    },

                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemCount: reply.replyPics.length,
                  ),
                ),
              ],

              // TODO: get a video format and support video in reply.
              if (reply.videoInfo != null) ...[const SizedBox(height: 8)],

              const SizedBox(height: 12),
              if (reply.quote != null && !isQuote) ...[
                UserHomeReplyWidget(reply: reply.quote!, isQuote: true),
                const SizedBox(height: 6),
              ],
              if (!isQuote) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),

                  // TODO: add video info here. (if exists.)

                  // TODO: add reply quote here.
                  child: Row(
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reply.threadTitle,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_incandescent,
                            size: 16,
                            color: colorScheme.onSecondaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reply.lightCount.toString(),
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class UserHomeReplyListWidget extends StatelessWidget {
  final List<UserHomeReply> replyList;

  final bool isLoading;
  final bool isLastPage;

  const UserHomeReplyListWidget({
    super.key,
    required this.replyList,
    required this.isLoading,
    required this.isLastPage,
  });

    Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isLastPage
          ? Text(
              "—— 后面没有了 ——",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            )
          : const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        if(index == replyList.length) return _buildFooter(context);
        final item = replyList[index];
        return UserHomeReplyWidget(reply: item, isQuote: false);
      }, childCount: replyList.length + 1),
    );
  }
}

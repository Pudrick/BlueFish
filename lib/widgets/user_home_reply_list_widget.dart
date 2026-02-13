import 'package:bluefish/models/user_homepage/user_home_reply.dart';
import 'package:bluefish/pages/phoeo_gallery_page.dart';
import 'package:bluefish/utils/remove_string_tag_suffix.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserHomeReplyWidget extends StatelessWidget {
  final UserHomeReply reply;
  final bool isQuote;

  const UserHomeReplyWidget({
    super.key,
    required this.reply,
    required this.isQuote,
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
              if (reply.parsedPHPAttr["audit_status"] != 1) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.errorContainer,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 16,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "该回复当前可能无法查看",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                textAlign: TextAlign.start,
                reply.replyContent.removeSuffixTag(),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),

              if (reply.replyPics.isNotEmpty || reply.videoInfo != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final bool hasVideo = reply.videoInfo != null;
                      
                      if(index == 0 && hasVideo) {
                        return GestureDetector(
                          onTap: () {
                            //TODO: add the video play logic.
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  reply.videoInfo!.coverImgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Container(
                      width: 160,
                      color: Colors.black12,
                      child: const Center(child: Icon(Icons.videocam, size: 40)),
                    ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle
                                  ),
                                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 30,),
                                )
                              ],
                            ),
                          ),
                        );
                      }

                      final int imageIndex = hasVideo ? index - 1 : index;
                      final imageUrl = reply.replyPics[imageIndex].url.toString();
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoGalleryPage(
                                imageUrls: reply.replyPics
                                    .map((e) => e.url.toString())
                                    .toList(),
                                initialIndex: imageIndex,
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
                    },

                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemCount: reply.replyPics.length + (reply.videoInfo != null ? 1 : 0),
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
        if (index == replyList.length) return _buildFooter(context);
        final item = replyList[index];
        return UserHomeReplyWidget(reply: item, isQuote: false);
      }, childCount: replyList.length + 1),
    );
  }
}

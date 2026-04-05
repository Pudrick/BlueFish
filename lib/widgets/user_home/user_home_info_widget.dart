import 'package:bluefish/models/user_home/user_home.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:flutter/material.dart';

class UserHomeInfoWidget extends StatelessWidget {
  final UserHome userHome;

  const UserHomeInfoWidget({super.key, required this.userHome});

  Widget _statusCard(BuildContext context, String name, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, {required bool isCompact}) {
    final avatarSize = isCompact ? 92.0 : 108.0;
    final avatarUrl = userHome.avatarUrl.toString();
    final heroTag = 'user_avatar_${userHome.puid}';

    return GestureDetector(
      onTap: () {
        context.pushPhotoGallery(
          imageUrls: <String>[avatarUrl],
          initialIndex: 0,
          heroTags: <Object>[heroTag],
        );
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              width: avatarSize,
              height: avatarSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoStrContainer(BuildContext context, String info) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        info,
        style: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMetaWrap(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _infoStrContainer(context, userHome.bbsUserLevelFormatedStr),
        _infoStrContainer(context, 'IP属地：${userHome.location}'),
        _infoStrContainer(context, '${userHome.reputation}声望'),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    const cardGap = 10.0;
    final stats = [
      ('回复被点亮', userHome.beLightCount),
      ('主贴被推荐', userHome.beRecommendCount),
      ('关注', userHome.followCount),
      ('粉丝', userHome.fansCount),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth < 640;
        final columns = useTwoColumns ? 2 : 4;
        final tileWidth =
            (constraints.maxWidth - cardGap * (columns - 1)) / columns;

        return Wrap(
          spacing: cardGap,
          runSpacing: cardGap,
          children: [
            for (final (label, count) in stats)
              SizedBox(
                width: tileWidth,
                child: _statusCard(context, label, count),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isFollowed = userHome.followStatus != FollowStatus.notFollowed;
    final textTheme = Theme.of(context).textTheme;
    final buttonLabelStyle = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackButtons = constraints.maxWidth < 320;
        final followButton = SizedBox(
          height: 40,
          child: isFollowed
              ? FilledButton.tonal(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check),
                      const SizedBox(width: 4),
                      Text('已关注', style: buttonLabelStyle),
                    ],
                  ),
                )
              : FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add_outlined),
                      const SizedBox(width: 4),
                      Text('关注', style: buttonLabelStyle),
                    ],
                  ),
                ),
        );
        final messageButton = SizedBox(
          height: 40,
          child: OutlinedButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline_outlined),
                const SizedBox(width: 4),
                Text('私信', style: buttonLabelStyle),
              ],
            ),
          ),
        );

        if (stackButtons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [followButton, const SizedBox(height: 10), messageButton],
          );
        }

        return Row(
          children: [
            Expanded(child: followButton),
            const SizedBox(width: 10),
            Expanded(child: messageButton),
          ],
        );
      },
    );
  }

  Widget _buildProfileSummary(BuildContext context, {required bool isCompact}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: isCompact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        Text(
          userHome.nickname,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        _buildMetaWrap(context),
        const SizedBox(height: 16),
        _buildStatsGrid(context),
        const SizedBox(height: 12),
        _buildActionButtons(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        return Card(
          elevation: 1,
          color: colorScheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _buildAvatar(context, isCompact: true)),
                      const SizedBox(height: 16),
                      _buildProfileSummary(context, isCompact: true),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(context, isCompact: false),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildProfileSummary(context, isCompact: false),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

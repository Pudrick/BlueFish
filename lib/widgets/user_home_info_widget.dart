import 'package:bluefish/models/user_homepage/user_home.dart';
import 'package:flutter/material.dart';

class UserHomeInfoWidget extends StatelessWidget {
  final UserHome userHome;

  const UserHomeInfoWidget({super.key, required this.userHome});

  Widget _statusCard(BuildContext context, String name, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 紧凑布局
          children: [
            Text(
              count.toString(), // 建议封装一个数字格式化（如 1.2k）
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4), // 增加一点间距
            Text(
              name,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline, // 使用更淡的颜色
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoStrContainer(ColorScheme colorScheme, String info) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), // 降低不透明度，更清爽
        borderRadius: BorderRadius.circular(8), // 圆角
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        info,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _verticalDivider(BuildContext context) {
  return VerticalDivider(
    width: 1, 
    thickness: 1, 
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), 
    indent: 10, 
    endIndent: 10,
  );
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  

                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
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
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      userHome.avatarUrl.toString(),
                      fit: BoxFit.cover,
                      height: 180,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16,),

              // Expanded is used for provide a width value for Row.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 180,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            userHome.nickname,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _infoStrContainer(
                              colorScheme,
                              userHome.bbsUserLevelFormatedStr,
                            ),
                            _infoStrContainer(
                              colorScheme,
                              "IP属地：${userHome.location}",
                            ),
                            _infoStrContainer(
                              colorScheme,
                              "${userHome.reputation}声望",
                            ),
                          ],
                        ),
                        // a "stupid" way to do it...
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Column(
                            children: [
                              // IntrinsicHeight is for visualize the vertical divider.
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _statusCard(
                                        context,
                                        "回复被点亮",
                                        userHome.beLightCount,
                                      ),
                                    ),
                                    _verticalDivider(context),
                                    Expanded(
                                      child: _statusCard(
                                        context,
                                        "主贴被推荐",
                                        userHome.beRecommendCount,
                                      ),
                                    ),
                                    _verticalDivider(context),
                                       Expanded(
                                      child: _statusCard(
                                        context,
                                        "关注",
                                        userHome.followCount,
                                      ),
                                    ),
                                    _verticalDivider(context),
                                    Expanded(
                                      child: _statusCard(
                                        context,
                                        "粉丝",
                                        userHome.fansCount,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 36, 
                                      child: 
                                      (userHome.followStatus == FollowStatus.notFollowed) ? 
                                      FilledButton(
                                        onPressed: () {},
                                        style: 
                                        FilledButton.styleFrom(
                                          padding: EdgeInsets.zero, 
                                          visualDensity:
                                              VisualDensity.compact, 
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person_add_outlined),
                                            SizedBox(width: 4,),
                                            Text(
                                              "关注",
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ) :
                                                FilledButton.tonal(
                                        onPressed: (){},
                                        style: 
                                        FilledButton.styleFrom(
                                          padding: EdgeInsets.zero, 
                                          visualDensity:
                                              VisualDensity.compact, 
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check),
                                            SizedBox(width: 4,),
                                            Text(
                                              "已关注",
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: OutlinedButton(
                                        onPressed: () {},
                                        style: FilledButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.mail_outline_outlined),
                                            SizedBox(width: 4,),
                                            Text(
                                              "私信",
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

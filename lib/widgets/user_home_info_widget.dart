import 'package:bluefish/models/user_homepage/user_home.dart';
import 'package:flutter/material.dart';

class UserHomeInfoWidget extends StatelessWidget {
  final UserHome userHome;

  const UserHomeInfoWidget({super.key, required this.userHome});

  Widget _statusCard(BuildContext context, String name, int count) {
    final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            children: [
              Text(
                count.toString(),
       style: textTheme.labelLarge?.copyWith( 
                fontWeight: FontWeight.bold,
                color: colorScheme.onSecondaryContainer,
                height: 1.0, 
              ),
              ),
              const SizedBox(height: 2,),
              Text(
                name,
                style: textTheme.labelSmall?.copyWith( // 【压缩 4】：改用 labelSmall (约11px)
                fontSize: 10, // 强制指定更小字号
                color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                height: 1.2,
              ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
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
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                 Text(
                    userHome.nickname,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 6,),
                  //   Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       Text(userHome.bbsUserLevelFormatedStr),
                  //       Text("IP属地：${userHome.location}"),
                  //       Text("${userHome.reputation}声望"),
                  //     ],
                  //   ),
                    // a "stupid" way to do it...
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _statusCard(
                                context,
                                "回复被点亮",
                                userHome.beLightCount,
                              ),
                            ),
                            Expanded(
                              child: _statusCard(
                                context,
                                "主贴被推荐",
                                userHome.beRecommendCount,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _statusCard(
                                context,
                                "关注",
                                userHome.followCount,
                              ),
                            ),
                            Expanded(
                              child: _statusCard(
                                context,
                                "粉丝",
                                userHome.fansCount,
                              ),
                            ),
                          ],
                        ),
                        Row(
                  children: [
                    // 关注按钮 (主要操作 - FilledButton)
                    Expanded(
                      child: SizedBox(
                        height: 36, // 强制压低按钮高度
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero, // 减少内边距
                            visualDensity: VisualDensity.compact, // 紧凑模式
                          ),
                          child: const Text("关注", style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 私信按钮 (次要操作 - Tonal 或 Outlined)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: FilledButton.tonal( // Tonal 颜色更柔和，不抢主视觉
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text("私信", style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

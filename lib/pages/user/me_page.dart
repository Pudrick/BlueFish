import 'package:bluefish/auth/current_user_identity_controller.dart';
import 'package:bluefish/router/app_routes.dart';
import 'package:bluefish/services/thread/thread_gift_service.dart';
import 'package:bluefish/viewModels/current_user_profile_view_model.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<
      CurrentUserIdentityController,
      CurrentUserProfileViewModel
    >(
      builder: (context, currentUserIdentity, currentUserProfileViewModel, _) {
        final isLoggedIn = currentUserIdentity.isLoggedIn;
        final profile = isLoggedIn ? currentUserProfileViewModel.profile : null;
        final supportingText = isLoggedIn ? null : '当前未检测到登录会话，点击后前往登录页';
        final currentUserEuid = currentUserIdentity.currentUserEuid;
        final currentUserPuid = currentUserIdentity.currentUserPuid;

        final VoidCallback? onHeaderTap = switch (isLoggedIn) {
          false => () => context.pushLogin(),
          true when currentUserEuid != null =>
            () => context.maybeGoRouter?.push<void>(
              AppRoutes.userHomeLocation(euid: currentUserEuid),
            ),
          true when currentUserPuid != null =>
            () => context.maybeGoRouter?.push<void>(
              AppRoutes.userHomeLocation(puid: currentUserPuid),
            ),
          _ => null,
        };

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxContentWidth = constraints.maxWidth >= 1024
                    ? 960.0
                    : double.infinity;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _MeHeaderCard(
                          title: isLoggedIn
                              ? (profile?.username ?? '个人中心')
                              : '未登录',
                          avatarUrl: isLoggedIn ? profile?.avatarUrl : null,
                          hasActiveSession: isLoggedIn,
                          supportingText: supportingText,
                          onTap: onHeaderTap,
                        ),
                        const SizedBox(height: 24),
                        _NotchedSection(
                          key: const ValueKey('me-section-account'),
                          title: '账户',
                          child: _FeatureGrid(
                            items: [
                              _MeFeatureItemData(
                                key: 'profile',
                                title: '编辑资料',
                                icon: Icons.account_circle_outlined,
                                statusLabel: isLoggedIn ? '待接入' : '先登录',
                                tone: _MeFeatureTone.primary,
                                onTap: isLoggedIn
                                    ? null
                                    : () {
                                        context.pushLogin();
                                      },
                              ),
                              _MeFeatureItemData(
                                key: 'settings',
                                title: '设置',
                                icon: Icons.settings_outlined,
                                tone: _MeFeatureTone.secondary,
                                onTap: () {
                                  context.pushSettings();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _NotchedSection(
                          key: const ValueKey('me-section-activity'),
                          title: '互动与记录',
                          child: _FeatureGrid(
                            items: [
                              _MeFeatureItemData(
                                key: 'favorites',
                                title: '收藏',
                                icon: Icons.bookmark_border_rounded,
                                tone: _MeFeatureTone.tertiary,
                                onTap: () {
                                  _openPlaceholderPage(
                                    context,
                                    title: '收藏',
                                    icon: Icons.bookmark_border_rounded,
                                    statusLabel: '占位入口',
                                    description: '这里后续会集中展示你收藏过的帖子、回复和相关内容。',
                                  );
                                },
                              ),
                              _MeFeatureItemData(
                                key: 'lights',
                                title: '点亮',
                                icon: Icons.wb_incandescent_outlined,
                                tone: _MeFeatureTone.warning,
                                onTap: () {
                                  _openPlaceholderPage(
                                    context,
                                    title: '点亮',
                                    icon: Icons.wb_incandescent_outlined,
                                    statusLabel: '占位入口',
                                    description: '这里后续会展示你点亮过的内容，方便回看互动痕迹。',
                                  );
                                },
                              ),
                              _MeFeatureItemData(
                                key: 'history',
                                title: '历史记录',
                                icon: Icons.history_rounded,
                                tone: _MeFeatureTone.neutral,
                                onTap: () {
                                  _openPlaceholderPage(
                                    context,
                                    title: '历史记录',
                                    icon: Icons.history_rounded,
                                    statusLabel: '占位入口',
                                    description: '这里后续会整理最近浏览过的帖子与页面，方便继续阅读。',
                                  );
                                },
                              ),
                              _MeFeatureItemData(
                                key: 'drafts',
                                title: '草稿箱',
                                icon: Icons.edit_note_rounded,
                                tone: _MeFeatureTone.primary,
                                onTap: () {
                                  _openPlaceholderPage(
                                    context,
                                    title: '草稿箱',
                                    icon: Icons.edit_note_rounded,
                                    statusLabel: '占位入口',
                                    description: '这里后续会集中管理未发布的帖子和回复草稿，方便继续编辑。',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _NotchedSection(
                          key: const ValueKey('me-section-assets'),
                          title: '礼物',
                          child: _HcoinAssetCard(
                            isLoggedIn: isLoggedIn,
                            currentUserPuid: currentUserPuid,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static void _openPlaceholderPage(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String statusLabel,
    required String description,
    String? supportingText,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FeaturePlaceholderPage(
          title: title,
          icon: icon,
          statusLabel: statusLabel,
          description: description,
          supportingText: supportingText,
        ),
      ),
    );
  }
}

class _MeHeaderCard extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final bool hasActiveSession;
  final String? supportingText;
  final VoidCallback? onTap;

  const _MeHeaderCard({
    required this.title,
    required this.avatarUrl,
    required this.hasActiveSession,
    required this.supportingText,
    required this.onTap,
  });

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedAvatarUrl = avatarUrl?.trim();

    if (normalizedAvatarUrl == null || normalizedAvatarUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_rounded,
          size: 28,
          color: colorScheme.onPrimaryContainer,
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: CachedNetworkImage(
        key: const ValueKey('me-header-avatar-image'),
        imageUrl: normalizedAvatarUrl,
        fit: BoxFit.cover,
        placeholder: (context, _) => ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        errorBuilder: (context, _, _) => ColoredBox(
          color: colorScheme.primaryContainer,
          child: Icon(
            Icons.person_rounded,
            size: 28,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final normalizedSupportingText = supportingText?.trim();
    final hasSupportingText =
        normalizedSupportingText != null && normalizedSupportingText.isNotEmpty;
    final indicatorColor = onTap == null
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.55)
        : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        key: const ValueKey('me-header-button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          key: const ValueKey('me-header-card'),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        key: const ValueKey('me-header-title'),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HeaderStatusPill(
                        label: hasActiveSession ? '已登录' : '未登录',
                        active: hasActiveSession,
                        compact: true,
                      ),
                      if (hasSupportingText) ...[
                        const SizedBox(height: 8),
                        Text(
                          normalizedSupportingText,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Center(
                  child: Container(
                    key: const ValueKey('me-header-chevron'),
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: indicatorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStatusPill extends StatelessWidget {
  final String label;
  final bool active;
  final bool compact;

  const _HeaderStatusPill({
    required this.label,
    required this.active,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = active
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = active
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotchedSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _NotchedSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: child,
          ),
        ),
        Positioned(
          left: 18,
          top: -11,
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<_MeFeatureItemData> items;

  const _FeatureGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = _resolveColumnCount(constraints.maxWidth);
        final itemWidth = columns == 1
            ? (items.length == 1 && constraints.maxWidth >= 420
                  ? 220.0
                  : constraints.maxWidth)
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _FeatureCard(item: item),
              ),
          ],
        );
      },
    );
  }

  int _resolveColumnCount(double maxWidth) {
    if (items.length <= 1) {
      return 1;
    }
    if (items.length >= 4 && maxWidth >= 760) {
      return 4;
    }
    if (maxWidth >= 250) {
      return 2;
    }
    return 1;
  }
}

class _HcoinAssetCard extends StatefulWidget {
  final bool isLoggedIn;
  final String? currentUserPuid;

  const _HcoinAssetCard({
    required this.isLoggedIn,
    required this.currentUserPuid,
  });

  @override
  State<_HcoinAssetCard> createState() => _HcoinAssetCardState();
}

class _HcoinAssetCardState extends State<_HcoinAssetCard> {
  int? _hcoinBalance;
  bool _isRefreshing = false;
  bool _isReceiving = false;

  String get _balanceDisplay => _hcoinBalance?.toString() ?? '--';

  Future<void> _handleRefreshTap() async {
    if (_isRefreshing || _isReceiving) {
      return;
    }

    if (!_ensureReadyForAuthenticatedAction()) {
      return;
    }

    await _refreshBalance();
  }

  Future<void> _refreshBalance({bool silentFailure = false}) async {
    if (_isRefreshing || !mounted) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    final result = await context.read<ThreadGiftService>().getHcoin(
      forceRefresh: true,
    );
    if (!mounted) {
      return;
    }

    String? snackBarMessage;
    final nextBalance = result.when<int?>(
      success: (balance) => balance,
      failure: (message, exception) {
        snackBarMessage = message;
        return null;
      },
    );

    setState(() {
      _isRefreshing = false;
      if (nextBalance != null) {
        _hcoinBalance = nextBalance;
      }
    });

    if (!silentFailure &&
        snackBarMessage != null &&
        snackBarMessage!.isNotEmpty) {
      _showSnackBar(snackBarMessage!);
    }
  }

  Future<void> _handleReceiveTap() async {
    if (_isRefreshing || _isReceiving) {
      return;
    }

    if (!_ensureReadyForAuthenticatedAction()) {
      return;
    }

    final currentUserPuid = widget.currentUserPuid?.trim();
    if (currentUserPuid == null || currentUserPuid.isEmpty) {
      _showSnackBar('当前账号信息不完整，暂时无法领取H币。');
      return;
    }

    setState(() {
      _isReceiving = true;
    });

    final threadGiftService = context.read<ThreadGiftService>();
    final receivableResult = await threadGiftService.getReceivableHcoinList();
    if (!mounted) {
      return;
    }

    final receivableItems = receivableResult.dataOrNull;
    if (receivableItems == null) {
      final message = receivableResult.when<String?>(
        success: (_) => null,
        failure: (message, exception) => message,
      );
      setState(() {
        _isReceiving = false;
      });
      if (message?.isNotEmpty ?? false) {
        _showSnackBar(message!);
      }
      return;
    }

    if (receivableItems.isEmpty) {
      setState(() {
        _isReceiving = false;
      });
      _showSnackBar('当前没有可领取的H币', width: 260);
      return;
    }

    final receiveResult = await threadGiftService.receiveHcoin(
      puid: currentUserPuid,
      ids: receivableItems.map((item) => item.id).toList(growable: false),
    );
    if (!mounted) {
      return;
    }

    final receiveSucceeded = receiveResult.isSuccess;
    final snackBarMessage = receiveResult.when<String>(
      success: (_) => '获取成功',
      failure: (message, exception) => message,
    );

    setState(() {
      _isReceiving = false;
    });

    if (receiveSucceeded) {
      await _refreshBalance(silentFailure: true);
      if (!mounted) {
        return;
      }
    }

    _showSnackBar(snackBarMessage);
  }

  bool _ensureReadyForAuthenticatedAction() {
    if (widget.isLoggedIn) {
      return true;
    }

    context.pushLogin();
    return false;
  }

  void _showSnackBar(String message, {double? width}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final resolvedWidth = width?.clamp(0.0, screenWidth - 24.0).toDouble();
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          width: resolvedWidth,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColors = _MeFeatureTone.secondary.resolve(colorScheme);

    return Material(
      key: const ValueKey('me-feature-hcoin'),
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.monetization_on_outlined,
                      color: accentColors.foreground,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'H币',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const ValueKey('me-hcoin-refresh-button'),
                    onPressed: _isReceiving || _isRefreshing
                        ? null
                        : _handleRefreshTap,
                    tooltip: '刷新',
                    icon: _isRefreshing
                        ? SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '当前持有',
                key: const ValueKey('me-hcoin-balance-label'),
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _balanceDisplay,
                  key: ValueKey('me-hcoin-balance-$_balanceDisplay'),
                  style: textTheme.displaySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('me-hcoin-receive-button'),
                  onPressed: _isRefreshing || _isReceiving
                      ? null
                      : _handleReceiveTap,
                  icon: _isReceiving
                      ? SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: const Text('领取'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _MeFeatureItemData item;

  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColors = item.tone.resolve(colorScheme);

    return Material(
      key: ValueKey('me-feature-${item.key}'),
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: SizedBox(
            height: 124,
            child: Stack(
              children: [
                if (item.statusLabel != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _FeatureStatusChip(label: item.statusLabel!),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            item.icon,
                            color: accentColors.foreground,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureStatusChip extends StatelessWidget {
  final String label;

  const _FeatureStatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeaturePlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String statusLabel;
  final String description;
  final String? supportingText;

  const _FeaturePlaceholderPage({
    required this.title,
    required this.icon,
    required this.statusLabel,
    required this.description,
    this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.38),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        icon,
                        color: colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FeatureStatusChip(label: statusLabel),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                    if (supportingText != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.32,
                            ),
                          ),
                        ),
                        child: Text(
                          supportingText!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeFeatureItemData {
  final String key;
  final String title;
  final IconData icon;
  final String? statusLabel;
  final _MeFeatureTone tone;
  final VoidCallback? onTap;

  const _MeFeatureItemData({
    required this.key,
    required this.title,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.statusLabel,
  });
}

enum _MeFeatureTone { primary, secondary, tertiary, neutral, warning }

extension on _MeFeatureTone {
  _FeatureAccentColors resolve(ColorScheme colorScheme) {
    return switch (this) {
      _MeFeatureTone.primary => _FeatureAccentColors(
        foreground: colorScheme.primary,
        background: colorScheme.primaryContainer.withValues(alpha: 0.9),
      ),
      _MeFeatureTone.secondary => _FeatureAccentColors(
        foreground: colorScheme.secondary,
        background: colorScheme.secondaryContainer.withValues(alpha: 0.9),
      ),
      _MeFeatureTone.tertiary => _FeatureAccentColors(
        foreground: colorScheme.tertiary,
        background: colorScheme.tertiaryContainer.withValues(alpha: 0.9),
      ),
      _MeFeatureTone.warning => _FeatureAccentColors(
        foreground: colorScheme.error,
        background: colorScheme.errorContainer.withValues(alpha: 0.72),
      ),
      _MeFeatureTone.neutral => _FeatureAccentColors(
        foreground: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHighest,
      ),
    };
  }
}

class _FeatureAccentColors {
  final Color foreground;
  final Color background;

  const _FeatureAccentColors({
    required this.foreground,
    required this.background,
  });
}

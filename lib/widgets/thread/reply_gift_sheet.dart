import 'dart:async';
import 'dart:math' as math;

import 'package:bluefish/models/thread/single_reply_floor.dart';
import 'package:bluefish/models/thread/thread_gift.dart';
import 'package:bluefish/services/thread/thread_gift_service.dart';
import 'package:bluefish/utils/result.dart';
import 'package:flutter/material.dart';

typedef ReplyGiftTapCallback =
    Future<Result<String>> Function(SingleReplyFloor reply, ThreadGift gift);
typedef ReplyReceivedGiftListTapCallback =
    void Function(SingleReplyFloor reply);

const double _kReplyGiftSheetRecommendedHeightFactor = 0.28;
const double _kReplyGiftSheetMinHeightFactor = 0.25;
const double _kReplyGiftSheetMaxHeightFactor = 0.31;
const double _kReplyGiftGridRowSpacing = 8;
const BorderRadius _kReplyGiftTileBorderRadius = BorderRadius.all(
  Radius.circular(14),
);
const double _kReplyGiftTileIconScale = 0.72;
const double _kReplyGiftTileIconMinSize = 34;
const double _kReplyGiftTileIconMaxSize = 56;
const EdgeInsets _kReplyGiftFooterPadding = EdgeInsets.fromLTRB(16, 8, 16, 12);

Future<String?> showReplyGiftBottomSheetForReply({
  required BuildContext context,
  required SingleReplyFloor reply,
  required ThreadGiftService threadGiftService,
  String hCoinDisplay = '--',
  ReplyGiftTapCallback? onGiftTap,
  ReplyReceivedGiftListTapCallback? onViewReceivedGiftsTap,
}) async {
  final result = await threadGiftService.getThreadGifts();
  if (!context.mounted) {
    return null;
  }

  if (result is Failure<List<ThreadGift>>) {
    return result.message;
  }

  final gifts = result.dataOrNull ?? const <ThreadGift>[];
  if (gifts.isEmpty) {
    return '礼物列表暂时为空。';
  }

  final hCoinResult = await threadGiftService.getHcoin();
  if (!context.mounted) {
    return null;
  }

  var resolvedHCoinDisplay = hCoinDisplay;
  String? initialMessage;
  hCoinResult.when(
    success: (value) {
      resolvedHCoinDisplay = '$value';
    },
    failure: (message, exception) {
      if (message.trim().isNotEmpty) {
        initialMessage = message;
      }
    },
  );

  await showReplyGiftSheet(
    context: context,
    gifts: gifts,
    hCoinDisplay: resolvedHCoinDisplay,
    initialMessage: initialMessage,
    onGiftTap: onGiftTap == null ? null : (gift) => onGiftTap.call(reply, gift),
    onRefreshHCoin: ({bool forceRefresh = false}) {
      return threadGiftService.getHcoin(forceRefresh: forceRefresh);
    },
    onViewReceivedGiftsTap: () => onViewReceivedGiftsTap?.call(reply),
  );
  return null;
}

Future<void> showReplyGiftSheet({
  required BuildContext context,
  required List<ThreadGift> gifts,
  String hCoinDisplay = '--',
  String? initialMessage,
  Future<Result<String>> Function(ThreadGift gift)? onGiftTap,
  Future<Result<int>> Function({bool forceRefresh})? onRefreshHCoin,
  VoidCallback? onViewReceivedGiftsTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return _ReplyGiftSheet(
        gifts: gifts,
        hCoinDisplay: hCoinDisplay,
        initialMessage: initialMessage,
        onGiftTap: onGiftTap,
        onRefreshHCoin: onRefreshHCoin,
        onViewReceivedGiftsTap: onViewReceivedGiftsTap,
      );
    },
  );
}

class _ReplyGiftSheet extends StatefulWidget {
  final List<ThreadGift> gifts;
  final String hCoinDisplay;
  final String? initialMessage;
  final Future<Result<String>> Function(ThreadGift gift)? onGiftTap;
  final Future<Result<int>> Function({bool forceRefresh})? onRefreshHCoin;
  final VoidCallback? onViewReceivedGiftsTap;

  const _ReplyGiftSheet({
    required this.gifts,
    required this.hCoinDisplay,
    required this.initialMessage,
    required this.onGiftTap,
    required this.onRefreshHCoin,
    required this.onViewReceivedGiftsTap,
  });

  @override
  State<_ReplyGiftSheet> createState() => _ReplyGiftSheetState();
}

class _ReplyGiftSheetState extends State<_ReplyGiftSheet> {
  static const Duration _statusWidgetDisplayDuration = Duration(
    milliseconds: 1600,
  );

  late String _hCoinDisplay;
  bool _isGiftActionRunning = false;
  bool _initialMessageShown = false;
  Timer? _statusWidgetTimer;
  _GiftStatusState? _statusState;

  @override
  void initState() {
    super.initState();
    _hCoinDisplay = widget.hCoinDisplay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialMessageIfNeeded();
    });
  }

  void _showInitialMessageIfNeeded() {
    if (!mounted || _initialMessageShown) {
      return;
    }

    final message = widget.initialMessage?.trim();
    if (message == null || message.isEmpty) {
      return;
    }

    _initialMessageShown = true;
    _showStatusWidget(message, tone: _GiftStatusTone.error);
  }

  void _showStatusWidget(String message, {required _GiftStatusTone tone}) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return;
    }

    _statusWidgetTimer?.cancel();

    setState(() {
      _statusState = _GiftStatusState(message: normalized, tone: tone);
    });

    _statusWidgetTimer = Timer(_statusWidgetDisplayDuration, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusState = null;
      });
    });
  }

  @override
  void dispose() {
    _statusWidgetTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleGiftTap(ThreadGift gift) async {
    final onGiftTap = widget.onGiftTap;
    if (onGiftTap == null || _isGiftActionRunning) {
      return;
    }

    setState(() {
      _isGiftActionRunning = true;
    });

    try {
      final actionResult = await onGiftTap(gift);
      if (!mounted) {
        return;
      }

      String? successMessage;
      String? failureMessage;
      actionResult.when(
        success: (message) {
          final normalizedMessage = message.trim();
          successMessage = normalizedMessage.isEmpty
              ? '投币成功'
              : normalizedMessage;
        },
        failure: (message, exception) {
          failureMessage = message;
        },
      );

      if (failureMessage != null && failureMessage!.trim().isNotEmpty) {
        _showStatusWidget(failureMessage!, tone: _GiftStatusTone.error);
        return;
      }

      if (successMessage != null) {
        _showStatusWidget(successMessage!, tone: _GiftStatusTone.success);
      }

      final onRefreshHCoin = widget.onRefreshHCoin;
      if (onRefreshHCoin == null) {
        return;
      }

      final hCoinResult = await onRefreshHCoin(forceRefresh: true);
      if (!mounted) {
        return;
      }

      hCoinResult.when(
        success: (value) {
          setState(() {
            _hCoinDisplay = '$value';
          });
        },
        failure: (message, exception) {
          if (message.trim().isNotEmpty) {
            _showStatusWidget(message, tone: _GiftStatusTone.error);
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGiftActionRunning = false;
        });
      }
    }
  }

  Future<void> _handleViewReceivedGiftsTap() async {
    final onViewReceivedGiftsTap = widget.onViewReceivedGiftsTap;
    if (onViewReceivedGiftsTap == null) {
      return;
    }

    final navigator = Navigator.of(context);
    await navigator.maybePop();
    onViewReceivedGiftsTap();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final recommendedHeight =
            availableHeight * _kReplyGiftSheetRecommendedHeightFactor;
        final minHeight = availableHeight * _kReplyGiftSheetMinHeightFactor;
        final maxHeight = availableHeight * _kReplyGiftSheetMaxHeightFactor;
        final sheetHeight = recommendedHeight
            .clamp(minHeight, maxHeight)
            .toDouble();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).maybePop(),
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SizedBox(
                    height: sheetHeight,
                    child: _ReplyGiftSheetSurface(
                      gifts: widget.gifts,
                      hCoinDisplay: _hCoinDisplay,
                      statusState: _statusState,
                      onGiftTap: _handleGiftTap,
                      isGiftActionRunning: _isGiftActionRunning,
                      onViewReceivedGiftsTap:
                          widget.onViewReceivedGiftsTap == null
                          ? null
                          : () {
                              unawaited(_handleViewReceivedGiftsTap());
                            },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReplyGiftSheetSurface extends StatelessWidget {
  final List<ThreadGift> gifts;
  final String hCoinDisplay;
  final _GiftStatusState? statusState;
  final Future<void> Function(ThreadGift gift)? onGiftTap;
  final bool isGiftActionRunning;
  final VoidCallback? onViewReceivedGiftsTap;

  const _ReplyGiftSheetSurface({
    required this.gifts,
    required this.hCoinDisplay,
    required this.statusState,
    required this.onGiftTap,
    required this.isGiftActionRunning,
    required this.onViewReceivedGiftsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      key: const ValueKey('reply-gift-sheet'),
      color: colorScheme.surfaceContainerLow,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(-0.08, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: statusState == null
                            ? const SizedBox(
                                key: ValueKey('reply-gift-status-empty'),
                              )
                            : _GiftStatusBadge(
                                key: ValueKey(
                                  'reply-gift-status-${statusState!.tone.name}',
                                ),
                                statusState: statusState!,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HCoinPill(hCoinDisplay: hCoinDisplay),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ReplyGiftGrid(
                  gifts: gifts,
                  onGiftTap: onGiftTap,
                  isGiftActionRunning: isGiftActionRunning,
                ),
              ),
            ),
            Padding(
              padding: _kReplyGiftFooterPadding,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: const ValueKey('reply-gift-view-received-button'),
                  onPressed: onViewReceivedGiftsTap ?? () {},
                  icon: const Icon(Icons.card_giftcard_rounded),
                  label: const Text('查看该回复收到的所有礼物'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _GiftStatusTone { success, error }

class _GiftStatusState {
  final String message;
  final _GiftStatusTone tone;

  const _GiftStatusState({required this.message, required this.tone});
}

class _GiftStatusBadge extends StatelessWidget {
  final _GiftStatusState statusState;

  const _GiftStatusBadge({super.key, required this.statusState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSuccess = statusState.tone == _GiftStatusTone.success;
    final backgroundColor = isSuccess
        ? colorScheme.tertiaryContainer
        : colorScheme.errorContainer;
    final foregroundColor = isSuccess
        ? colorScheme.onTertiaryContainer
        : colorScheme.onErrorContainer;
    final borderColor = (isSuccess ? colorScheme.tertiary : colorScheme.error)
        .withValues(alpha: 0.24);

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            size: 16,
            color: foregroundColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              statusState.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HCoinPill extends StatelessWidget {
  final String hCoinDisplay;

  const _HCoinPill({required this.hCoinDisplay});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: '当前持有的 H 币',
      child: Container(
        key: const ValueKey('reply-gift-hcoin-pill'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on_outlined,
              size: 16,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              '持有 H币 $hCoinDisplay',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyGiftGrid extends StatelessWidget {
  final List<ThreadGift> gifts;
  final Future<void> Function(ThreadGift gift)? onGiftTap;
  final bool isGiftActionRunning;

  const _ReplyGiftGrid({
    required this.gifts,
    required this.onGiftTap,
    required this.isGiftActionRunning,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = math.max(1, (gifts.length / 2).ceil());
    final firstRowCount = math.min(columnCount, gifts.length);
    final firstRowGifts = gifts.take(firstRowCount).toList(growable: false);
    final secondRowGifts = gifts.skip(firstRowCount).toList(growable: false);

    return Column(
      children: [
        Expanded(
          child: _ReplyGiftRow(
            rowGifts: firstRowGifts,
            columnCount: columnCount,
            onGiftTap: onGiftTap,
            isGiftActionRunning: isGiftActionRunning,
          ),
        ),
        const SizedBox(height: _kReplyGiftGridRowSpacing),
        Expanded(
          child: _ReplyGiftRow(
            rowGifts: secondRowGifts,
            columnCount: columnCount,
            onGiftTap: onGiftTap,
            isGiftActionRunning: isGiftActionRunning,
          ),
        ),
      ],
    );
  }
}

class _ReplyGiftRow extends StatelessWidget {
  final List<ThreadGift> rowGifts;
  final int columnCount;
  final Future<void> Function(ThreadGift gift)? onGiftTap;
  final bool isGiftActionRunning;

  const _ReplyGiftRow({
    required this.rowGifts,
    required this.columnCount,
    required this.onGiftTap,
    required this.isGiftActionRunning,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var index = 0; index < columnCount; index++) {
      if (index > 0) {
        children.add(const SizedBox(width: 8));
      }

      final ThreadGift? gift = index < rowGifts.length ? rowGifts[index] : null;
      children.add(
        Expanded(
          child: gift == null
              ? const SizedBox.expand()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final tileSize = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    if (tileSize <= 0) {
                      return const SizedBox.shrink();
                    }

                    return Center(
                      child: SizedBox.square(
                        dimension: tileSize,
                        child: _ReplyGiftTile(
                          gift: gift,
                          isBusy: isGiftActionRunning,
                          onTap: onGiftTap == null || isGiftActionRunning
                              ? null
                              : () {
                                  unawaited(onGiftTap!.call(gift));
                                },
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _ReplyGiftTile extends StatelessWidget {
  final ThreadGift gift;
  final VoidCallback? onTap;
  final bool isBusy;

  const _ReplyGiftTile({
    required this.gift,
    required this.onTap,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: '礼物 ${gift.giftId}',
      child: Material(
        key: ValueKey('reply-gift-item-${gift.giftId}'),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: _kReplyGiftTileBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconSize =
                  (constraints.biggest.shortestSide * _kReplyGiftTileIconScale)
                      .clamp(
                        _kReplyGiftTileIconMinSize,
                        _kReplyGiftTileIconMaxSize,
                      );

              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: SizedBox(
                      key: ValueKey('reply-gift-icon-${gift.giftId}'),
                      width: iconSize,
                      height: iconSize,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          gift.iconUrl,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.card_giftcard_rounded,
                              color: colorScheme.onSurfaceVariant,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (isBusy)
                    Container(
                      color: colorScheme.surface.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

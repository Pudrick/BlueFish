import 'package:bluefish/viewModels/user_home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserHomeDisplaySelectWidget extends StatelessWidget {
  static const double preferredHeight = 48;

  static const _options = <_UserHomeDisplayOptionData>[
    _UserHomeDisplayOptionData(
      value: DisplayStatus.threads,
      label: '主贴',
      icon: Icons.forum_outlined,
    ),
    _UserHomeDisplayOptionData(
      value: DisplayStatus.replies,
      label: '回复',
      icon: Icons.reply_rounded,
    ),
    _UserHomeDisplayOptionData(
      value: DisplayStatus.recommends,
      label: '推荐',
      icon: Icons.recommend_outlined,
    ),
  ];

  final VoidCallback? onTabChanged;

  const UserHomeDisplaySelectWidget({super.key, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserHomeViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (var i = 0; i < _options.length; i++) ...[
                Expanded(
                  child: _UserHomeDisplayOption(
                    label: _options[i].label,
                    icon: _options[i].icon,
                    selected: vm.displayStatus == _options[i].value,
                    onTap: () {
                      if (vm.displayStatus != _options[i].value) {
                        vm.changeDisplayTo(_options[i].value);
                        onTabChanged?.call();
                      }
                    },
                  ),
                ),
                if (i != _options.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserHomeDisplayOptionData {
  final DisplayStatus value;
  final String label;
  final IconData icon;

  const _UserHomeDisplayOptionData({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class _UserHomeDisplayOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _UserHomeDisplayOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foregroundColor = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: foregroundColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

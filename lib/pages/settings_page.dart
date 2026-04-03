import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/pages/about_page.dart';
import 'package:bluefish/pages/debug_cookie_page.dart';
import 'package:bluefish/userdata/theme_settings.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<int> _seedColors = <int>[
    0xFF0B6E4F,
    0xFF005B99,
    0xFF8E4B10,
    0xFF7A1F3D,
    0xFF5A3E9E,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettingsViewModel, AuthSessionManager>(
      builder: (context, settingsViewModel, authSessionManager, _) {
        final settings = settingsViewModel.settings;

        return Scaffold(
          appBar: AppBar(title: const Text('设置')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SettingsSection(
                title: '外观',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主题模式',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AppThemePreference>(
                      showSelectedIcon: false,
                      segments: [
                        for (final preference in AppThemePreference.values)
                          ButtonSegment<AppThemePreference>(
                            value: preference,
                            label: Text(preference.label),
                          ),
                      ],
                      selected: <AppThemePreference>{settings.themePreference},
                      onSelectionChanged: (selection) {
                        settingsViewModel.updateThemePreference(
                          selection.first,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '主题色',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final colorValue in _seedColors)
                          _ThemeColorChip(
                            colorValue: colorValue,
                            selected: settings.seedColorValue == colorValue,
                            onTap: () {
                              settingsViewModel.updateSeedColor(colorValue);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: '字号',
                child: Column(
                  children: [
                    _FontScaleSlider(
                      icon: Icons.subject_rounded,
                      label: '正文字号',
                      value: settings.contentFontScale,
                      onChanged: settingsViewModel.updateContentFontScale,
                    ),
                    const SizedBox(height: 12),
                    _FontScaleSlider(
                      icon: Icons.title_rounded,
                      label: '标题字号',
                      value: settings.titleFontScale,
                      onChanged: settingsViewModel.updateTitleFontScale,
                    ),
                    const SizedBox(height: 12),
                    _FontScaleSlider(
                      icon: Icons.sell_outlined,
                      label: '辅助字号',
                      value: settings.metaFontScale,
                      onChanged: settingsViewModel.updateMetaFontScale,
                    ),
                    const SizedBox(height: 16),
                    _TextPreviewCard(settings: settings),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: '关于',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('关于 BlueFish'),
                      subtitle: const Text('查看 App 版本、包名和开源许可'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: const Text('恢复默认外观设置'),
                      subtitle: const Text('重置主题模式、主题色和字号缩放'),
                      onTap: settingsViewModel.reset,
                    ),
                  ],
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                _SettingsSection(
                  title: '开发测试',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cookie_outlined),
                    title: const Text('调试 Cookie'),
                    subtitle: Text(
                      '当前来源：${authSessionManager.activeSource.label}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const DebugCookiePage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThemeColorChip extends StatelessWidget {
  final int colorValue;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeColorChip({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? color : color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                selected ? '已选' : '选择',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontScaleSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _FontScaleSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text('${value.toStringAsFixed(2)}x'),
          ],
        ),
        Slider(
          value: value,
          min: AppSettings.minFontScale,
          max: AppSettings.maxFontScale,
          divisions: 10,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TextPreviewCard extends StatelessWidget {
  final AppSettings settings;

  const _TextPreviewCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final inheritedTheme = Theme.of(context);
    final previewTheme = buildAppTheme(
      settings,
      brightness: inheritedTheme.brightness,
    );
    final colorScheme = previewTheme.colorScheme;

    return Theme(
      data: previewTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '字号预览',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '这是正文示例，用来判断当前阅读密度是否舒服。',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '辅助信息 · 2 分钟前 · 来自设置预览',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '正文 ${settings.contentFontScale.toStringAsFixed(2)}x · '
                  '标题 ${settings.titleFontScale.toStringAsFixed(2)}x · '
                  '辅助 ${settings.metaFontScale.toStringAsFixed(2)}x',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

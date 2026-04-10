import 'dart:math' as math;

import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:bluefish/auth/web_login_session_service.dart';
import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/pages/settings/about_page.dart';
import 'package:bluefish/pages/settings/debug_cookie_page.dart';
import 'package:bluefish/router/app_routes.dart';
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

  Future<void> _confirmAndOpenAdvancedSettings(BuildContext context) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('打开高级设置'),
          content: const Text('通常不需要手动修改这些设置，除非你知道这是什么。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );

    if (shouldContinue == true && context.mounted) {
      context.pushAdvancedSettings();
    }
  }

  Future<void> _confirmAndLogout(
    BuildContext context,
    AuthSessionManager authSessionManager,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('这会清除应用保存的登录会话和内嵌网页登录 Cookie。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('退出登录'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      await WebLoginCookieStore().clearAllCookies();
      await authSessionManager.clearLoginCookies();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('已退出登录。')));
    } catch (_) {
      await authSessionManager.clearLoginCookies();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('已清除应用会话，内嵌网页登录态可能仍需手动刷新。')),
        );
    }
  }

  Future<void> _openMediaSaveDirectoryDialog(
    BuildContext context, {
    required AppSettingsViewModel settingsViewModel,
    required bool isImage,
  }) async {
    final submittedValue = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return _MediaSaveDirectoryDialog(
          title: isImage ? '图片默认保存位置' : '视频默认保存位置',
          initialValue: isImage
              ? settingsViewModel.settings.imageSaveDirectoryPath
              : settingsViewModel.settings.videoSaveDirectoryPath,
          helperText: '留空时使用默认下载目录。当前版本可直接输入目标目录路径。',
        );
      },
    );

    if (submittedValue == null) {
      return;
    }

    if (isImage) {
      await settingsViewModel.updateImageSaveDirectoryPath(submittedValue);
    } else {
      await settingsViewModel.updateVideoSaveDirectoryPath(submittedValue);
    }
  }

  String _mediaSaveDirectorySummary(String? path) {
    if (path == null || path.isEmpty) {
      return '默认下载目录';
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettingsViewModel, AuthSessionManager>(
      builder: (context, settingsViewModel, authSessionManager, _) {
        final settings = settingsViewModel.settings;
        final imageShrinkTargetSliderMax = math.min(
          AppSettings.maxImageShrinkTargetMaxEdgeDp,
          settings.imageShrinkTriggerMaxEdgeDp,
        );

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
                    _ThemeModeSelector(
                      value: settings.themePreference,
                      onChanged: settingsViewModel.updateThemePreference,
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
                title: '图片',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '控制 HTML 大图初始缩小策略。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ImageEdgeSlider(
                      icon: Icons.photo_size_select_large_rounded,
                      label: '大图触发最长边',
                      helperText: '超过此值时，图片会先按比例缩小显示。',
                      value: settings.imageShrinkTriggerMaxEdgeDp,
                      min: AppSettings.minImageShrinkTriggerMaxEdgeDp,
                      max: AppSettings.maxImageShrinkTriggerMaxEdgeDp,
                      onChanged:
                          settingsViewModel.updateImageShrinkTriggerMaxEdgeDp,
                    ),
                    const SizedBox(height: 12),
                    _ImageEdgeSlider(
                      icon: Icons.fit_screen_rounded,
                      label: '缩小后最长边',
                      helperText: '首次点击图片会还原到未缩小时的尺寸。',
                      value: settings.imageShrinkTargetMaxEdgeDp,
                      min: AppSettings.minImageShrinkTargetMaxEdgeDp,
                      max: imageShrinkTargetSliderMax,
                      onChanged:
                          settingsViewModel.updateImageShrinkTargetMaxEdgeDp,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '默认值：触发 640dp，目标 360dp。',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: '保存',
                child: Column(
                  children: [
                    _SettingsActionTile(
                      leading: const Icon(Icons.image_outlined),
                      title: const Text('图片默认保存位置'),
                      subtitle: Text(
                        _mediaSaveDirectorySummary(
                          settings.imageSaveDirectoryPath,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        _openMediaSaveDirectoryDialog(
                          context,
                          settingsViewModel: settingsViewModel,
                          isImage: true,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _SettingsActionTile(
                      leading: const Icon(Icons.video_library_outlined),
                      title: const Text('视频默认保存位置'),
                      subtitle: Text(
                        _mediaSaveDirectorySummary(
                          settings.videoSaveDirectoryPath,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        _openMediaSaveDirectoryDialog(
                          context,
                          settingsViewModel: settingsViewModel,
                          isImage: false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: '关于',
                child: Column(
                  children: [
                    _SettingsActionTile(
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
                    _SettingsActionTile(
                      leading: const Icon(Icons.tune_rounded),
                      title: const Text('高级设置'),
                      subtitle: const Text('通常来说不需要手动更改'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        _confirmAndOpenAdvancedSettings(context);
                      },
                    ),
                    _SettingsActionTile(
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: const Text('恢复默认设置'),
                      subtitle: const Text('重置外观、字号缩放、保存位置和高级设置'),
                      onTap: settingsViewModel.reset,
                    ),
                  ],
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                _SettingsSection(
                  title: '开发测试',
                  child: _SettingsActionTile(
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
              if (authSessionManager.isLoggedIn) ...[
                const SizedBox(height: 16),
                _SettingsSection(
                  title: '账户',
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        _confirmAndLogout(context, authSessionManager);
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('退出登录'),
                    ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
            child: child,
          ),
        ),
        Positioned(
          left: 18,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            color: theme.scaffoldBackgroundColor,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final AppThemePreference value;
  final ValueChanged<AppThemePreference> onChanged;

  const _ThemeModeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (var i = 0; i < AppThemePreference.values.length; i++) ...[
                  Expanded(
                    child: _ThemeModeOption(
                      label: AppThemePreference.values[i].label,
                      selected: AppThemePreference.values[i] == value,
                      onTap: () => onChanged(AppThemePreference.values[i]),
                    ),
                  ),
                  if (i != AppThemePreference.values.length - 1)
                    const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsActionTile({
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );

    return Material(
      color: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        shape: shape,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
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
    final textTheme = previewTheme.textTheme;

    return Container(
      key: ValueKey<String>(
        [
          settings.contentFontScale.toStringAsFixed(2),
          settings.titleFontScale.toStringAsFixed(2),
          settings.metaFontScale.toStringAsFixed(2),
        ].join('-'),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '字号设置预览',
              key: const ValueKey('settings-preview-tag'),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '这是一条标题示例',
            key: const ValueKey('settings-preview-title'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '这是正文示例，用来判断当前阅读密度是否舒服，也能直接观察正文字号是否跟随上方设置实时变化。',
            key: const ValueKey('settings-preview-body'),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '辅助信息 · 2 分钟前 · 来自设置预览',
            key: const ValueKey('settings-preview-meta'),
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewScaleChip(
                label: '正文',
                value: settings.contentFontScale,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _PreviewScaleChip(
                label: '标题',
                value: settings.titleFontScale,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _PreviewScaleChip(
                label: '辅助',
                value: settings.metaFontScale,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageEdgeSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final String helperText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _ImageEdgeSlider({
    required this.icon,
    required this.label,
    required this.helperText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(min, max).toDouble();
    final divisions = ((max - min) / 10).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text('${safeValue.toStringAsFixed(0)}dp'),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          helperText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Slider(
          value: safeValue,
          min: min,
          max: max,
          divisions: divisions > 0 ? divisions : null,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PreviewScaleChip extends StatelessWidget {
  final String label;
  final double value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _PreviewScaleChip({
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(2)}x',
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MediaSaveDirectoryDialog extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String helperText;

  const _MediaSaveDirectoryDialog({
    required this.title,
    required this.initialValue,
    required this.helperText,
  });

  @override
  State<_MediaSaveDirectoryDialog> createState() =>
      _MediaSaveDirectoryDialogState();
}

class _MediaSaveDirectoryDialogState extends State<_MediaSaveDirectoryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.helperText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '目录路径',
                  hintText: r'C:\Users\Example\Downloads',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('使用默认'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

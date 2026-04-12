import 'package:bluefish/network/api_config.dart';
import 'package:bluefish/models/app_settings.dart';
import 'package:bluefish/services/thread/reply_page_locator_log_sink.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

  Future<void> _clearReplyLocateCacheBeforeDate(
    BuildContext context,
    AppSettingsViewModel settingsViewModel,
  ) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: '选择清理截止日期',
    );

    if (selectedDate == null || !context.mounted) {
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('清除指定日期前缓存'),
          content: Text(
            '将清除 ${selectedDate.toLocal().toString().split(' ').first} 之前的回复定位缓存。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('清除'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) {
      return;
    }

    final removedCount = await settingsViewModel.clearReplyLocateCacheBefore(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
    );
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已清理 $removedCount 条回复定位缓存。')));
  }

  Future<void> _clearAllReplyLocateCache(
    BuildContext context,
    AppSettingsViewModel settingsViewModel,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('清除所有回复定位缓存'),
          content: const Text('该操作会删除所有已保存的回复定位缓存。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('清除全部'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) {
      return;
    }

    await settingsViewModel.clearAllReplyLocateCache();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('已清除所有回复定位缓存。')));
  }

  Future<void> _openApiVersionOverrideDialog(
    BuildContext context,
    AppSettingsViewModel settingsViewModel,
  ) async {
    final submittedValue = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return _ApiVersionOverrideDialog(
          initialValue: settingsViewModel.settings.apiVersionOverride,
        );
      },
    );

    if (submittedValue == null) {
      return;
    }

    await settingsViewModel.updateApiVersionOverride(submittedValue);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsViewModel>(
      builder: (context, settingsViewModel, _) {
        final settings = settingsViewModel.settings;

        return Scaffold(
          appBar: AppBar(title: const Text('高级设置')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '通常不需要手动修改这些设置，除非你知道这是什么。',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('API 请求版本号'),
                  subtitle: Text(
                    settings.apiVersionOverride == null
                        ? '当前使用默认 API 版本片段：${ApiConfig.apiVersion}'
                        : '当前自定义 API 版本片段：${settings.apiVersionOverride}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _openApiVersionOverrideDialog(context, settingsViewModel);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '回复定位总探测预算',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${settings.replyLocateTotalProbeBudget}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '控制单次跳转前最多探测的帖子页数。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Slider(
                        value: settings.replyLocateTotalProbeBudget.toDouble(),
                        min: AppSettings.minReplyLocateTotalProbeBudget
                            .toDouble(),
                        max: AppSettings.maxReplyLocateTotalProbeBudget
                            .toDouble(),
                        divisions:
                            AppSettings.maxReplyLocateTotalProbeBudget -
                            AppSettings.minReplyLocateTotalProbeBudget,
                        onChanged: (value) {
                          settingsViewModel.updateReplyLocateTotalProbeBudget(
                            value.round(),
                          );
                        },
                      ),
                      Text(
                        '默认值：${AppSettings.defaultReplyLocateTotalProbeBudget}。',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.linear_scale_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '回复定位粗探步长',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${settings.replyLocateCoarseProbeStride}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '控制粗探阶段每次探测的页数间隔。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Slider(
                        value: settings.replyLocateCoarseProbeStride.toDouble(),
                        min: AppSettings.minReplyLocateCoarseProbeStride
                            .toDouble(),
                        max: AppSettings.maxReplyLocateCoarseProbeStride
                            .toDouble(),
                        divisions:
                            ((AppSettings.maxReplyLocateCoarseProbeStride -
                                        AppSettings
                                            .minReplyLocateCoarseProbeStride) /
                                    10)
                                .round(),
                        onChanged: (value) {
                          final rounded = ((value / 10).round() * 10)
                              .clamp(
                                AppSettings.minReplyLocateCoarseProbeStride,
                                AppSettings.maxReplyLocateCoarseProbeStride,
                              )
                              .toInt();
                          settingsViewModel.updateReplyLocateCoarseProbeStride(
                            rounded,
                          );
                        },
                      ),
                      Text(
                        '默认值：${AppSettings.defaultReplyLocateCoarseProbeStride}。',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storage_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '回复定位缓存上限',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${settings.replyLocateCacheMaxEntries}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '控制最多保留多少条回复定位缓存记录。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Slider(
                        value: settings.replyLocateCacheMaxEntries.toDouble(),
                        min: AppSettings.minReplyLocateCacheMaxEntries
                            .toDouble(),
                        max: AppSettings.maxReplyLocateCacheMaxEntries
                            .toDouble(),
                        divisions:
                            ((AppSettings.maxReplyLocateCacheMaxEntries -
                                        AppSettings
                                            .minReplyLocateCacheMaxEntries) /
                                    64)
                                .round(),
                        onChanged: (value) {
                          final rounded = ((value / 64).round() * 64)
                              .clamp(
                                AppSettings.minReplyLocateCacheMaxEntries,
                                AppSettings.maxReplyLocateCacheMaxEntries,
                              )
                              .toInt();
                          settingsViewModel.updateReplyLocateCacheMaxEntries(
                            rounded,
                          );
                        },
                      ),
                      Text(
                        '默认值：${AppSettings.defaultReplyLocateCacheMaxEntries}。',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.thumb_up_alt_outlined),
                      title: const Text('自动探测主贴推荐状态'),
                      subtitle: const Text(
                        '开启后帖子页会切换到自动探测模式。当前仅保留入口，实际探测流程待接入。',
                      ),
                      value: settings.autoProbeThreadRecommendStatus,
                      onChanged: (value) {
                        settingsViewModel.updateAutoProbeThreadRecommendStatus(
                          value,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.receipt_long_rounded),
                      title: const Text('生成跳转日志'),
                      subtitle: const Text('记录回复跳转到详情页时的定位计算过程。'),
                      value: settings.generateJumpLogs,
                      onChanged: (value) {
                        settingsViewModel.updateGenerateJumpLogs(value);
                      },
                    ),
                    if (settings.generateJumpLogs) ...[
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.folder_open_rounded),
                        title: Text('跳转日志保存目录'),
                        subtitle: Text(
                          '当前项目/${ReplyPageLocatorLogSink.defaultRelativeDirectory}/${ReplyPageLocatorLogSink.defaultFileName}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_rounded),
                      title: const Text('清除指定日期前的回复定位缓存'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        _clearReplyLocateCacheBeforeDate(
                          context,
                          settingsViewModel,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_rounded),
                      title: const Text('清除所有回复定位缓存'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        _clearAllReplyLocateCache(context, settingsViewModel);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ApiVersionOverrideDialog extends StatefulWidget {
  final String? initialValue;

  const _ApiVersionOverrideDialog({this.initialValue});

  @override
  State<_ApiVersionOverrideDialog> createState() =>
      _ApiVersionOverrideDialogState();
}

class _ApiVersionOverrideDialogState extends State<_ApiVersionOverrideDialog> {
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
      title: const Text('API 请求版本号'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '请输入 API URL 中的 APP 版本号片段。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'API 请求版本号',
                  hintText: ApiConfig.defaultApiVersion,
                  helperText: '留空会恢复默认值',
                  border: const OutlineInputBorder(),
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
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

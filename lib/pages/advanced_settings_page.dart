import 'package:bluefish/network/api_config.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

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

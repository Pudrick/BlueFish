import 'package:bluefish/auth/auth_session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DebugCookiePage extends StatefulWidget {
  const DebugCookiePage({super.key});

  @override
  State<DebugCookiePage> createState() => _DebugCookiePageState();
}

class _DebugCookiePageState extends State<DebugCookiePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sessionManager = context.read<AuthSessionManager>();
    if (_controller.text.isEmpty) {
      _controller.text = sessionManager.debugOverrideCookies ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveDebugOverride(AuthSessionManager sessionManager) async {
    await sessionManager.saveDebugOverrideCookies(_controller.text);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('调试 Cookie 已保存')));
  }

  Future<void> _clearDebugOverride(AuthSessionManager sessionManager) async {
    await sessionManager.clearDebugOverrideCookies();
    _controller.clear();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已清除本地调试 Cookie')));
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('调试 Cookie')),
        body: const Center(child: Text('当前不是 Debug 构建，调试 Cookie 面板已禁用。')),
      );
    }

    return Consumer<AuthSessionManager>(
      builder: (context, sessionManager, _) {
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(title: const Text('调试 Cookie')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '推荐用法',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '开发测试时可以临时粘贴 Cookie，或者用 '
                      '--dart-define=$debugCookieDefineName=... 启动；这样就不用把真实 Cookie 写进源码。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前来源：${sessionManager.activeSource.label}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controller,
                        minLines: 6,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          labelText: '本地调试 Cookie',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: sessionManager.canUseDebugOverride
                                ? () => _saveDebugOverride(sessionManager)
                                : null,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('保存本地覆盖'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: sessionManager.canUseDebugOverride
                                ? () => _clearDebugOverride(sessionManager)
                                : null,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('清除本地覆盖'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

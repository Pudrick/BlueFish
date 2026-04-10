import 'dart:async';

import 'package:bluefish/services/media/media_save_service.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class ThreadInlineVideoWidget extends StatefulWidget {
  final String? videoUrl;
  final String? coverUrl;
  final Key? sectionKey;
  final Key? playButtonKey;
  final MediaSaveService? mediaSaveService;

  const ThreadInlineVideoWidget({
    super.key,
    required this.videoUrl,
    required this.coverUrl,
    this.sectionKey = const ValueKey('thread-main-video-section'),
    this.playButtonKey = const ValueKey('thread-main-video-play'),
    this.mediaSaveService,
  });

  @override
  State<ThreadInlineVideoWidget> createState() =>
      _ThreadInlineVideoWidgetState();
}

class _ThreadInlineVideoWidgetState extends State<ThreadInlineVideoWidget> {
  MediaSaveService get _mediaSaveService =>
      widget.mediaSaveService ?? context.read<MediaSaveService>();

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void didUpdateWidget(covariant ThreadInlineVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _isInitializing = false;
      _isSaving = false;
      _errorMessage = null;
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _startPlayback() async {
    if (_isInitializing ||
        _chewieController != null ||
        widget.videoUrl == null) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final uri = Uri.tryParse(widget.videoUrl!);
    if (uri == null) {
      setState(() {
        _errorMessage = '视频地址无效';
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final videoController = VideoPlayerController.networkUrl(uri);

    try {
      await videoController.initialize();

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        allowMuting: true,
        showControlsOnInitialize: true,
        additionalOptions: (context) => <OptionItem>[
          OptionItem(
            onTap: (_) => unawaited(_saveVideo()),
            iconData: _isSaving
                ? Icons.downloading_rounded
                : Icons.download_rounded,
            title: _isSaving ? '正在保存至本地' : '保存至本地',
            subtitle: _resolveSaveDestinationSummary(context),
          ),
        ],
        optionsBuilder: _showVideoOptionsSheet,
        materialProgressColors: ChewieProgressColors(
          playedColor: colorScheme.primary,
          handleColor: colorScheme.primary,
          bufferedColor: colorScheme.primary.withValues(alpha: 0.35),
          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.18),
        ),
      );

      if (!mounted) {
        chewieController.dispose();
        videoController.dispose();
        return;
      }

      setState(() {
        _videoController = videoController;
        _chewieController = chewieController;
        _isInitializing = false;
      });
    } catch (_) {
      await videoController.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage = '视频加载失败，请重试';
      });
    }
  }

  Future<void> _saveVideo() async {
    if (_isSaving || widget.videoUrl == null) {
      return;
    }

    final settings = context.read<AppSettingsViewModel>().settings;
    setState(() {
      _isSaving = true;
    });

    try {
      final savedFile = await _mediaSaveService.saveVideo(
        url: widget.videoUrl!,
        preferredDirectoryPath: settings.videoSaveDirectoryPath,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('已保存至 ${savedFile.path}');
    } on MediaSaveException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('保存视频失败，请稍后重试。');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showVideoOptionsSheet(
    BuildContext context,
    List<OptionItem> options,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final selectedOption = await showModalBottomSheet<OptionItem>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '视频操作',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final option in options)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _VideoOptionTile(
                              icon: option.iconData,
                              title: option.title,
                              subtitle: option.subtitle,
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(option),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!context.mounted || selectedOption == null) {
      return;
    }

    selectedOption.onTap(context);
  }

  String _resolveSaveDestinationSummary(BuildContext context) {
    final configuredPath = context
        .read<AppSettingsViewModel>()
        .settings
        .videoSaveDirectoryPath;
    if (configuredPath == null || configuredPath.isEmpty) {
      return '默认下载目录';
    }

    return configuredPath;
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool hasVideoUrl = widget.videoUrl != null;
    final bool isReady = _chewieController != null;
    final double aspectRatio = _resolvedAspectRatio();

    return Container(
      key: widget.sectionKey,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: isReady
                ? Chewie(controller: _chewieController!)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _VideoPoster(coverUrl: widget.coverUrl),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: _VideoPosterAction(
                          key: widget.playButtonKey,
                          isLoading: _isInitializing,
                          hasVideoUrl: hasVideoUrl,
                          onPressed: hasVideoUrl ? _startPlayback : null,
                        ),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage ?? (hasVideoUrl ? '点击播放视频' : '暂未获取到可播放的视频地址'),
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _resolvedAspectRatio() {
    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      final ratio = controller.value.aspectRatio;
      if (ratio > 0) {
        return ratio;
      }
    }
    return 16 / 9;
  }
}

class _VideoPoster extends StatelessWidget {
  final String? coverUrl;

  const _VideoPoster({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (coverUrl == null) {
      return ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.videocam_outlined,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      coverUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

class _VideoPosterAction extends StatelessWidget {
  final bool isLoading;
  final bool hasVideoUrl;
  final VoidCallback? onPressed;

  const _VideoPosterAction({
    super.key,
    required this.isLoading,
    required this.hasVideoUrl,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.36),
          shape: BoxShape.circle,
        ),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: hasVideoUrl
            ? Colors.black.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
        foregroundColor: Colors.white,
      ),
      iconSize: 34,
      icon: Icon(
        hasVideoUrl ? Icons.play_arrow_rounded : Icons.info_outline_rounded,
      ),
      tooltip: hasVideoUrl ? '播放视频' : '视频暂不可播放',
    );
  }
}

class _VideoOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _VideoOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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

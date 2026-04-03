import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ThreadInlineVideoWidget extends StatefulWidget {
  final String? videoUrl;
  final String? coverUrl;

  const ThreadInlineVideoWidget({
    super.key,
    required this.videoUrl,
    required this.coverUrl,
  });

  @override
  State<ThreadInlineVideoWidget> createState() =>
      _ThreadInlineVideoWidgetState();
}

class _ThreadInlineVideoWidgetState extends State<ThreadInlineVideoWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = false;
  String? _errorMessage;

  @override
  void didUpdateWidget(covariant ThreadInlineVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _isInitializing = false;
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
      key: const ValueKey('thread-main-video-section'),
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
      key: const ValueKey('thread-main-video-play'),
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

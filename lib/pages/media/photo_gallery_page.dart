import 'package:bluefish/services/media/media_save_service.dart';
import 'package:bluefish/viewModels/app_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

class PhotoGalleryPage extends StatefulWidget {
  final List<String> imageUrls;
  final List<Object>? heroTags;
  final int initialIndex;
  final MediaSaveService? mediaSaveService;

  const PhotoGalleryPage({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    this.heroTags,
    this.mediaSaveService,
  });

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  MediaSaveService get _mediaSaveService =>
      widget.mediaSaveService ?? context.read<MediaSaveService>();
  late PageController _pageController;
  late int _currentIndex;
  bool _isSaving = false;

  Object _heroTagAt(int index) {
    final heroTags = widget.heroTags;
    if (heroTags != null && index >= 0 && index < heroTags.length) {
      return heroTags[index];
    }

    return widget.imageUrls[index];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentImage() async {
    if (_isSaving) {
      return;
    }

    final imageUrl = widget.imageUrls[_currentIndex];
    final settings = context.read<AppSettingsViewModel>().settings;
    setState(() {
      _isSaving = true;
    });

    try {
      final savedFile = await _mediaSaveService.saveImage(
        url: imageUrl,
        preferredDirectoryPath: settings.imageSaveDirectoryPath,
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
      _showSnackBar('保存图片失败，请稍后重试。');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final url = widget.imageUrls[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(url),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: _heroTagAt(index)),
              );
            },
            itemCount: widget.imageUrls.length,
            loadingBuilder: (context, event) =>
                const Center(child: CircularProgressIndicator()),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          Positioned(
            top: topInset + 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _GalleryActionButton(
                  tooltip: '关闭',
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      textAlign: TextAlign.center,
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _GalleryActionButton(
                  tooltip: _isSaving ? '正在保存' : '保存至本地',
                  icon: _isSaving
                      ? Icons.downloading_rounded
                      : Icons.download_rounded,
                  onPressed: _isSaving ? null : _saveCurrentImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _GalleryActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.48),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.28),
          disabledForegroundColor: Colors.white70,
        ),
        icon: Icon(icon),
      ),
    );
  }
}

import 'dart:io';

import 'package:http/http.dart' as http;

enum SavedMediaType { image, video }

class SavedMediaFile {
  final SavedMediaType type;
  final String path;
  final String fileName;

  const SavedMediaFile({
    required this.type,
    required this.path,
    required this.fileName,
  });
}

class MediaSaveException implements Exception {
  final String message;

  const MediaSaveException(this.message);

  @override
  String toString() => message;
}

class MediaSaveService {
  final http.Client _client;

  MediaSaveService({required http.Client client}) : _client = client;

  Future<SavedMediaFile> saveImage({
    required String url,
    String? preferredDirectoryPath,
  }) {
    return _saveNetworkMedia(
      type: SavedMediaType.image,
      url: url,
      preferredDirectoryPath: preferredDirectoryPath,
    );
  }

  Future<SavedMediaFile> saveVideo({
    required String url,
    String? preferredDirectoryPath,
  }) {
    return _saveNetworkMedia(
      type: SavedMediaType.video,
      url: url,
      preferredDirectoryPath: preferredDirectoryPath,
    );
  }

  Future<SavedMediaFile> _saveNetworkMedia({
    required SavedMediaType type,
    required String url,
    String? preferredDirectoryPath,
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (!uri.hasScheme && uri.scheme.isEmpty)) {
      throw const MediaSaveException('媒体地址无效，无法保存。');
    }

    final directory = await _resolveTargetDirectory(
      preferredDirectoryPath: preferredDirectoryPath,
    );

    http.StreamedResponse response;
    try {
      response = await _client.send(http.Request('GET', uri));
    } on Exception {
      throw const MediaSaveException('下载媒体失败，请稍后重试。');
    }

    if (response.statusCode != HttpStatus.ok) {
      throw MediaSaveException('下载媒体失败（HTTP ${response.statusCode}）。');
    }

    final contentType = response.headers[HttpHeaders.contentTypeHeader];
    final originalFileName = _resolveOriginalFileName(uri);
    final extension = _resolveFileExtension(
      originalFileName: originalFileName,
      contentType: contentType,
      type: type,
    );
    final fileName = _sanitizeFileName(
      originalFileName ?? '${DateTime.now().millisecondsSinceEpoch}$extension',
      fallbackExtension: extension,
    );
    final file = await _resolveUniqueFile(directory, fileName);

    IOSink? sink;
    try {
      sink = file.openWrite();
      await response.stream.pipe(sink);
      sink = null;
    } on Exception {
      await sink?.close();
      if (await file.exists()) {
        await file.delete();
      }
      throw const MediaSaveException('保存媒体到本地失败。');
    }

    return SavedMediaFile(type: type, path: file.path, fileName: fileName);
  }

  Future<Directory> _resolveTargetDirectory({
    required String? preferredDirectoryPath,
  }) async {
    final normalizedPreferredDirectoryPath = preferredDirectoryPath?.trim();
    final targetDirectory =
        normalizedPreferredDirectoryPath != null &&
            normalizedPreferredDirectoryPath.isNotEmpty
        ? Directory(normalizedPreferredDirectoryPath)
        : _resolveDefaultDirectory();

    try {
      await targetDirectory.create(recursive: true);
    } on FileSystemException {
      throw MediaSaveException(
        normalizedPreferredDirectoryPath != null &&
                normalizedPreferredDirectoryPath.isNotEmpty
            ? '无法访问保存目录：$normalizedPreferredDirectoryPath'
            : '无法访问默认保存目录。',
      );
    }

    return targetDirectory;
  }

  Directory _resolveDefaultDirectory() {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        return Directory('$userProfile\\Downloads');
      }
    }

    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory('$home${Platform.pathSeparator}Downloads');
      }
    }

    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }

    if (Platform.isIOS) {
      return Directory('${Platform.environment['HOME'] ?? '.'}/Documents');
    }

    return Directory.current;
  }

  String? _resolveOriginalFileName(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return null;
    }

    final lastSegment = uri.pathSegments.last.trim();
    if (lastSegment.isEmpty) {
      return null;
    }

    final decodedFileName = Uri.decodeComponent(lastSegment);
    return _extractExtension(decodedFileName) != null ? decodedFileName : null;
  }

  String _resolveFileExtension({
    required String? originalFileName,
    required String? contentType,
    required SavedMediaType type,
  }) {
    final originalExtension = _extractExtension(originalFileName);
    if (originalExtension != null) {
      return originalExtension;
    }

    final normalizedContentType = contentType?.split(';').first.trim();
    final extensionFromContentType = switch (normalizedContentType) {
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      'image/webp' => '.webp',
      'image/gif' => '.gif',
      'image/bmp' => '.bmp',
      'image/heic' => '.heic',
      'video/mp4' => '.mp4',
      'video/quicktime' => '.mov',
      'video/webm' => '.webm',
      'video/x-msvideo' => '.avi',
      'video/x-matroska' => '.mkv',
      'application/vnd.apple.mpegurl' => '.m3u8',
      _ => null,
    };
    if (extensionFromContentType != null) {
      return extensionFromContentType;
    }

    return switch (type) {
      SavedMediaType.image => '.jpg',
      SavedMediaType.video => '.mp4',
    };
  }

  String? _extractExtension(String? fileName) {
    if (fileName == null || fileName.isEmpty) {
      return null;
    }

    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return null;
    }

    return fileName.substring(dotIndex);
  }

  String _sanitizeFileName(
    String fileName, {
    required String fallbackExtension,
  }) {
    final normalized = fileName.trim().replaceAll(
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
      '_',
    );
    if (normalized.isEmpty || normalized == '.' || normalized == '..') {
      return '${DateTime.now().millisecondsSinceEpoch}$fallbackExtension';
    }

    final hasExtension = _extractExtension(normalized) != null;
    return hasExtension ? normalized : '$normalized$fallbackExtension';
  }

  Future<File> _resolveUniqueFile(Directory directory, String fileName) async {
    final extension = _extractExtension(fileName) ?? '';
    final baseName = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);
    var candidate = File('${directory.path}${Platform.pathSeparator}$fileName');
    var suffix = 1;
    while (await candidate.exists()) {
      candidate = File(
        '${directory.path}${Platform.pathSeparator}${baseName}_$suffix$extension',
      );
      suffix += 1;
    }
    return candidate;
  }
}

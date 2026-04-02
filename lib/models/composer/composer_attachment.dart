import 'package:flutter/foundation.dart';

enum ComposerAttachmentType { image, video }

enum ComposerUploadState { pending, uploading, uploaded, failed }

@immutable
class ComposerAttachment {
  final String id;
  final ComposerAttachmentType type;
  final ComposerUploadState uploadState;
  final String label;
  final String? localPath;
  final String? remoteUrl;
  final String? thumbnailUrl;
  final Duration? duration;
  final int? bytes;
  final double progress;
  final String? errorMessage;

  const ComposerAttachment({
    required this.id,
    required this.type,
    required this.uploadState,
    required this.label,
    this.localPath,
    this.remoteUrl,
    this.thumbnailUrl,
    this.duration,
    this.bytes,
    this.progress = 0,
    this.errorMessage,
  });

  bool get isReady => uploadState == ComposerUploadState.uploaded;

  ComposerAttachment copyWith({
    ComposerUploadState? uploadState,
    String? label,
    String? localPath,
    String? remoteUrl,
    String? thumbnailUrl,
    Duration? duration,
    int? bytes,
    double? progress,
    String? errorMessage,
  }) {
    return ComposerAttachment(
      id: id,
      type: type,
      uploadState: uploadState ?? this.uploadState,
      label: label ?? this.label,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      bytes: bytes ?? this.bytes,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

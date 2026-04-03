import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

@immutable
class PickedComposerImage {
  final String path;
  final String name;
  final int? bytes;

  const PickedComposerImage({
    required this.path,
    required this.name,
    this.bytes,
  });
}

abstract class ComposerImagePickerService {
  Future<PickedComposerImage?> pickImage();
}

class DeviceComposerImagePickerService implements ComposerImagePickerService {
  final ImagePicker _picker;

  DeviceComposerImagePickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  @override
  Future<PickedComposerImage?> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return null;
    }

    int? bytes;
    try {
      bytes = await pickedFile.length();
    } catch (_) {
      bytes = null;
    }

    return PickedComposerImage(
      path: pickedFile.path,
      name: pickedFile.name,
      bytes: bytes,
    );
  }
}

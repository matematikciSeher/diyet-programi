import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import 'temp_capture_file.dart';

enum PhotoSource { camera, gallery }

class PickedPhoto {
  const PickedPhoto({required this.bytes, this.contentType});

  final Uint8List bytes;
  final String? contentType;
}

/// Kamera veya galeriden fotoğraf seçimi (ilerleme fotoğrafı vb.).
abstract interface class PhotoPickerService {
  bool supports(PhotoSource source);

  /// Kullanıcı vazgeçerse `null` döner; izin reddedilirse
  /// [PermissionException] fırlatır.
  Future<PickedPhoto?> pick(PhotoSource source);
}

class ImagePickerPhotoService implements PhotoPickerService {
  ImagePickerPhotoService({
    ImagePicker? picker,
    this.maxDimension = 1600,
    this.jpegQuality = 85,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Uzun kenar. Yön düzeltmesi ve JPEG yeniden kodlama (EXIF azalır) picker'da.
  final double maxDimension;
  final int jpegQuality;

  @override
  bool supports(PhotoSource source) =>
      _picker.supportsImageSource(_sourceOf(source));

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: _sourceOf(source),
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: jpegQuality,
      );
    } on PlatformException catch (e) {
      if (e.code.endsWith('access_denied')) {
        throw PermissionException(e.message ?? e.code, code: e.code);
      }
      rethrow;
    }
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    await deleteTempCaptureFile(file.path);
    return PickedPhoto(
      bytes: bytes,
      contentType: file.mimeType ?? 'image/jpeg',
    );
  }

  static ImageSource _sourceOf(PhotoSource source) => switch (source) {
    PhotoSource.camera => ImageSource.camera,
    PhotoSource.gallery => ImageSource.gallery,
  };
}

import 'dart:typed_data';

import '../../../../core/config/app_config.dart';
import 'food_capture_codes.dart';

/// AI'ye gitmeden önce fotoğraf sınırı. Yeniden kodlama ve yön düzeltme
/// `image_picker` tarafında [AppConfig] limitleriyle yapılır; bu sınıf
/// bayt uzunluğu ve biçim kontrolüdür. Orijinal dosya gönderilmez.
class FoodImagePolicy {
  const FoodImagePolicy({
    required this.maxBytes,
    required this.maxDimension,
    required this.jpegQuality,
  });

  factory FoodImagePolicy.fromConfig(AppConfig config) => FoodImagePolicy(
    maxBytes: config.effectiveFoodVisionMaxImageBytes,
    maxDimension: config.effectiveFoodVisionMaxImageDimension,
    jpegQuality: config.effectiveFoodVisionJpegQuality,
  );

  final int maxBytes;
  final int maxDimension;
  final int jpegQuality;

  /// Sorun yoksa `null`. Aksi halde [FoodCaptureCodes] değeri.
  String? validate(Uint8List bytes, {String? mimeType}) {
    if (bytes.isEmpty) return FoodCaptureCodes.unsupportedImage;
    if (bytes.length > maxBytes) return FoodCaptureCodes.imageTooLarge;
    final sniffed = sniffMime(bytes);
    if (sniffed == null) return FoodCaptureCodes.unsupportedImage;
    if (mimeType != null &&
        mimeType.isNotEmpty &&
        !_compatible(mimeType, sniffed)) {
      return FoodCaptureCodes.unsupportedImage;
    }
    return null;
  }

  static String? sniffMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    if (bytes.length >= 12 && String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      return 'image/heic';
    }
    return null;
  }

  static bool _compatible(String declared, String sniffed) {
    final mime = declared.toLowerCase();
    if (mime == sniffed) return true;
    if (sniffed == 'image/jpeg' && (mime == 'image/jpg' || mime == 'image/pjpeg')) {
      return true;
    }
    return false;
  }
}

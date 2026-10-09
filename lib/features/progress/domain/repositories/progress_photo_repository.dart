import 'dart:typed_data';

import '../../../../core/errors/result.dart';
import '../../../../shared/models/progress_photo.dart';

abstract interface class ProgressPhotoRepository {
  /// En yeni fotoğraf önce gelir.
  Stream<List<ProgressPhoto>> watchPhotos();

  /// Görseli dosya depolamaya yükler ve meta verisini kaydeder.
  Future<Result<ProgressPhoto>> addPhoto({
    required Uint8List bytes,
    String? contentType,
    DateTime? takenAt,
    double? weightKg,
  });

  Future<Result<Uint8List?>> loadImage(ProgressPhoto photo);

  Future<Result<void>> deletePhoto(ProgressPhoto photo);
}

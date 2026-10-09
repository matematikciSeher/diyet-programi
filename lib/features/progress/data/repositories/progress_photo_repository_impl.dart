import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/progress_photo.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../../shared/services/storage/file_storage_service.dart';
import '../../domain/repositories/progress_photo_repository.dart';

final class ProgressPhotoRepositoryImpl extends UserScopedRepository
    implements ProgressPhotoRepository {
  const ProgressPhotoRepositoryImpl(super.db, super.uid, this._storage);

  final FileStorageService _storage;

  @override
  Stream<List<ProgressPhoto>> watchPhotos() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.progressPhotos(id),
          query: const DocumentQuery(orderBy: 'takenAt', descending: true),
        )
        .map(
          (docs) => docs
              .map((d) => ProgressPhoto.fromJson({...d.data, 'id': d.id}))
              .toList(),
        );
  }

  @override
  Future<Result<ProgressPhoto>> addPhoto({
    required Uint8List bytes,
    String? contentType,
    DateTime? takenAt,
    double? weightKg,
  }) => guard(() async {
    final collection = FirestorePaths.progressPhotos(requireUid());
    final id = db.generateId(collection);
    final storagePath = '$collection/$id.jpg';
    final url = await _storage.upload(
      path: storagePath,
      bytes: bytes,
      contentType: contentType,
    );
    final photo = ProgressPhoto(
      id: id,
      storagePath: storagePath,
      url: url,
      takenAt: takenAt ?? DateTime.now(),
      weightKg: weightKg,
    );
    await db.setDocument('$collection/$id', photo.toJson());
    return photo;
  });

  @override
  Future<Result<Uint8List?>> loadImage(ProgressPhoto photo) =>
      guard(() => _storage.download(photo.storagePath));

  @override
  Future<Result<void>> deletePhoto(ProgressPhoto photo) => guard(() async {
    await db.deleteDocument(
      '${FirestorePaths.progressPhotos(requireUid())}/${photo.id}',
    );
    await _storage.delete(photo.storagePath);
  });
}

final progressPhotoRepositoryProvider = Provider<ProgressPhotoRepository>(
  (ref) => ProgressPhotoRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
    ref.watch(fileStorageServiceProvider),
  ),
);

import 'dart:async';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../mappers/firestore_mapper.dart';
import '../models/user_profile.dart';
import '../services/database/document_database.dart';
import '../services/sync/sync_service.dart';
import 'user_profile_repository.dart';

/// Yerel profil deposunu korur; kayıtları Firebase kuyruğuna alır.
final class SyncingUserProfileRepository implements UserProfileRepository {
  SyncingUserProfileRepository({
    required UserProfileRepository local,
    required this.sync,
    required this.uid,
    this.remote,
  }) : _local = local;

  final UserProfileRepository _local;
  final SyncService sync;
  final DocumentDatabase? remote;
  final String? uid;

  @override
  Stream<UserProfile?> watchProfile() => _local.watchProfile();

  @override
  Future<Result<UserProfile?>> getProfile() => _local.getProfile();

  @override
  Future<Result<void>> saveProfile(UserProfile profile) => guard(() async {
    (await _local.saveProfile(profile)).requireValue;
    final id = uid;
    if (id == null || !sync.hasRemote) return;
    await sync.enqueueSet(
      FirestorePaths.user(id),
      profile.copyWith(updatedAt: DateTime.now()).toJson(),
      merge: true,
    );
    unawaited(sync.processQueue());
  });

  @override
  Future<Result<void>> deleteProfile() => guard(() async {
    (await _local.deleteProfile()).requireValue;
    final id = uid;
    if (id == null || !sync.hasRemote) return;
    await sync.enqueueDelete(FirestorePaths.user(id));
    unawaited(sync.processQueue());
  });

  /// Uzak profil daha yeniyse yerel kopyayı günceller. Hata yutulur.
  Future<void> hydrateFromRemote() async {
    final id = uid;
    final remoteDb = remote;
    if (id == null || remoteDb == null) return;
    try {
      final doc = await remoteDb.getDocument(FirestorePaths.user(id));
      if (doc == null) return;
      final remoteProfile = UserProfile.fromJson(
        FirestoreMapper.decode({...doc.data, 'id': doc.data['id'] ?? id}),
      );
      final localProfile = (await _local.getProfile()).valueOrNull;
      if (localProfile == null ||
          remoteProfile.updatedAt.isAfter(localProfile.updatedAt)) {
        (await _local.saveProfile(remoteProfile)).requireValue;
      }
    } on Object catch (error) {
      AppLogger.warning('Profil uzak kopyası alınamadı', error: error);
    }
  }
}

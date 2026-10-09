import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/app_logger.dart';
import '../../repositories/syncing_user_profile_repository.dart';
import '../database/document_database.dart';
import 'sync_service.dart';

/// Oturum açılınca uzak veriyi last-write-wins ile yerele çeker.
/// UI'yı bloklamaz; hatalar yutulur.
class UserDataHydrator {
  const UserDataHydrator({
    required this.sync,
    required this.local,
    this.profiles,
  });

  final SyncService sync;
  final DocumentDatabase local;
  final SyncingUserProfileRepository? profiles;

  Future<void> hydrate(String uid) async {
    try {
      await profiles?.hydrateFromRemote();
      await sync.pullDocument(local, FirestorePaths.user(uid));
      for (final path in FirestorePaths.userCollectionPaths(uid)) {
        await sync.pullCollection(local, path);
      }
      await sync.processQueue();
    } on Object catch (error) {
      AppLogger.warning('Uzak veri yüklenemedi', error: error);
    }
  }
}

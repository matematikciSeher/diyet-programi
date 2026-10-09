import 'dart:async';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/mappers/firestore_mapper.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/sync/sync_service.dart';
import '../../domain/models/notification_settings.dart';
import 'notification_repository.dart';

/// Bildirim tercihlerini yerelde tutar ve Firebase'e kuyruklar.
/// Planlama cihaz üzerinde kalır.
final class SyncingNotificationRepository implements NotificationRepository {
  SyncingNotificationRepository({
    required NotificationRepository local,
    required this.sync,
    required this.uid,
    this.remote,
  }) : _local = local;

  final NotificationRepository _local;
  final SyncService sync;
  final DocumentDatabase? remote;
  final String? uid;

  @override
  NotificationSettings load() => _local.load();

  @override
  Stream<NotificationSettings> watch() => _local.watch();

  @override
  Future<Result<void>> save(NotificationSettings settings) => guard(() async {
    (await _local.save(settings)).requireValue;
    final id = uid;
    if (id == null || !sync.hasRemote) return;
    await sync.enqueueSet(
      '${FirestorePaths.notificationSettings(id)}/${FirestorePaths.notificationSettingsDocId}',
      settings.toJson(),
      merge: true,
    );
    unawaited(sync.processQueue());
  });

  Future<void> hydrateFromRemote() async {
    final id = uid;
    final remoteDb = remote;
    if (id == null || remoteDb == null) return;
    try {
      final path =
          '${FirestorePaths.notificationSettings(id)}/${FirestorePaths.notificationSettingsDocId}';
      final doc = await remoteDb.getDocument(path);
      if (doc == null) return;
      final remoteSettings = NotificationSettings.fromJson(
        FirestoreMapper.decode(doc.data),
      );
      (await _local.save(remoteSettings)).requireValue;
    } on Object catch (error) {
      AppLogger.warning('Bildirim ayarları uzak kopyası alınamadı', error: error);
    }
  }

  void dispose() {
    final local = _local;
    if (local is LocalNotificationRepository) {
      local.dispose();
    }
  }
}

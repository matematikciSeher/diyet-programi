import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/features/notifications/data/repositories/notification_repository.dart';
import 'package:diyet_programi/features/notifications/data/repositories/syncing_notification_repository.dart';
import 'package:diyet_programi/features/notifications/domain/models/notification_settings.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/local_first_harness.dart';

void main() {
  test('hydrate uzak bildirim ayarını yerele çeker', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final storage = InMemoryKeyValueStorage();
    final local = LocalNotificationRepository(storage, 'user-1');
    addTearDown(local.dispose);
    await h.remote.setDocument(
      '${FirestorePaths.notificationSettings('user-1')}/${FirestorePaths.notificationSettingsDocId}',
      const NotificationSettings(enabled: true).toJson(),
    );
    final repo = SyncingNotificationRepository(
      local: local,
      sync: h.sync,
      uid: 'user-1',
      remote: h.remote,
    );
    await repo.hydrateFromRemote();
    expect(local.load().enabled, isTrue);
  });
}

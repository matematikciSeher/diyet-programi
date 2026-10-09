import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/shared/repositories/local_user_profile_repository.dart';
import 'package:diyet_programi/shared/repositories/syncing_user_profile_repository.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/local_first_harness.dart';
import '../../helpers/test_profile.dart';

void main() {
  test('profil önce yerele yazılır, sonra kuyruğa alınır', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final storage = InMemoryKeyValueStorage();
    final local = LocalUserProfileRepository(storage);
    addTearDown(local.dispose);
    final repo = SyncingUserProfileRepository(
      local: local,
      sync: h.sync,
      uid: 'user-1',
      remote: h.remote,
    );
    final profile = testProfile(id: 'user-1');
    final saved = await repo.saveProfile(profile);
    expect(saved.isSuccess, isTrue);
    expect((await local.getProfile()).valueOrNull?.name, 'Seher');
    await h.sync.processQueue();
    expect(
      h.queue.snapshot.where((o) => o.status == SyncStatus.synced),
      isNotEmpty,
    );
    final remote = await h.remote.getDocument(FirestorePaths.user('user-1'));
    expect(remote?.data['name'], 'Seher');
  });

  test('hydrate uzak daha yeniyse yereli günceller', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final storage = InMemoryKeyValueStorage();
    final local = LocalUserProfileRepository(storage);
    addTearDown(local.dispose);
    final older = testProfile(id: 'user-1').copyWith(
      updatedAt: DateTime(2026, 1, 1),
    );
    await local.saveProfile(older);
    await h.remote.setDocument(FirestorePaths.user('user-1'), {
      ...testProfile(id: 'user-1', weight: 70).toJson(),
      'updatedAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    });
    final repo = SyncingUserProfileRepository(
      local: local,
      sync: h.sync,
      uid: 'user-1',
      remote: h.remote,
    );
    await repo.hydrateFromRemote();
    expect((await local.getProfile()).valueOrNull?.weight, 70);
  });
}

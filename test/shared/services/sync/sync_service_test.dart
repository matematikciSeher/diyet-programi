import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/database/local_first_document_database.dart';
import 'package:diyet_programi/shared/services/sync/sync_operation.dart';
import 'package:diyet_programi/shared/services/sync/sync_queue.dart';
import 'package:diyet_programi/shared/services/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/failing_document_database.dart';

void main() {
  late InMemoryDocumentDatabase local;
  late InMemoryDocumentDatabase remote;
  late InMemorySyncQueue queue;
  late SyncService sync;
  var now = DateTime(2026, 9, 29, 8);

  setUp(() {
    local = InMemoryDocumentDatabase();
    remote = InMemoryDocumentDatabase();
    queue = InMemorySyncQueue();
    now = DateTime(2026, 9, 29, 8);
    sync = SyncService(
      queue: queue,
      remote: remote,
      clock: () => now,
      maxAttempts: 2,
    );
  });

  tearDown(() async {
    await local.dispose();
    await remote.dispose();
    await queue.dispose();
  });

  test('başarılı senkron pending -> synced', () async {
    await sync.enqueueSet('users/u1', {'name': 'Ayşe'});
    expect(queue.open, hasLength(1));
    expect(queue.open.first.status, SyncStatus.pending);
    await sync.processQueue();
    expect(queue.snapshot.single.status, SyncStatus.synced);
    expect((await remote.getDocument('users/u1'))?.data['name'], 'Ayşe');
  });

  test('uzak hata failed olur ve veri kuyrukta kalır', () async {
    sync.attachRemote(FailingDocumentDatabase());
    await sync.enqueueSet('users/u1', {'name': 'Ayşe'});
    await sync.processQueue();
    await sync.processQueue();
    expect(queue.snapshot.single.status, SyncStatus.failed);
    expect(queue.snapshot.single.lastError, 'unavailable');
  });

  test('remote yoksa kuyruk işlenmez, işlem pending kalır', () async {
    final offline = SyncService(queue: queue, clock: () => now);
    await offline.enqueueSet('users/u1', {'x': 1});
    await offline.processQueue();
    expect(queue.open.single.status, SyncStatus.pending);
  });

  test('pull last-write-wins ile yereli günceller', () async {
    await local.setDocument('users/u1', {
      'v': 1,
      'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    await remote.setDocument('users/u1', {
      'v': 2,
      'updatedAt': DateTime(2026, 2, 1).toIso8601String(),
    });
    await sync.pullDocument(local, 'users/u1');
    expect((await local.getDocument('users/u1'))?.data['v'], 2);
  });

  test('pull eski uzak veri yeni yerelin üzerine yazmaz', () async {
    await local.setDocument('users/u1', {
      'v': 3,
      'updatedAt': DateTime(2026, 3, 1).toIso8601String(),
    });
    await remote.setDocument('users/u1', {
      'v': 1,
      'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    await sync.pullDocument(local, 'users/u1');
    expect((await local.getDocument('users/u1'))?.data['v'], 3);
  });

  test('LocalFirst yazınca UI yereli görür, sonra remote dolar', () async {
    final db = LocalFirstDocumentDatabase(
      local: local,
      sync: sync,
      clock: () => now,
    );
    await db.setDocument(FirestorePaths.user('u1'), {'name': 'Seher'});
    expect((await local.getDocument(FirestorePaths.user('u1')))?.data['name'], 'Seher');
    await sync.processQueue();
    expect(
      (await remote.getDocument(FirestorePaths.user('u1')))?.data['name'],
      'Seher',
    );
    await db.dispose();
  });
}

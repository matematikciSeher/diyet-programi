import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/database/local_first_document_database.dart';
import 'package:diyet_programi/shared/services/sync/sync_queue.dart';
import 'package:diyet_programi/shared/services/sync/sync_service.dart';

import 'failing_document_database.dart';

class LocalFirstHarness {
  LocalFirstHarness({this.failRemote = false}) {
    local = InMemoryDocumentDatabase();
    remote = InMemoryDocumentDatabase();
    queue = InMemorySyncQueue();
    sync = SyncService(
      queue: queue,
      remote: failRemote ? FailingDocumentDatabase() : remote,
      clock: () => DateTime(2026, 9, 29, 12),
      maxAttempts: 1,
    );
    db = LocalFirstDocumentDatabase(
      local: local,
      sync: sync,
      clock: () => DateTime(2026, 9, 29, 12),
    );
  }

  late final InMemoryDocumentDatabase local;
  late final InMemoryDocumentDatabase remote;
  late final InMemorySyncQueue queue;
  late final SyncService sync;
  late final LocalFirstDocumentDatabase db;
  final bool failRemote;

  Future<void> dispose() async {
    await db.dispose();
    await remote.dispose();
    await queue.dispose();
  }
}

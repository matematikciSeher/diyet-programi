import 'dart:async';

import '../../../core/utils/app_logger.dart';
import '../../mappers/firestore_mapper.dart';
import '../sync/sync_service.dart';
import 'document_database.dart';
import 'in_memory_document_database.dart';

/// Okumalar her zaman yerelden. Yazmalar önce yerele, sonra senkron
/// kuyruğuna. Firebase yoksa veya düşerse yerel veri kaybolmaz.
class LocalFirstDocumentDatabase implements DocumentDatabase {
  LocalFirstDocumentDatabase({
    required this.local,
    required this.sync,
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final DocumentDatabase local;
  final SyncService sync;
  final DateTime Function() _clock;

  JsonMap _stamp(JsonMap data, {JsonMap? existing}) {
    final now = _clock().toIso8601String();
    return {
      ...data,
      'createdAt': data['createdAt'] ?? existing?['createdAt'] ?? now,
      'updatedAt': data['updatedAt'] ?? now,
      'deviceUpdatedAt': now,
    };
  }

  void _enqueueSet(String path, JsonMap data, {bool merge = false}) {
    if (!sync.hasRemote) return;
    unawaited(_pushSet(path, data, merge: merge));
  }

  void _enqueueDelete(String path) {
    if (!sync.hasRemote) return;
    unawaited(_pushDelete(path));
  }

  Future<void> _pushSet(
    String path,
    JsonMap data, {
    required bool merge,
  }) async {
    try {
      await sync.enqueueSet(path, data, merge: merge);
      await sync.processQueue();
    } on Object catch (error) {
      AppLogger.warning('Senkron kuyruğu yazılamadı', error: error);
    }
  }

  Future<void> _pushDelete(String path) async {
    try {
      await sync.enqueueDelete(path);
      await sync.processQueue();
    } on Object catch (error) {
      AppLogger.warning('Senkron silme kuyruğa alınamadı', error: error);
    }
  }

  @override
  Future<DocumentSnapshotData?> getDocument(String documentPath) =>
      local.getDocument(documentPath);

  @override
  Stream<DocumentSnapshotData?> watchDocument(String documentPath) =>
      local.watchDocument(documentPath);

  @override
  Future<List<DocumentSnapshotData>> getCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  }) => local.getCollection(collectionPath, query: query);

  @override
  Stream<List<DocumentSnapshotData>> watchCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  }) => local.watchCollection(collectionPath, query: query);

  @override
  String generateId(String collectionPath) => local.generateId(collectionPath);

  @override
  Future<String> addDocument(String collectionPath, JsonMap data) async {
    final stamped = _stamp(FirestoreMapper.decode(data));
    final id = await local.addDocument(collectionPath, stamped);
    _enqueueSet('$collectionPath/$id', stamped);
    return id;
  }

  @override
  Future<void> setDocument(
    String documentPath,
    JsonMap data, {
    bool merge = false,
  }) async {
    final existing = await local.getDocument(documentPath);
    final stamped = _stamp(
      FirestoreMapper.decode(data),
      existing: existing?.data,
    );
    await local.setDocument(documentPath, stamped, merge: merge);
    _enqueueSet(documentPath, stamped, merge: merge);
  }

  @override
  Future<void> updateDocument(String documentPath, JsonMap data) async {
    final existing = await local.getDocument(documentPath);
    final stamped = _stamp(
      FirestoreMapper.decode(data),
      existing: existing?.data,
    );
    await local.updateDocument(documentPath, stamped);
    final updated = await local.getDocument(documentPath);
    if (updated != null) {
      _enqueueSet(documentPath, updated.data, merge: true);
    }
  }

  @override
  Future<void> deleteDocument(String documentPath) async {
    await local.deleteDocument(documentPath);
    _enqueueDelete(documentPath);
  }

  Future<void> dispose() async {
    final db = local;
    if (db is InMemoryDocumentDatabase) {
      await db.dispose();
    }
  }
}

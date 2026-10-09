import 'dart:async';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../mappers/firestore_mapper.dart';
import '../database/document_database.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

/// Yerel değişiklikleri uzaktaki [DocumentDatabase]'e (Firestore) aktarır.
/// Uzak yoksa veya hata olursa kuyruk korunur; UI etkilenmez.
class SyncService {
  SyncService({
    required SyncQueue queue,
    DocumentDatabase? remote,
    DateTime Function() clock = DateTime.now,
    this.maxAttempts = 5,
  }) : _queue = queue,
       _remote = remote,
       _clock = clock;

  final SyncQueue _queue;
  DocumentDatabase? _remote;
  final DateTime Function() _clock;
  final int maxAttempts;
  final Set<String> _blockedUsers = {};
  var _processing = false;
  Completer<void>? _idle;

  bool get hasRemote => _remote != null;

  /// Bu kullanıcının bekleyen yazıları Firebase'e gitmez.
  void blockUserUploads(String uid) {
    if (uid.isEmpty) return;
    _blockedUsers.add(uid);
  }

  void unblockUserUploads(String uid) => _blockedUsers.remove(uid);

  bool uploadsBlockedFor(String documentPath) {
    for (final uid in _blockedUsers) {
      if (FirestorePaths.belongsToUser(documentPath, uid)) return true;
    }
    return false;
  }

  /// Süren [processQueue] bitene kadar bekler.
  Future<void> waitUntilIdle() {
    if (!_processing) return Future<void>.value();
    return _idle?.future ?? Future<void>.value();
  }

  /// Kullanıcıya ait kuyruk kayıtlarını düşürür; başka kullanıcıya dokunmaz.
  Future<void> discardUserOperations(String uid) {
    return _queue.removeWhere(
      (operation) => FirestorePaths.belongsToUser(operation.documentPath, uid),
    );
  }

  SyncQueue get queue => _queue;

  /// Firebase sonradan bağlanırsa kuyruk işlenebilir.
  void attachRemote(DocumentDatabase? remote) => _remote = remote;

  Stream<List<SyncOperation>> watchQueue() => _queue.watch();

  Future<void> enqueueSet(
    String documentPath,
    JsonMap data, {
    bool merge = false,
  }) {
    if (uploadsBlockedFor(documentPath)) return Future<void>.value();
    return _queue.enqueue(
      SyncOperation(
        id: '${_clock().microsecondsSinceEpoch}-$documentPath',
        documentPath: documentPath,
        type: SyncOperationType.set,
        data: Map<String, dynamic>.from(data),
        merge: merge,
        status: SyncStatus.pending,
        enqueuedAt: _clock(),
      ),
    );
  }

  Future<void> enqueueDelete(String documentPath) {
    if (uploadsBlockedFor(documentPath)) return Future<void>.value();
    return _queue.enqueue(
      SyncOperation(
        id: '${_clock().microsecondsSinceEpoch}-$documentPath',
        documentPath: documentPath,
        type: SyncOperationType.delete,
        status: SyncStatus.pending,
        enqueuedAt: _clock(),
      ),
    );
  }

  /// Açık işlemleri sırayla dener. Remote yoksa sessizce çıkar.
  Future<void> processQueue() async {
    if (_processing) return;
    final remote = _remote;
    if (remote == null) return;
    _processing = true;
    _idle = Completer<void>();
    try {
      for (final op in List<SyncOperation>.from(_queue.open)) {
        if (uploadsBlockedFor(op.documentPath)) continue;
        await _attempt(op, remote);
      }
    } finally {
      _processing = false;
      final idle = _idle;
      _idle = null;
      if (idle != null && !idle.isCompleted) idle.complete();
    }
  }

  /// Uzak belgelerden yerel kopyayı last-write-wins ile günceller.
  Future<void> pullCollection(
    DocumentDatabase local,
    String collectionPath,
  ) async {
    final remote = _remote;
    if (remote == null) return;
    try {
      final remoteDocs = await remote.getCollection(collectionPath);
      for (final remoteDoc in remoteDocs) {
        final path = '$collectionPath/${remoteDoc.id}';
        final localDoc = await local.getDocument(path);
        final incoming = FirestoreMapper.decode(remoteDoc.data);
        if (localDoc == null) {
          await local.setDocument(path, incoming);
          continue;
        }
        final winner = LastWriteWins.resolve(localDoc.data, incoming);
        await local.setDocument(path, winner);
      }
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Uzak koleksiyon okunamadı: $collectionPath',
        error: error,
      );
      AppLogger.debug('$stackTrace');
    }
  }

  Future<void> pullDocument(DocumentDatabase local, String documentPath) async {
    final remote = _remote;
    if (remote == null) return;
    try {
      final remoteDoc = await remote.getDocument(documentPath);
      if (remoteDoc == null) return;
      final incoming = FirestoreMapper.decode(remoteDoc.data);
      final localDoc = await local.getDocument(documentPath);
      if (localDoc == null) {
        await local.setDocument(documentPath, incoming);
        return;
      }
      await local.setDocument(
        documentPath,
        LastWriteWins.resolve(localDoc.data, incoming),
      );
    } on Object catch (error) {
      AppLogger.warning('Uzak belge okunamadı: $documentPath', error: error);
    }
  }

  Future<void> _attempt(SyncOperation op, DocumentDatabase remote) async {
    if (uploadsBlockedFor(op.documentPath)) return;
    var current = op.copyWith(
      status: SyncStatus.syncing,
      attempts: op.attempts + 1,
    );
    await _queue.update(current);
    if (uploadsBlockedFor(op.documentPath)) {
      await _queue.update(
        current.copyWith(status: SyncStatus.pending, attempts: op.attempts),
      );
      return;
    }
    try {
      switch (op.type) {
        case SyncOperationType.set:
          await remote.setDocument(
            op.documentPath,
            FirestoreMapper.encode(op.data ?? const {}),
            merge: op.merge,
          );
        case SyncOperationType.delete:
          await remote.deleteDocument(op.documentPath);
      }
      current = current.copyWith(
        status: SyncStatus.synced,
        completedAt: _clock(),
      );
      await _queue.update(current);
    } on Object catch (error) {
      final failed = current.attempts >= maxAttempts;
      current = current.copyWith(
        status: failed ? SyncStatus.failed : SyncStatus.pending,
        lastError: _safeErrorCode(error),
      );
      await _queue.update(current);
      AppLogger.warning('Senkron başarısız (${op.documentPath})', error: error);
    }
  }

  /// Beslenme/kilo gibi kişisel veriyi loglamamak için yalnızca tip/kod.
  static String _safeErrorCode(Object error) {
    if (error is AppException) {
      return error.code ?? error.runtimeType.toString();
    }
    return error.runtimeType.toString();
  }
}

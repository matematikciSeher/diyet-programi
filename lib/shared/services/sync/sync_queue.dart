import 'dart:async';
import 'dart:convert';

import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/app_logger.dart';
import '../local_storage/key_value_storage.dart';
import 'sync_operation.dart';

/// Bekleyen senkronizasyon işlemleri. Kalıcı kuyruk cihaz yeniden
/// başlatılınca kaybolmaz.
abstract interface class SyncQueue {
  List<SyncOperation> get snapshot;
  Stream<List<SyncOperation>> watch();
  Future<void> enqueue(SyncOperation operation);
  Future<void> update(SyncOperation operation);
  Future<void> removeWhere(bool Function(SyncOperation operation) test);
  List<SyncOperation> get open;
}

class InMemorySyncQueue implements SyncQueue {
  InMemorySyncQueue({List<SyncOperation>? initial}) {
    if (initial != null) {
      for (final op in initial) {
        _items[op.id] = op;
      }
    }
  }

  final Map<String, SyncOperation> _items = {};
  final _changes = StreamController<List<SyncOperation>>.broadcast();

  @override
  List<SyncOperation> get snapshot =>
      _items.values.toList()
        ..sort((a, b) => a.enqueuedAt.compareTo(b.enqueuedAt));

  @override
  List<SyncOperation> get open =>
      snapshot.where((op) => op.isOpen).toList(growable: false);

  @override
  Stream<List<SyncOperation>> watch() async* {
    yield snapshot;
    yield* _changes.stream;
  }

  @override
  Future<void> enqueue(SyncOperation operation) async {
    _items[operation.id] = operation;
    _changes.add(snapshot);
  }

  @override
  Future<void> update(SyncOperation operation) async {
    _items[operation.id] = operation;
    _changes.add(snapshot);
  }

  @override
  Future<void> removeWhere(bool Function(SyncOperation operation) test) async {
    final removed = [
      for (final entry in _items.entries)
        if (test(entry.value)) entry.key,
    ];
    if (removed.isEmpty) return;
    for (final id in removed) {
      _items.remove(id);
    }
    _changes.add(snapshot);
  }

  Future<void> dispose() => _changes.close();
}

/// [KeyValueStorage] üzerinde JSON olarak saklanan kuyruk.
class PersistentSyncQueue extends InMemorySyncQueue {
  PersistentSyncQueue._(this._storage, {super.initial});

  factory PersistentSyncQueue.load(KeyValueStorage storage) {
    return PersistentSyncQueue._(storage, initial: _read(storage));
  }

  final KeyValueStorage _storage;

  static List<SyncOperation>? _read(KeyValueStorage storage) {
    final raw = storage.getString(StorageKeys.syncQueue);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return [
        for (final item in decoded)
          if (item is Map)
            SyncOperation.fromJson(Map<String, dynamic>.from(item)),
      ];
    } on FormatException catch (e) {
      AppLogger.warning('Senkron kuyruğu okunamadı: $e');
      return null;
    }
  }

  Future<void> _persist() => _storage.setString(
    StorageKeys.syncQueue,
    jsonEncode(snapshot.map((o) => o.toJson()).toList()),
  );

  @override
  Future<void> enqueue(SyncOperation operation) async {
    await super.enqueue(operation);
    await _persist();
  }

  @override
  Future<void> update(SyncOperation operation) async {
    await super.update(operation);
    await _persist();
  }

  @override
  Future<void> removeWhere(bool Function(SyncOperation operation) test) async {
    await super.removeWhere(test);
    await _persist();
  }
}

import 'dart:async';

import '../../../core/errors/app_exception.dart';
import 'document_database.dart';

/// Firebase bağlanana kadar kullanılan, Firestore semantiğine yakın
/// bellek içi veritabanı. Test ve önizleme için de uygundur.
class InMemoryDocumentDatabase implements DocumentDatabase {
  /// [initial] önceki bir [snapshot] ile veriyi geri yükler; [onWrite] her
  /// yazma işleminden sonra çağrılır (ör. cihazdaki kopyayı güncellemek için).
  InMemoryDocumentDatabase({
    Map<String, Map<String, JsonMap>>? initial,
    this.onWrite,
  }) {
    if (initial != null) {
      for (final MapEntry(:key, :value) in initial.entries) {
        _collections[key] = {
          for (final doc in value.entries) doc.key: Map.of(doc.value),
        };
      }
    }
  }

  /// collectionPath -> (docId -> data)
  final Map<String, Map<String, JsonMap>> _collections = {};
  final _changes = StreamController<String>.broadcast();
  final void Function()? onWrite;
  int _idCounter = 0;

  /// Tüm verinin JSON'a çevrilebilir kopyası.
  Map<String, Map<String, JsonMap>> snapshot() => {
    for (final MapEntry(:key, :value) in _collections.entries)
      key: {for (final doc in value.entries) doc.key: Map.of(doc.value)},
  };

  (String, String) _split(String documentPath) {
    final index = documentPath.lastIndexOf('/');
    if (index <= 0) {
      throw ArgumentError.value(documentPath, 'documentPath', 'Invalid path');
    }
    return (
      documentPath.substring(0, index),
      documentPath.substring(index + 1),
    );
  }

  void _notify(String collectionPath) {
    _changes.add(collectionPath);
    onWrite?.call();
  }

  @override
  String generateId(String collectionPath) =>
      '${DateTime.now().microsecondsSinceEpoch}${++_idCounter}';

  @override
  Future<DocumentSnapshotData?> getDocument(String documentPath) async {
    final (collection, id) = _split(documentPath);
    final data = _collections[collection]?[id];
    return data == null
        ? null
        : DocumentSnapshotData(id: id, data: Map.of(data));
  }

  @override
  Stream<DocumentSnapshotData?> watchDocument(String documentPath) async* {
    final (collection, _) = _split(documentPath);
    yield await getDocument(documentPath);
    yield* _changes.stream
        .where((changed) => changed == collection)
        .asyncMap((_) => getDocument(documentPath));
  }

  @override
  Future<List<DocumentSnapshotData>> getCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  }) async {
    final docs = (_collections[collectionPath] ?? const {}).entries
        .map((e) => DocumentSnapshotData(id: e.key, data: Map.of(e.value)))
        .where((doc) => query.filters.every((f) => _matches(doc.data, f)))
        .toList();

    final orderBy = query.orderBy;
    if (orderBy != null) {
      docs.sort((a, b) {
        final result = _compare(a.data[orderBy], b.data[orderBy]);
        return query.descending ? -result : result;
      });
    }
    final limit = query.limit;
    return limit == null ? docs : docs.take(limit).toList();
  }

  @override
  Stream<List<DocumentSnapshotData>> watchCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  }) async* {
    yield await getCollection(collectionPath, query: query);
    yield* _changes.stream
        .where((changed) => changed == collectionPath)
        .asyncMap((_) => getCollection(collectionPath, query: query));
  }

  @override
  Future<String> addDocument(String collectionPath, JsonMap data) async {
    final id = generateId(collectionPath);
    (_collections[collectionPath] ??= {})[id] = Map.of(data);
    _notify(collectionPath);
    return id;
  }

  @override
  Future<void> setDocument(
    String documentPath,
    JsonMap data, {
    bool merge = false,
  }) async {
    final (collection, id) = _split(documentPath);
    final docs = _collections[collection] ??= {};
    docs[id] = merge ? {...?docs[id], ...data} : Map.of(data);
    _notify(collection);
  }

  @override
  Future<void> updateDocument(String documentPath, JsonMap data) async {
    final (collection, id) = _split(documentPath);
    final existing = _collections[collection]?[id];
    if (existing == null) throw NotFoundException(documentPath);
    _collections[collection]![id] = {...existing, ...data};
    _notify(collection);
  }

  @override
  Future<void> deleteDocument(String documentPath) async {
    final (collection, id) = _split(documentPath);
    _collections[collection]?.remove(id);
    _notify(collection);
  }

  bool _matches(JsonMap data, QueryFilter filter) {
    final value = data[filter.field];
    return switch (filter.operator) {
      FilterOperator.isEqualTo => value == filter.value,
      FilterOperator.isLessThan => _compare(value, filter.value) < 0,
      FilterOperator.isLessThanOrEqualTo => _compare(value, filter.value) <= 0,
      FilterOperator.isGreaterThan => _compare(value, filter.value) > 0,
      FilterOperator.isGreaterThanOrEqualTo =>
        _compare(value, filter.value) >= 0,
      FilterOperator.arrayContains =>
        value is List && value.contains(filter.value),
    };
  }

  int _compare(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is Comparable && b is Comparable) {
      try {
        return a.compareTo(b);
      } on TypeError {
        return a.toString().compareTo(b.toString());
      }
    }
    return a.toString().compareTo(b.toString());
  }

  Future<void> dispose() => _changes.close();
}

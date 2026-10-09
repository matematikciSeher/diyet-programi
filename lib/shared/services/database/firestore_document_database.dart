import 'package:cloud_firestore/cloud_firestore.dart';

import '../../mappers/firestore_mapper.dart';
import '../firebase/firebase_error_mapper.dart';
import 'document_database.dart';

/// Firestore [DocumentDatabase] uyarlaması. Repository'ler bu sınıfa
/// doğrudan bağlanmaz; [LocalFirstDocumentDatabase] üzerinden gider.
class FirestoreDocumentDatabase implements DocumentDatabase {
  FirestoreDocumentDatabase({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (error) {
      throw FirebaseErrorMapper.map(error);
    }
  }

  DocumentReference<JsonMap> _doc(String documentPath) =>
      _firestore.doc(documentPath);

  CollectionReference<JsonMap> _col(String collectionPath) =>
      _firestore.collection(collectionPath);

  Query<JsonMap> _applyQuery(
    CollectionReference<JsonMap> collection,
    DocumentQuery query,
  ) {
    Query<JsonMap> result = collection;
    for (final filter in query.filters) {
      result = switch (filter.operator) {
        FilterOperator.isEqualTo => result.where(
          filter.field,
          isEqualTo: _toFirestoreValue(filter.value),
        ),
        FilterOperator.isLessThan => result.where(
          filter.field,
          isLessThan: _toFirestoreValue(filter.value),
        ),
        FilterOperator.isLessThanOrEqualTo => result.where(
          filter.field,
          isLessThanOrEqualTo: _toFirestoreValue(filter.value),
        ),
        FilterOperator.isGreaterThan => result.where(
          filter.field,
          isGreaterThan: _toFirestoreValue(filter.value),
        ),
        FilterOperator.isGreaterThanOrEqualTo => result.where(
          filter.field,
          isGreaterThanOrEqualTo: _toFirestoreValue(filter.value),
        ),
        FilterOperator.arrayContains => result.where(
          filter.field,
          arrayContains: _toFirestoreValue(filter.value),
        ),
      };
    }
    final orderBy = query.orderBy;
    if (orderBy != null) {
      result = result.orderBy(orderBy, descending: query.descending);
    }
    final limit = query.limit;
    if (limit != null) {
      result = result.limit(limit);
    }
    return result;
  }

  JsonMap _decode(Map<String, dynamic>? data) {
    if (data == null) return {};
    return FirestoreMapper.decode(_fromFirestoreTree(data));
  }

  JsonMap _encode(JsonMap data) =>
      _toFirestoreTree(FirestoreMapper.encode(data));

  JsonMap _fromFirestoreTree(JsonMap data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      result[entry.key] = _fromFirestoreValue(entry.value);
    }
    return result;
  }

  Object? _fromFirestoreValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is Map) {
      return <String, dynamic>{
        for (final e in value.entries)
          '${e.key}': _fromFirestoreValue(e.value),
      };
    }
    if (value is List) {
      return [for (final item in value) _fromFirestoreValue(item)];
    }
    return value;
  }

  JsonMap _toFirestoreTree(JsonMap data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      result[entry.key] = _toFirestoreValue(entry.value);
    }
    return result;
  }

  Object? _toFirestoreValue(Object? value) {
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is Map) {
      return <String, dynamic>{
        for (final e in value.entries)
          '${e.key}': _toFirestoreValue(e.value),
      };
    }
    if (value is List) {
      return [for (final item in value) _toFirestoreValue(item)];
    }
    return value;
  }

  DocumentSnapshotData? _snapshot(DocumentSnapshot<JsonMap> snap) {
    if (!snap.exists) return null;
    return DocumentSnapshotData(id: snap.id, data: _decode(snap.data()));
  }

  @override
  Future<DocumentSnapshotData?> getDocument(String documentPath) =>
      _guard(() async {
        final snap = await _doc(documentPath).get();
        return _snapshot(snap);
      });

  @override
  Stream<DocumentSnapshotData?> watchDocument(String documentPath) {
    return _doc(documentPath).snapshots().map(_snapshot);
  }

  @override
  Future<List<DocumentSnapshotData>> getCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  }) => _guard(() async {
    final snap = await _applyQuery(_col(collectionPath), query).get();
    return [
      for (final doc in snap.docs)
        DocumentSnapshotData(id: doc.id, data: _decode(doc.data())),
    ];
  });

  @override
  Stream<List<DocumentSnapshotData>> watchCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  }) {
    return _applyQuery(_col(collectionPath), query).snapshots().map(
      (snap) => [
        for (final doc in snap.docs)
          DocumentSnapshotData(id: doc.id, data: _decode(doc.data())),
      ],
    );
  }

  @override
  Future<String> addDocument(String collectionPath, JsonMap data) =>
      _guard(() async {
        final ref = await _col(collectionPath).add(_encode(data));
        return ref.id;
      });

  @override
  Future<void> setDocument(
    String documentPath,
    JsonMap data, {
    bool merge = false,
  }) => _guard(
    () => _doc(documentPath).set(_encode(data), SetOptions(merge: merge)),
  );

  @override
  Future<void> updateDocument(String documentPath, JsonMap data) =>
      _guard(() => _doc(documentPath).update(_encode(data)));

  @override
  Future<void> deleteDocument(String documentPath) =>
      _guard(() => _doc(documentPath).delete());

  @override
  String generateId(String collectionPath) => _col(collectionPath).doc().id;
}

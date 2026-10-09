import 'package:equatable/equatable.dart';

typedef JsonMap = Map<String, dynamic>;

/// Veritabanından okunan doküman: id + veri.
class DocumentSnapshotData extends Equatable {
  const DocumentSnapshotData({required this.id, required this.data});

  final String id;
  final JsonMap data;

  @override
  List<Object?> get props => [id, data];
}

enum FilterOperator {
  isEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
}

class QueryFilter extends Equatable {
  const QueryFilter(this.field, this.operator, this.value);

  final String field;
  final FilterOperator operator;
  final Object? value;

  @override
  List<Object?> get props => [field, operator, value];
}

/// Sağlayıcıdan bağımsız sorgu tanımı (Firestore Query'ye çevrilir).
class DocumentQuery extends Equatable {
  const DocumentQuery({
    this.filters = const [],
    this.orderBy,
    this.descending = false,
    this.limit,
  });

  final List<QueryFilter> filters;
  final String? orderBy;
  final bool descending;
  final int? limit;

  @override
  List<Object?> get props => [filters, orderBy, descending, limit];
}

/// Doküman tabanlı uzak veritabanı soyutlaması.
///
/// Hedef implementasyon: `FirestoreDocumentDatabase` (cloud_firestore).
/// Yollar `FirestorePaths` ile üretilir. Repository'ler Firestore'u doğrudan
/// değil bu arayüzü kullanır; böylece test edilebilir ve değiştirilebilir.
abstract interface class DocumentDatabase {
  Future<DocumentSnapshotData?> getDocument(String documentPath);

  Stream<DocumentSnapshotData?> watchDocument(String documentPath);

  Future<List<DocumentSnapshotData>> getCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  });

  Stream<List<DocumentSnapshotData>> watchCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  });

  /// Yeni doküman ekler, oluşturulan id'yi döndürür.
  Future<String> addDocument(String collectionPath, JsonMap data);

  Future<void> setDocument(
    String documentPath,
    JsonMap data, {
    bool merge = false,
  });

  Future<void> updateDocument(String documentPath, JsonMap data);

  Future<void> deleteDocument(String documentPath);

  /// Koleksiyon içinde çakışmasız yeni id üretir.
  String generateId(String collectionPath);
}

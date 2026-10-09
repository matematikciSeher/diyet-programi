import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/shared/services/database/document_database.dart';

/// Testlerde Firebase/ağ hatalarını taklit eden uzak kaynak.
class FailingDocumentDatabase implements DocumentDatabase {
  FailingDocumentDatabase([
    this.error = const NetworkException(
      'unavailable',
      code: 'unavailable',
    ),
  ]);

  final AppException error;

  Never _fail() => throw error;

  @override
  Future<DocumentSnapshotData?> getDocument(String documentPath) async =>
      _fail();

  @override
  Stream<DocumentSnapshotData?> watchDocument(String documentPath) =>
      Stream.error(error);

  @override
  Future<List<DocumentSnapshotData>> getCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  }) async => _fail();

  @override
  Stream<List<DocumentSnapshotData>> watchCollection(
    String collectionPath, {
    DocumentQuery query = const DocumentQuery(),
  }) => Stream.error(error);

  @override
  Future<String> addDocument(String collectionPath, JsonMap data) async =>
      _fail();

  @override
  Future<void> setDocument(
    String documentPath,
    JsonMap data, {
    bool merge = false,
  }) async => _fail();

  @override
  Future<void> updateDocument(String documentPath, JsonMap data) async =>
      _fail();

  @override
  Future<void> deleteDocument(String documentPath) async => _fail();

  @override
  String generateId(String collectionPath) => 'fail-id';
}

import '../../../core/constants/firestore_paths.dart';
import '../../../shared/services/database/document_database.dart';
import '../domain/catalog/assistant_catalog.dart';

/// Kategorileri sabit kimlikle yazar. Yeniden açılışta ikinci kayıt açmaz.
class AssistantCategoryStore {
  const AssistantCategoryStore(this._database);

  static const collection = FirestorePaths.assistantCategoriesLocal;

  final DocumentDatabase _database;

  Future<int> ensureSeeded() async {
    for (final category in AssistantCatalog.categories) {
      await _database.setDocument('$collection/${category.id}', {
        'id': category.id,
        'section': category.section.name,
        'titleTr': category.titleTr,
        'titleEn': category.titleEn,
        'descriptionTr': category.descriptionTr,
        'descriptionEn': category.descriptionEn,
        'keywords': category.keywords,
      });
    }
    final docs = await _database.getCollection(collection);
    return docs.length;
  }
}

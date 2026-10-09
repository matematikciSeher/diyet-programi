import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/models/shopping_list_item.dart';
import '../../domain/repositories/shopping_list_repository.dart';

final class LocalShoppingListRepository extends UserScopedRepository
    implements ShoppingListRepository {
  const LocalShoppingListRepository(super.db, super.uid);

  @override
  Stream<List<ShoppingListItem>> watchItems() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.shoppingLists(id),
          query: const DocumentQuery(orderBy: 'createdAt'),
        )
        .map(
          (docs) => [
            for (final d in docs)
              ShoppingListItem.fromJson({...d.data, 'id': d.id}),
          ],
        );
  }

  @override
  Future<Result<ShoppingListItem>> addItem(ShoppingListItem item) =>
      guard(() async {
        final collection = FirestorePaths.shoppingLists(requireUid());
        final saved = ShoppingListItem(
          id: item.id.isEmpty ? db.generateId(collection) : item.id,
          userId: requireUid(),
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          category: item.category,
          isCompleted: item.isCompleted,
          sourceRecipeId: item.sourceRecipeId,
          sourceMealPlanId: item.sourceMealPlanId,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        );
        await db.setDocument('$collection/${saved.id}', saved.toJson());
        return saved;
      });

  @override
  Future<Result<ShoppingListItem>> updateItem(ShoppingListItem item) =>
      guard(() async {
        final saved = item.copyWith(updatedAt: DateTime.now());
        await db.setDocument(
          '${FirestorePaths.shoppingLists(requireUid())}/${saved.id}',
          saved.toJson(),
        );
        return saved;
      });

  @override
  Future<Result<void>> deleteItem(String id) => guard(
    () =>
        db.deleteDocument('${FirestorePaths.shoppingLists(requireUid())}/$id'),
  );

  @override
  Future<Result<void>> clearCompleted() => guard(() async {
    final uid = requireUid();
    final docs = await db.getCollection(FirestorePaths.shoppingLists(uid));
    for (final doc in docs) {
      if (doc.data['isCompleted'] == true) {
        await db.deleteDocument(
          '${FirestorePaths.shoppingLists(uid)}/${doc.id}',
        );
      }
    }
  });
}

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>(
  (ref) => LocalShoppingListRepository(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
  ),
);

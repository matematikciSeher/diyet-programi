import '../../../../core/errors/result.dart';
import '../models/shopping_list_item.dart';

/// Hedef: `FirestoreShoppingListRepository`.
abstract interface class ShoppingListRepository {
  Stream<List<ShoppingListItem>> watchItems();

  Future<Result<ShoppingListItem>> addItem(ShoppingListItem item);

  Future<Result<ShoppingListItem>> updateItem(ShoppingListItem item);

  Future<Result<void>> deleteItem(String id);

  Future<Result<void>> clearCompleted();
}

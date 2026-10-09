import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meal_plans/data/repositories/meal_plan_repository_impl.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../meal_plans/domain/usecases/weekly_meal_planner.dart';
import '../../../recipes/data/repositories/recipe_repository_impl.dart';
import '../../data/repositories/shopping_list_repository_impl.dart';
import '../../domain/models/shopping_list_item.dart';
import '../../domain/services/shopping_list_aggregator.dart';

final shoppingListAggregatorProvider = Provider<ShoppingListAggregator>(
  (ref) => ShoppingListAggregator(
    items: ref.watch(shoppingListRepositoryProvider),
    recipes: ref.watch(recipeRepositoryProvider),
    clock: ref.watch(clockProvider),
    uid: () => ref.read(currentUserIdProvider),
  ),
);

final shoppingListItemsProvider = StreamProvider<List<ShoppingListItem>>(
  (ref) => ref.watch(shoppingListRepositoryProvider).watchItems(),
);

class ShoppingListActions {
  const ShoppingListActions(this._ref);

  final Ref _ref;

  ShoppingListAggregator get _aggregator =>
      _ref.read(shoppingListAggregatorProvider);

  Future<Result<ShoppingListItem>> addManual({
    required String name,
    required double quantity,
    required String unit,
  }) async {
    final uid = _ref.read(currentUserIdProvider) ?? '';
    final now = _ref.read(clockProvider)();
    return _ref
        .read(shoppingListRepositoryProvider)
        .addItem(
          ShoppingListItem(
            id: '',
            userId: uid,
            name: name.trim(),
            quantity: quantity,
            unit: unit.trim().isEmpty ? 'adet' : unit.trim(),
            category: ShoppingCategory.forName(name),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<Result<void>> toggle(ShoppingListItem item) => _ref
      .read(shoppingListRepositoryProvider)
      .updateItem(item.copyWith(isCompleted: !item.isCompleted));

  Future<Result<void>> delete(String id) =>
      _ref.read(shoppingListRepositoryProvider).deleteItem(id);

  Future<int> addRecipe(Recipe recipe, {double portionFactor = 1}) =>
      _aggregator.addRecipe(recipe, portionFactor: portionFactor);

  Future<int> generateWeek() async {
    final today = _ref.read(clockProvider)().startOfDay;
    final meals = <PlannedMeal>[];
    final plans = _ref.read(mealPlanRepositoryProvider);
    for (final day in WeeklyMealPlanner.weekDays(today)) {
      meals.addAll(await plans.watchDay(day).first);
    }
    return _aggregator.replaceWeek(meals);
  }
}

final shoppingListActionsProvider = Provider<ShoppingListActions>(
  ShoppingListActions.new,
);

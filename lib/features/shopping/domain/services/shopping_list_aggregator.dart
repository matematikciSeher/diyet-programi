import '../../../meal_plans/domain/models/plan_item.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../recipes/domain/repositories/recipe_repository.dart';
import '../../../../shared/models/recipe.dart';
import '../models/shopping_list_item.dart';
import '../repositories/shopping_list_repository.dart';

class DraftShoppingItem {
  const DraftShoppingItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.sourceRecipeId,
    this.sourceMealPlanId,
  });

  final String name;
  final double quantity;
  final String unit;
  final String? sourceRecipeId;
  final String? sourceMealPlanId;

  ShoppingCategory get category => ShoppingCategory.forName(name);

  String get mergeKey =>
      '${_fold(name)}|${_fold(unit.isEmpty ? 'adet' : unit)}';

  static String _fold(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

/// Tarif ve plan malzemelerini birleştirip alışveriş listesine yazar.
class ShoppingListAggregator {
  const ShoppingListAggregator({
    required ShoppingListRepository items,
    required RecipeRepository recipes,
    required DateTime Function() clock,
    required String? Function() uid,
  }) : _items = items,
       _recipes = recipes,
       _clock = clock,
       _uid = uid;

  final ShoppingListRepository _items;
  final RecipeRepository _recipes;
  final DateTime Function() _clock;
  final String? Function() _uid;

  Future<int> addDrafts(
    Iterable<DraftShoppingItem> drafts, {
    bool mergeExisting = true,
  }) async {
    final uid = _uid();
    if (uid == null) return 0;
    final existing = await _items.watchItems().first;
    final byKey = <String, ShoppingListItem>{
      if (mergeExisting)
        for (final item in existing)
          DraftShoppingItem(
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
          ).mergeKey: item,
    };
    var added = 0;
    final now = _clock();
    for (final draft in drafts) {
      if (draft.name.trim().isEmpty) continue;
      final key = draft.mergeKey;
      final current = byKey[key];
      if (current != null) {
        final updated = await _items.updateItem(
          current.copyWith(
            quantity: current.quantity + draft.quantity,
            updatedAt: now,
            sourceRecipeId: current.sourceRecipeId ?? draft.sourceRecipeId,
            sourceMealPlanId:
                current.sourceMealPlanId ?? draft.sourceMealPlanId,
          ),
        );
        final saved = updated.valueOrNull;
        if (saved != null) byKey[key] = saved;
        added++;
        continue;
      }
      final created = await _items.addItem(
        ShoppingListItem(
          id: '',
          userId: uid,
          name: _title(draft.name),
          quantity: draft.quantity,
          unit: draft.unit.isEmpty ? 'adet' : draft.unit,
          category: draft.category,
          createdAt: now,
          updatedAt: now,
          sourceRecipeId: draft.sourceRecipeId,
          sourceMealPlanId: draft.sourceMealPlanId,
        ),
      );
      final saved = created.valueOrNull;
      if (saved != null) {
        byKey[key] = saved;
        added++;
      }
    }
    return added;
  }

  /// [portionFactor] 1 ise tarifte yazılı miktarlar eklenir.
  /// Ayrıntı ekranında seçilen porsiyon / tarif porsiyonu olarak verilir.
  Future<int> addRecipe(Recipe recipe, {double portionFactor = 1}) =>
      addDrafts([
        for (final ingredient in recipe.ingredients)
          DraftShoppingItem(
            name: ingredient.name,
            quantity: ingredient.quantity * portionFactor,
            unit: ingredient.unit,
            sourceRecipeId: recipe.id,
          ),
      ]);

  Future<int> addWeek(List<PlannedMeal> meals) async =>
      addDrafts(await _draftsForMeals(meals));

  /// Plan kaynaklı satırları siler ve listeyi [meals] ile yeniden yazar.
  ///
  /// Elle eklenen veya yalnızca tariften gelen satırlar durur. Aynı malzeme
  /// ve birim hafta içinde toplanır. Porsiyon, tarifin toplam malzeme
  /// listesinin porsiyon sayısına oranıdır.
  Future<int> replaceWeek(List<PlannedMeal> meals) async {
    final uid = _uid();
    if (uid == null) return 0;
    final aggregated = _aggregate(await _draftsForMeals(meals));
    final existing = await _items.watchItems().first;
    for (final item in existing) {
      final source = item.sourceMealPlanId;
      if (source != null && source.isNotEmpty) {
        await _items.deleteItem(item.id);
      }
    }
    return addDrafts(aggregated, mergeExisting: false);
  }

  Future<List<DraftShoppingItem>> _draftsForMeals(
    List<PlannedMeal> meals,
  ) async {
    final drafts = <DraftShoppingItem>[];
    for (final meal in meals) {
      final recipeId = meal.recipeId;
      Recipe? recipe;
      if (recipeId != null && recipeId.isNotEmpty) {
        recipe = await _recipes.watchRecipe(recipeId).first;
      }
      if (recipe != null && recipe.ingredients.isNotEmpty) {
        final base = recipe.servings <= 0 ? 1 : recipe.servings;
        final factor = meal.portionFactor / base;
        drafts.addAll([
          for (final ingredient in recipe.ingredients)
            DraftShoppingItem(
              name: ingredient.name,
              quantity: ingredient.quantity * factor,
              unit: ingredient.unit,
              sourceRecipeId: recipe.id,
              sourceMealPlanId: meal.id,
            ),
        ]);
        continue;
      }
      drafts.addAll([
        for (final item in meal.items)
          _fromPlanItem(item, meal, meal.portionFactor),
      ]);
    }
    return drafts;
  }

  static List<DraftShoppingItem> _aggregate(List<DraftShoppingItem> drafts) {
    final merged = <String, DraftShoppingItem>{};
    for (final draft in drafts) {
      if (draft.name.trim().isEmpty) continue;
      final current = merged[draft.mergeKey];
      merged[draft.mergeKey] = current == null
          ? draft
          : DraftShoppingItem(
              name: current.name,
              quantity: current.quantity + draft.quantity,
              unit: current.unit,
              sourceRecipeId: current.sourceRecipeId ?? draft.sourceRecipeId,
              sourceMealPlanId:
                  current.sourceMealPlanId ?? draft.sourceMealPlanId,
            );
    }
    return merged.values.toList();
  }

  static DraftShoppingItem _fromPlanItem(
    PlanItem item,
    PlannedMeal meal,
    double factor,
  ) {
    final parsed = parseAmount(item.amount);
    return DraftShoppingItem(
      name: item.name,
      quantity: (parsed.$1 ?? (item.grams > 0 ? item.grams : 1)) * factor,
      unit: parsed.$2 ?? (item.grams > 0 ? 'g' : 'adet'),
      sourceMealPlanId: meal.id,
      sourceRecipeId: meal.recipeId,
    );
  }

  /// "2 adet", "150 g", "1 kase" → (miktar, birim).
  static (double?, String?) parseAmount(String amount) {
    final match = RegExp(
      r'^\s*(\d+(?:[.,]\d+)?)\s*(.*)$',
    ).firstMatch(amount.trim());
    if (match == null) return (null, null);
    final qty = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final unit = match.group(2)?.trim();
    return (qty, (unit == null || unit.isEmpty) ? null : unit);
  }

  static String _title(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}

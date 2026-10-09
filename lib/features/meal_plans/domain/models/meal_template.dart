import '../../../../shared/models/enums.dart';
import '../../../../shared/models/nutrition_facts.dart';
import 'plan_ingredient.dart';
import 'plan_item.dart';

/// Plan üreticinin seçtiği hazır öğün kombinasyonu.
class MealTemplate {
  MealTemplate({
    required this.id,
    required this.mealType,
    required this.title,
    required this.items,
  }) : nutrition = items.fold(NutritionFacts.zero, (s, i) => s + i.nutrition),
       ingredients = {for (final item in items) ...item.ingredients};

  final String id;
  final MealType mealType;
  final String title;
  final List<PlanItem> items;
  final NutritionFacts nutrition;
  final Set<PlanIngredient> ingredients;

  bool allows(Set<PlanIngredient> excluded) =>
      !ingredients.any(excluded.contains);
}

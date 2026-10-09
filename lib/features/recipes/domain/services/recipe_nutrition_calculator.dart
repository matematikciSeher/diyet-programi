import '../../../../shared/models/food.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/recipe.dart';
import '../../../food/domain/models/portion_selection.dart';
import '../../../food/domain/services/food_calculation_service.dart';

/// Malzeme satırı: mevcut [Food] kaydına miktar ve birimle bağlanır.
class RecipeIngredientLine {
  const RecipeIngredientLine({
    required this.foodId,
    required this.quantity,
    required this.unit,
  });

  final String foodId;
  final double quantity;
  final String unit;
}

/// Tarif besinini [FoodCalculationService] ile malzemelerden üretir.
///
/// Değerler uydurulmaz. Eşleşen yiyecek veya birim yoksa hata verir.
class RecipeNutritionCalculator {
  const RecipeNutritionCalculator(
    this._foodById, {
    FoodCalculationService calculation = const FoodCalculationService(),
  }) : _calculation = calculation;

  final Food? Function(String foodId) _foodById;
  final FoodCalculationService _calculation;

  /// [servings] porsiyonluk malzemenin porsiyon başı [NutritionFacts] değeri
  /// ve gramı işlenmiş malzeme listesi.
  ({NutritionFacts perServing, List<RecipeIngredient> ingredients}) build({
    required int servings,
    required List<RecipeIngredientLine> lines,
  }) {
    if (servings < 1) {
      throw ArgumentError.value(servings, 'servings');
    }
    if (lines.isEmpty) {
      throw ArgumentError.value(lines, 'lines', 'empty');
    }
    final ingredients = <RecipeIngredient>[];
    final totals = <NutritionFacts>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final food = _foodById(line.foodId);
      if (food == null) {
        throw StateError('Tarif yiyeceği bulunamadı: ${line.foodId}');
      }
      final portion = _portion(food, line.unit);
      final selection = PortionSelection(
        portion: portion,
        quantity: line.quantity,
      );
      final nutrition = _calculation.nutritionFor(food, selection);
      final grams = _calculation.gramsFor(food, selection) ?? selection.baseAmount;
      totals.add(nutrition);
      ingredients.add(
        RecipeIngredient(
          id: '${food.id}-$i',
          foodId: food.id,
          name: food.name,
          quantity: line.quantity,
          unit: line.unit,
          grams: grams,
        ),
      );
    }
    return (
      perServing: _calculation.sum(totals).scale(1 / servings),
      ingredients: ingredients,
    );
  }

  FoodPortion _portion(Food food, String unit) {
    final key = unit.trim().toLowerCase();
    final parsed = switch (key) {
      'g' || 'gr' || 'gram' => PortionUnit.gram,
      'ml' => PortionUnit.milliliter,
      'adet' => PortionUnit.piece,
      'dilim' => PortionUnit.slice,
      'porsiyon' => PortionUnit.serving,
      'kase' => PortionUnit.bowl,
      'bardak' => PortionUnit.glass,
      'yemek kaşığı' || 'yk' => PortionUnit.tablespoon,
      'tatlı kaşığı' || 'çay kaşığı' || 'tk' || 'çk' => PortionUnit.teaspoon,
      _ => null,
    };
    if (parsed == null) {
      throw StateError('${food.id} için bilinmeyen birim: $unit');
    }
    if (parsed == PortionUnit.gram) {
      return const FoodPortion(unit: PortionUnit.gram, baseAmount: 1);
    }
    if (parsed == PortionUnit.milliliter) {
      if (food.basis == NutritionBasis.milliliter) {
        return const FoodPortion(unit: PortionUnit.milliliter, baseAmount: 1);
      }
      final density = food.gramsPerMl;
      if (density != null && density > 0) {
        return FoodPortion(unit: PortionUnit.milliliter, baseAmount: density);
      }
      throw StateError('${food.id} ml karşılığı yok');
    }
    final match = food.portions.where((p) => p.unit == parsed).firstOrNull;
    if (match == null || match.baseAmount <= 0) {
      throw StateError('${food.id} birimi yok: $unit');
    }
    return match;
  }
}

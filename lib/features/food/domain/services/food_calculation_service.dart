import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../models/portion_selection.dart';

/// Porsiyon, besin değeri ve tarif hesaplamaları. Durumsuz ve saf; UI ve
/// veri katmanından bağımsız test edilebilir.
class FoodCalculationService {
  const FoodCalculationService();

  static const _gramPortion = FoodPortion(
    unit: PortionUnit.gram,
    baseAmount: 1,
  );
  static const _mlPortion = FoodPortion(
    unit: PortionUnit.milliliter,
    baseAmount: 1,
  );

  /// Yiyecek için seçilebilir tüm ölçüler: önce veri kaynağının verdiği
  /// porsiyonlar, ardından g / ml. Yoğunluk biliniyorsa her ikisi de sunulur.
  List<FoodPortion> portionsFor(Food food) {
    final density = food.gramsPerMl;
    final base = switch (food.basis) {
      NutritionBasis.gram => [
        _gramPortion,
        if (density != null && density > 0)
          FoodPortion(unit: PortionUnit.milliliter, baseAmount: density),
      ],
      NutritionBasis.milliliter => [
        _mlPortion,
        if (density != null && density > 0)
          FoodPortion(unit: PortionUnit.gram, baseAmount: 1 / density),
      ],
    };
    return [
      ...food.portions.where((p) => p.baseAmount > 0 && !p.unit.isBaseUnit),
      ...base,
    ];
  }

  /// Hızlı eklemede kullanılan varsayılan: ilk porsiyonun 1 katı, porsiyon
  /// yoksa 100 g/ml.
  PortionSelection defaultSelection(Food food) {
    final portions = portionsFor(food);
    final first = portions.first;
    return first.unit.isBaseUnit
        ? PortionSelection(portion: first, quantity: 100)
        : PortionSelection(portion: first, quantity: 1);
  }

  NutritionFacts nutritionFor(Food food, PortionSelection selection) {
    if (!selection.isValid) return NutritionFacts.zero;
    return food.nutritionPer100.scale(selection.baseAmount / 100);
  }

  /// Seçimin gram karşılığı; ml bazlı ve yoğunluğu bilinmeyen yiyeceklerde
  /// `null`.
  double? gramsFor(Food food, PortionSelection selection) {
    return switch (food.basis) {
      NutritionBasis.gram => selection.baseAmount,
      NutritionBasis.milliliter =>
        food.gramsPerMl == null
            ? null
            : selection.baseAmount * food.gramsPerMl!,
    };
  }

  NutritionFacts sum(Iterable<NutritionFacts> items) =>
      items.fold(NutritionFacts.zero, (total, n) => total + n);

  /// Kullanıcının bir porsiyon için girdiği etiket değerlerinden yiyecek
  /// oluşturur; değerler 100 g/ml bazına çevrilerek saklanır.
  Food buildCustomFood({
    required String id,
    required String name,
    required NutritionBasis basis,
    required double portionAmount,
    required PortionUnit portionUnit,
    required NutritionFacts nutritionPerPortion,
    String? brand,
    String? barcode,
  }) {
    if (portionAmount <= 0) {
      throw ArgumentError.value(portionAmount, 'portionAmount');
    }
    return Food(
      id: id,
      name: name.trim(),
      brand: brand,
      barcode: barcode,
      basis: basis,
      nutritionPer100: nutritionPerPortion.scale(100 / portionAmount),
      portions: [
        if (!portionUnit.isBaseUnit)
          FoodPortion(unit: portionUnit, baseAmount: portionAmount),
      ],
      source: FoodSource.custom,
    );
  }

  FoodIngredient ingredientFrom(Food food, PortionSelection selection) {
    return FoodIngredient(
      foodId: food.id,
      name: food.name,
      portion: selection.portion,
      quantity: selection.quantity,
      // Yoğunluğu bilinmeyen sıvılarda tarif ağırlığı için 1 ml ≈ 1 g
      // kabul edilir; toplam besin değerleri bundan etkilenmez.
      grams: gramsFor(food, selection) ?? selection.baseAmount,
      nutrition: nutritionFor(food, selection),
    );
  }

  /// Malzemelerin toplam besin değeri.
  NutritionFacts recipeTotal(Iterable<FoodIngredient> ingredients) =>
      sum(ingredients.map((i) => i.nutrition));

  double recipeWeight(Iterable<FoodIngredient> ingredients) =>
      ingredients.fold(0, (total, i) => total + i.grams);

  /// Malzemelerden tarif yiyeceği oluşturur. Besin değerleri toplam çiğ
  /// ağırlık üzerinden 100 g'a; "porsiyon" birimi toplam / [servings]'e
  /// göre hesaplanır.
  Food buildRecipe({
    required String id,
    required String name,
    required int servings,
    required List<FoodIngredient> ingredients,
  }) {
    if (ingredients.isEmpty) {
      throw ArgumentError.value(ingredients, 'ingredients', 'empty');
    }
    if (servings < 1) throw ArgumentError.value(servings, 'servings');
    final weight = recipeWeight(ingredients);
    if (weight <= 0) throw ArgumentError.value(weight, 'weight');

    return Food(
      id: id,
      name: name.trim(),
      nutritionPer100: recipeTotal(ingredients).scale(100 / weight),
      portions: [
        FoodPortion(unit: PortionUnit.serving, baseAmount: weight / servings),
      ],
      ingredients: List.unmodifiable(ingredients),
      source: FoodSource.recipe,
    );
  }
}

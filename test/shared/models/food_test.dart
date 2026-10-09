import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const food = Food(
    id: 'off-3017620422003',
    name: 'Nutella',
    brand: 'Ferrero',
    barcode: '3017620422003',
    imageUrl: 'https://example.com/n.jpg',
    nutritionPer100: NutritionFacts(
      calories: 539,
      proteinG: 6.3,
      carbsG: 57.5,
      fatG: 30.9,
      fiberG: 0,
      sugarG: 56.3,
      saturatedFatG: 10.6,
      sodiumMg: 107,
    ),
    basis: NutritionBasis.gram,
    portions: [
      FoodPortion(unit: PortionUnit.serving, baseAmount: 15, description: '15 g'),
    ],
    keywords: ['hazelnut'],
    tags: {FoodTag.processed},
    source: FoodSource.database,
    isVerified: true,
    dataReference: 'Open Food Facts',
  );

  test('Food JSON gidiş-dönüş eşittir', () {
    expect(Food.fromJson(food.toJson()), food);
  });

  test('NutritionFacts ölçekleme 100 g → 250 g doğru çalışır', () {
    final scaled = food.nutritionPer100.scale(2.5);
    expect(scaled.calories, closeTo(1347.5, 1e-9));
    expect(scaled.proteinG, closeTo(15.75, 1e-9));
    expect(scaled.carbsG, closeTo(143.75, 1e-9));
    expect(scaled.fatG, closeTo(77.25, 1e-9));
    expect(scaled.sugarG, closeTo(140.75, 1e-9));
    expect(scaled.sodiumMg, closeTo(267.5, 1e-9));
  });

  test('tarif ile özel yiyecek kaynağı karışmaz', () {
    const custom = Food(
      id: 'c1',
      name: 'Ev yoğurdu',
      nutritionPer100: NutritionFacts(calories: 70),
      source: FoodSource.custom,
    );
    const recipe = Food(
      id: 'r1',
      name: 'Menemen',
      nutritionPer100: NutritionFacts(calories: 120),
      source: FoodSource.recipe,
      ingredients: [
        FoodIngredient(
          foodId: 'egg',
          name: 'Yumurta',
          portion: FoodPortion(unit: PortionUnit.piece, baseAmount: 50),
          quantity: 2,
          grams: 100,
          nutrition: NutritionFacts(calories: 140),
        ),
      ],
    );
    expect(custom.isUserCreated, isTrue);
    expect(custom.isRecipe, isFalse);
    expect(recipe.isRecipe, isTrue);
    expect(Food.fromJson(recipe.toJson()).ingredients, hasLength(1));
  });
}

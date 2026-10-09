import 'package:diyet_programi/features/food/domain/models/portion_selection.dart';
import 'package:diyet_programi/features/food/domain/services/food_calculation_service.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:flutter_test/flutter_test.dart';

const calc = FoodCalculationService();

const egg = Food(
  id: 'egg',
  name: 'Yumurta',
  nutritionPer100: NutritionFacts(
    calories: 140,
    proteinG: 12,
    carbsG: 1,
    fatG: 10,
  ),
  portions: [FoodPortion(unit: PortionUnit.piece, baseAmount: 50)],
);

const milk = Food(
  id: 'milk',
  name: 'Süt',
  nutritionPer100: NutritionFacts(
    calories: 60,
    proteinG: 3,
    carbsG: 5,
    fatG: 3,
  ),
  gramsPerMl: 1.03,
);

void main() {
  group('porsiyonlar', () {
    test('adlandırılmış porsiyonlar önce, ardından temel ölçü gelir', () {
      final units = calc.portionsFor(egg).map((p) => p.unit);
      expect(units, [PortionUnit.piece, PortionUnit.gram]);
    });

    test('yoğunluk varsa ml de sunulur', () {
      final ml = calc
          .portionsFor(milk)
          .singleWhere((p) => p.unit == PortionUnit.milliliter);
      expect(ml.baseAmount, 1.03);
    });

    test('varsayılan: ilk porsiyonun 1 katı, yoksa 100 g', () {
      expect(calc.defaultSelection(egg).quantity, 1);
      expect(calc.defaultSelection(egg).portion.unit, PortionUnit.piece);
      expect(calc.defaultSelection(milk).quantity, 100);
    });
  });

  group('besin değeri', () {
    test('miktarla orantılı ölçeklenir', () {
      final two = PortionSelection(portion: egg.portions.first, quantity: 2);
      final n = calc.nutritionFor(egg, two);
      expect(n.calories, 140);
      expect(n.proteinG, 12);
      expect(calc.gramsFor(egg, two), 100);
    });

    test('100 g 200 kcal iken 150 g 300 kcal ve makrolar orantılıdır', () {
      const food = Food(
        id: 'rice',
        name: 'Pirinç',
        nutritionPer100: NutritionFacts(
          calories: 200,
          proteinG: 4,
          carbsG: 44,
          fatG: 0.4,
          fiberG: 1,
        ),
      );
      const gram = FoodPortion(unit: PortionUnit.gram, baseAmount: 1);
      final n = calc.nutritionFor(
        food,
        const PortionSelection(portion: gram, quantity: 150),
      );
      expect(n.calories, 300);
      expect(n.proteinG, 6);
      expect(n.carbsG, 66);
      expect(n.fatG, closeTo(0.6, 1e-9));
      expect(n.fiberG, 1.5);
    });

    test('ml seçimi yoğunlukla grama çevrilir', () {
      final ml = calc
          .portionsFor(milk)
          .singleWhere((p) => p.unit == PortionUnit.milliliter);
      final n = calc.nutritionFor(
        milk,
        PortionSelection(portion: ml, quantity: 200),
      );
      expect(n.calories, closeTo(60 * 2.06, 1e-9));
    });

    test('geçersiz miktar sıfır döner', () {
      final zero = PortionSelection(portion: egg.portions.first, quantity: 0);
      expect(calc.nutritionFor(egg, zero), NutritionFacts.zero);
    });
  });

  test('özel yiyecek porsiyon değerlerinden 100 g bazına çevrilir', () {
    final food = calc.buildCustomFood(
      id: 'x',
      name: '  Granola ',
      basis: NutritionBasis.gram,
      portionAmount: 40,
      portionUnit: PortionUnit.bowl,
      nutritionPerPortion: const NutritionFacts(
        calories: 180,
        proteinG: 4,
        carbsG: 28,
        fatG: 6,
        fiberG: 3,
      ),
    );
    expect(food.name, 'Granola');
    expect(food.source, FoodSource.custom);
    expect(food.nutritionPer100.calories, 450);
    expect(food.nutritionPer100.fiberG, 7.5);
    expect(food.portions.single.baseAmount, 40);
    expect(
      calc.nutritionFor(food, calc.defaultSelection(food)).calories,
      closeTo(180, 1e-9),
    );
  });

  test('tarif: malzemelerin toplamı ve porsiyon başı değer', () {
    const oil = Food(
      id: 'oil',
      name: 'Zeytinyağı',
      nutritionPer100: NutritionFacts(calories: 884, fatG: 100),
    );
    const tomato = Food(
      id: 'tomato',
      name: 'Domates',
      nutritionPer100: NutritionFacts(
        calories: 18,
        proteinG: 0.9,
        carbsG: 3.9,
        fatG: 0.2,
        fiberG: 1.2,
      ),
    );
    final gram = calc.portionsFor(oil).last;
    final ingredients = [
      calc.ingredientFrom(
        egg,
        PortionSelection(portion: egg.portions.first, quantity: 2),
      ),
      calc.ingredientFrom(
        tomato,
        PortionSelection(portion: gram, quantity: 200),
      ),
      calc.ingredientFrom(oil, PortionSelection(portion: gram, quantity: 10)),
    ];

    final total = calc.recipeTotal(ingredients);
    expect(total.calories, closeTo(140 + 36 + 88.4, 1e-9));
    expect(total.fatG, closeTo(10 + 0.4 + 10, 1e-9));
    expect(total.fiberG, closeTo(2.4, 1e-9));

    final recipe = calc.buildRecipe(
      id: 'menemen',
      name: 'Menemen',
      servings: 2,
      ingredients: ingredients,
    );
    expect(recipe.isRecipe, isTrue);
    expect(recipe.ingredients, hasLength(3));

    final serving = calc.defaultSelection(recipe);
    expect(serving.portion.unit, PortionUnit.serving);
    expect(serving.portion.baseAmount, 155);
    expect(
      calc.nutritionFor(recipe, serving).calories,
      closeTo(total.calories / 2, 1e-9),
    );
  });

  test('malzemesiz tarif oluşturulamaz', () {
    expect(
      () => calc.buildRecipe(id: '', name: 'X', servings: 1, ingredients: []),
      throwsArgumentError,
    );
  });
}

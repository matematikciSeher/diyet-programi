import 'package:diyet_programi/features/dashboard/domain/nutrition_score.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/nutrition_targets.dart';
import 'package:flutter_test/flutter_test.dart';

const _targets = NutritionTargets(
  calories: 2000,
  proteinG: 100,
  carbsG: 250,
  fatG: 60,
  fiberG: 25,
  waterMl: 2000,
);

MealEntry _meal(
  MealType type,
  NutritionFacts nutrition, {
  double grams = 100,
  Set<FoodTag> tags = const {},
}) => MealEntry(
  id: '${type.name}-${nutrition.calories}',
  dayKey: '2026-09-28',
  mealType: type,
  name: 'test',
  quantityGrams: grams,
  nutrition: nutrition,
  loggedAt: DateTime(2026, 9, 28, 12),
  tags: tags,
);

double _progress(NutritionScore score, ScoreFactor factor) =>
    score.components.firstWhere((c) => c.factor == factor).progress;

void main() {
  test('ağırlıkların toplamı 100', () {
    expect(ScoreFactor.values.fold(0, (sum, f) => sum + f.maxPoints), 100);
  });

  test('boş gün 0 puan alır', () {
    final score = NutritionScoreCalculator.calculate(
      meals: const [],
      targets: _targets,
      waterMl: 0,
      now: DateTime(2026, 9, 28, 9),
    );
    expect(score.value, 0);
    expect(score.band, ScoreBand.starting);
  });

  test('tüm hedefleri tutturan gün 100 puan alır', () {
    const third = NutritionFacts(
      calories: 2000 / 3,
      proteinG: 35,
      carbsG: 80,
      fatG: 20,
      fiberG: 9,
    );
    final score = NutritionScoreCalculator.calculate(
      meals: [
        _meal(MealType.breakfast, third, grams: 150, tags: {FoodTag.fruit}),
        _meal(MealType.lunch, third, grams: 150, tags: {FoodTag.vegetable}),
        _meal(MealType.dinner, third, grams: 150, tags: {FoodTag.vegetable}),
      ],
      targets: _targets,
      waterMl: 2000,
      now: DateTime(2026, 9, 28, 21),
    );
    expect(score.value, 100);
    expect(score.band, ScoreBand.great);
  });

  test('kalori hedefi %130 aşılınca yakınlık puanı yarıya iner', () {
    final score = NutritionScoreCalculator.calculate(
      meals: [_meal(MealType.lunch, const NutritionFacts(calories: 2600))],
      targets: _targets,
      waterMl: 0,
      now: DateTime(2026, 9, 28, 13),
    );
    expect(_progress(score, ScoreFactor.calories), closeTo(0.5, 1e-9));
  });

  test('kalorinin %25\'i işlenmiş gıdadan gelirse puan yarıya iner', () {
    final score = NutritionScoreCalculator.calculate(
      meals: [
        _meal(MealType.lunch, const NutritionFacts(calories: 750)),
        _meal(
          MealType.snack,
          const NutritionFacts(calories: 250),
          tags: {FoodTag.processed},
        ),
      ],
      targets: _targets,
      waterMl: 0,
      now: DateTime(2026, 9, 28, 13),
    );
    expect(_progress(score, ScoreFactor.processed), closeTo(0.5, 1e-9));
  });

  test('saati geçen ana öğün atlanınca öğün düzeni puanı düşer', () {
    final score = NutritionScoreCalculator.calculate(
      meals: [_meal(MealType.lunch, const NutritionFacts(calories: 500))],
      targets: _targets,
      waterMl: 0,
      now: DateTime(2026, 9, 28, 15),
    );
    // Kahvaltı ve öğle vakti geçti; yalnızca öğle kaydedildi.
    expect(_progress(score, ScoreFactor.mealRhythm), 0.5);
  });
}

import 'package:diyet_programi/core/utils/extensions/date_extensions.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/plan_item.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meal_plans/domain/usecases/log_planned_meal.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late MealLogRepositoryImpl meals;
  late LogPlannedMeal log;

  setUp(() {
    db = InMemoryDocumentDatabase();
    meals = MealLogRepositoryImpl(db, 'user-1', clock: () => testNow);
    log = LogPlannedMeal(meals: meals, clock: () => testNow);
  });
  tearDown(() => db.dispose());

  test('planlanan kahvaltı bugünün günlüğüne öğün olarak eklenir', () async {
    const nutrition = NutritionFacts(
      calories: 380,
      proteinG: 18,
      carbsG: 55,
      fatG: 10,
    );
    final meal = PlannedMeal(
      id: 'plan-breakfast',
      dayKey: testNow.dayKey,
      mealType: MealType.breakfast,
      title: 'Yulaf + Yoğurt + Muz',
      nutrition: nutrition,
      items: const [
        PlanItem(
          emoji: '🥣',
          name: 'Yulaf',
          amount: '50 g',
          grams: 50,
          nutrition: NutritionFacts(
            calories: 200,
            proteinG: 8,
            carbsG: 35,
            fatG: 4,
          ),
        ),
        PlanItem(
          emoji: '🥛',
          name: 'Yoğurt',
          amount: '150 g',
          grams: 150,
          nutrition: NutritionFacts(
            calories: 180,
            proteinG: 10,
            carbsG: 20,
            fatG: 6,
          ),
        ),
      ],
    );

    final entries = (await log(
      meal,
      servingLabel: (item) => item.amount,
    )).valueOrNull!;
    expect(entries.map((e) => e.name), ['Yulaf', 'Yoğurt']);
    expect(entries.every((e) => e.mealType == MealType.breakfast), isTrue);
    expect(entries.every((e) => e.source == FoodSource.mealPlan), isTrue);
    expect(entries.every((e) => e.dayKey == testNow.dayKey), isTrue);
    expect(entries.fold(0.0, (sum, e) => sum + e.nutrition.calories), 380);

    final today = await meals.watchDay(testNow.startOfDay).first;
    expect(today, entries);
  });
}

import 'package:diyet_programi/features/food/data/datasources/sample_food_catalog.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_database_service.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/features/food/domain/services/food_calculation_service.dart';
import 'package:diyet_programi/features/food/domain/usecases/log_food.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/meals/domain/models/daily_log.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late FoodRepositoryImpl foods;
  late MealLogRepositoryImpl meals;
  const calc = FoodCalculationService();
  final now = DateTime(2026, 9, 28, 8, 30);

  setUp(() {
    db = InMemoryDocumentDatabase();
    final sample = SampleFoodDatabaseService();
    foods = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: sample,
      barcodeLookup: sample,
      clock: () => now,
    );
    meals = MealLogRepositoryImpl(db, 'user-1');
  });
  tearDown(() => db.dispose());

  test('barkod ürünü MealEntry olarak tüm öğünlere eklenir', () async {
    final logFood = LogFood(
      meals: meals,
      foods: foods,
      calculator: calc,
      clock: () => now,
    );
    final food = (await foods.findByBarcode(
      SampleFoodCatalog.demoBarcodes.first,
    )).valueOrNull!;
    final selection = calc.defaultSelection(food);

    for (final meal in MealType.values) {
      final entry = (await logFood(
        food: food,
        selection: selection,
        mealType: meal,
        servingLabel: meal.name,
      )).valueOrNull!;
      expect(entry.mealType, meal);
      expect(entry.foodId, food.id);
      expect(entry.nutrition.calories, calc.nutritionFor(food, selection).calories);
    }

    final dayEntries = await meals.watchDay(now).first;
    expect(dayEntries, hasLength(MealType.values.length));
    expect(
      {for (final e in dayEntries) e.mealType},
      MealType.values.toSet(),
    );

    final daily = DailyLog.fromEntries(date: now, entries: dayEntries);
    expect(
      daily.meals.expand((m) => m.entries).length,
      MealType.values.length,
    );
    expect(
      daily.totals.calories,
      closeTo(
        calc.nutritionFor(food, selection).calories * MealType.values.length,
        1e-6,
      ),
    );
  });

  test('porsiyon değişince hesap FoodCalculationService ile ölçeklenir', () {
    final food = SampleFoodCatalog.foods.firstWhere(
      (f) => f.barcode == SampleFoodCatalog.demoBarcodes.first,
    );
    final oneHundred = calc.defaultSelection(food);
    final scaled = oneHundred.copyWith(quantity: oneHundred.quantity * 1.5);
    expect(
      calc.nutritionFor(food, scaled).calories,
      closeTo(calc.nutritionFor(food, oneHundred).calories * 1.5, 1e-9),
    );
  });
}

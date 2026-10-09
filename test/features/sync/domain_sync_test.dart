import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/features/activity/domain/models/daily_activity.dart';
import 'package:diyet_programi/features/activity/domain/repositories/activity_repository.dart';
import 'package:diyet_programi/features/fasting/data/repositories/fasting_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/data/repositories/meal_plan_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meals/data/repositories/daily_log_repository_impl.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/measurements/data/repositories/measurement_repository_impl.dart';
import 'package:diyet_programi/features/shopping/data/repositories/shopping_list_repository_impl.dart';
import 'package:diyet_programi/features/shopping/domain/models/shopping_list_item.dart';
import 'package:diyet_programi/features/water/data/repositories/water_repository_impl.dart';
import 'package:diyet_programi/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:diyet_programi/shared/models/body_measurement.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/fasting_session.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/sync/sync_operation.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/features/nutrition/data/repositories/nutrition_goal_history_repository_impl.dart';
import 'package:diyet_programi/features/nutrition/domain/models/nutrition_goal_history.dart';
import 'package:diyet_programi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:diyet_programi/shared/services/barcode/barcode_lookup_service.dart';
import 'package:diyet_programi/shared/services/food_database/food_database_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/local_first_harness.dart';

void main() {
  const uid = 'user-1';
  final day = DateTime(2026, 9, 29);

  test('offline: su kaydı yerelde kalır, kuyruk failed olur', () async {
    final h = LocalFirstHarness(failRemote: true);
    addTearDown(h.dispose);
    final repo = WaterRepositoryImpl(h.db, uid);
    final result = await repo.addWater(250, at: day);
    expect(result.isSuccess, isTrue);
    final localLogs = await repo.watchDay(day).first;
    expect(localLogs.single.amountMl, 250);
    await h.sync.processQueue();
    expect(h.queue.snapshot, isNotEmpty);
    expect(
      h.queue.snapshot.every((o) => o.status == SyncStatus.failed),
      isTrue,
    );
    expect(
      await h.remote.getCollection(FirestorePaths.waterLogs(uid)),
      isEmpty,
    );
  });

  test('water sync uzak koleksiyona yazılır', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = WaterRepositoryImpl(h.db, uid);
    await repo.addWater(500, at: day);
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(FirestorePaths.waterLogs(uid));
    expect(remote, hasLength(1));
    expect(remote.single.data['amountMl'], 500);
  });

  test('weight sync createdAt/updatedAt taşır', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = WeightRepositoryImpl(h.db, uid);
    await repo.addEntry(weightKg: 72.5, recordedAt: day);
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(
      FirestorePaths.weightEntries(uid),
    );
    expect(remote.single.data['weightKg'], 72.5);
    expect(remote.single.data['createdAt'], isNotNull);
    expect(remote.single.data['updatedAt'], isNotNull);
  });

  test('measurement sync bel/kalça alanlarını korur', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = MeasurementRepositoryImpl(h.db, uid);
    await repo.addMeasurement(
      BodyMeasurement(
        id: '',
        recordedAt: day,
        waistCm: 90,
        hipCm: 100,
        chestCm: 95,
        neckCm: 34,
        armCm: 28,
        thighCm: 55,
      ),
    );
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(
      FirestorePaths.measurements(uid),
    );
    expect(remote.single.data['waistCm'], 90);
    expect(remote.single.data['hipCm'], 100);
  });

  test('shopping list sync kategori ve miktar korur', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = LocalShoppingListRepository(h.db, uid);
    await repo.addItem(
      ShoppingListItem(
        id: '',
        userId: uid,
        name: 'Domates',
        quantity: 2,
        unit: 'kg',
        category: ShoppingCategory.produce,
        createdAt: day,
        updatedAt: day,
      ),
    );
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(
      FirestorePaths.shoppingLists(uid),
    );
    expect(remote.single.data['name'], 'Domates');
    expect(remote.single.data['isCompleted'], false);
  });

  test('meal plan sync öğün ve kalori korur', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = MealPlanRepositoryImpl(h.db, uid);
    await repo.saveDay(day, [
      const PlannedMeal(
        id: '2026-09-29-0',
        dayKey: '2026-09-29',
        mealType: MealType.breakfast,
        title: 'Yulaf',
        nutrition: NutritionFacts(
          calories: 320,
          proteinG: 12,
          carbsG: 45,
          fatG: 8,
        ),
      ),
    ]);
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(FirestorePaths.mealPlans(uid));
    expect(remote, isNotEmpty);
    expect(remote.first.data['title'], 'Yulaf');
  });

  test('fasting sync protokol ve süre korur', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = FastingRepositoryImpl(h.db, uid);
    await repo.saveSession(
      FastingSession(
        id: '',
        startedAt: day,
        targetDuration: const Duration(hours: 16),
        protocol: FastingPreference.sixteenEight,
      ),
    );
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(
      FirestorePaths.fastingSessions(uid),
    );
    expect(remote.single.data['targetMinutes'], 16 * 60);
    expect(remote.single.data['protocol'], 'sixteenEight');
  });

  test('daily log öğün+su local-first ile birleşir', () async {
    final h = LocalFirstHarness(failRemote: true);
    addTearDown(h.dispose);
    final meals = MealLogRepositoryImpl(h.db, uid);
    final water = WaterRepositoryImpl(h.db, uid);
    final weights = WeightRepositoryImpl(h.db, uid);
    final daily = CompositeDailyLogRepository(
      meals: meals,
      water: water,
      activity: const _EmptyActivity(),
      weights: weights,
      userId: uid,
    );
    await meals.addEntry(
      MealEntry(
        id: '',
        dayKey: '2026-09-29',
        mealType: MealType.lunch,
        name: 'Tavuk',
        quantityGrams: 150,
        nutrition: const NutritionFacts(
          calories: 250,
          proteinG: 30,
          carbsG: 0,
          fatG: 12,
        ),
        loggedAt: day,
      ),
    );
    await water.addWater(300, at: day);
    final log = await daily.watchDay(day).first;
    expect(log.totals.calories, 250);
    expect(log.waterAmount, 300);
    expect(log.entries.single.name, 'Tavuk');
  });

  test('custom food sync users/{uid}/custom_foods altına yazılır', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = FoodRepositoryImpl(
      h.db,
      uid,
      foodDatabase: const EmptyFoodDatabaseService(),
      barcodeLookup: const EmptyBarcodeLookupService(),
    );
    await repo.saveCustomFood(
      const Food(
        id: '',
        name: 'Ev yemeği',
        nutritionPer100: NutritionFacts(calories: 120),
      ),
    );
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(
      FirestorePaths.customFoods(uid),
    );
    expect(remote.single.data['name'], 'Ev yemeği');
  });

  test('recipe sync users/{uid}/recipes altına yazılır', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = RecipeRepositoryImpl(h.db, uid);
    await repo.saveRecipe(
      const Recipe(
        id: '',
        title: 'Mercimek çorbası',
        servings: 2,
        nutritionPerServing: NutritionFacts(calories: 180),
      ),
    );
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(
      FirestorePaths.userRecipes(uid),
    );
    expect(remote.single.data['title'], 'Mercimek çorbası');
  });

  test('nutrition goal history sync kalori değişimini korur', () async {
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    final repo = LocalNutritionGoalHistoryRepository(h.db, uid);
    await repo.add(
      NutritionGoalHistory(
        id: '',
        userId: uid,
        createdAt: day,
        previousCalories: 1800,
        newCalories: 1650,
        approved: true,
        reason: GoalChangeReason.weightChange,
      ),
    );
    await h.sync.processQueue();
    final remote = await h.remote.getCollection(
      FirestorePaths.nutritionGoalHistory(uid),
    );
    expect(remote.single.data['newCalories'], 1650);
    expect(remote.single.data['approved'], true);
  });
}

class _EmptyActivity implements ActivityRepository {
  const _EmptyActivity();

  @override
  Stream<DailyActivity> watchDay(DateTime day) =>
      Stream.value(DailyActivity.empty);
}

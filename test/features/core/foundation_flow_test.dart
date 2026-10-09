import 'package:diyet_programi/core/routing/app_routes.dart';
import 'dart:typed_data';

import 'package:diyet_programi/features/food/data/datasources/sample_food_catalog.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_database_service.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/features/food/domain/models/food_log_draft.dart';
import 'package:diyet_programi/features/food/domain/services/food_calculation_service.dart';
import 'package:diyet_programi/features/food/domain/services/food_match_service.dart';
import 'package:diyet_programi/features/food/domain/services/food_vision_service.dart';
import 'package:diyet_programi/features/food/domain/services/spoken_meal_parser.dart';
import 'package:diyet_programi/features/food/domain/usecases/log_estimated_foods.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/notifications/domain/models/notification_settings.dart';
import 'package:diyet_programi/features/notifications/domain/services/notification_service.dart';
import 'package:diyet_programi/features/notifications/domain/services/reminder_planner.dart';
import 'package:diyet_programi/features/nutrition/data/repositories/nutrition_goal_history_repository_impl.dart';
import 'package:diyet_programi/features/nutrition/domain/models/nutrition_goal_history.dart';
import 'package:diyet_programi/features/nutrition/domain/usecases/apply_calorie_target.dart';
import 'package:diyet_programi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:diyet_programi/features/shopping/data/repositories/shopping_list_repository_impl.dart';
import 'package:diyet_programi/features/shopping/domain/services/shopping_list_aggregator.dart';
import 'package:diyet_programi/features/water/data/repositories/water_repository_impl.dart';
import 'package:diyet_programi/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:diyet_programi/features/weight/domain/usecases/weight_tracker.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:diyet_programi/shared/repositories/local_user_profile_repository.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/nutrition/calorie_calculation_service.dart';
import 'package:diyet_programi/shared/services/nutrition/nutrition_calculator.dart';
import 'package:diyet_programi/shared/services/nutrition/profile_targets_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late InMemoryKeyValueStorage storage;
  late LocalUserProfileRepository profiles;
  late WeightRepositoryImpl weights;
  late WeightTracker tracker;
  late ProfileTargetsService targets;
  late ApplyCalorieTarget apply;
  late WaterRepositoryImpl water;
  late MealLogRepositoryImpl meals;

  setUp(() {
    db = InMemoryDocumentDatabase();
    storage = InMemoryKeyValueStorage();
    profiles = LocalUserProfileRepository(storage);
    weights = WeightRepositoryImpl(db, 'user-1');
    tracker = WeightTracker(
      weights: weights,
      profiles: profiles,
      clock: () => testNow,
    );
    targets = const ProfileTargetsService(NutritionCalculator());
    apply = ApplyCalorieTarget(
      profiles: profiles,
      history: LocalNutritionGoalHistoryRepository(db, 'user-1'),
      targets: targets,
      storage: storage,
      clock: () => testNow,
    );
    water = WaterRepositoryImpl(db, 'user-1');
    meals = MealLogRepositoryImpl(db, 'user-1', clock: () => testNow);
  });

  tearDown(() {
    db.dispose();
    profiles.dispose();
  });

  test('kilo değişince yeni hedef hesaplanır', () async {
    await profiles.saveProfile(testProfile(weight: 90, dailyCalories: 1850));
    await tracker.add(85, at: testNow);
    final profile = (await profiles.getProfile()).valueOrNull!;
    expect(profile.weight, 85);
    final suggestion = targets.suggest(profile, previousWeightKg: 90);
    expect(suggestion, isNotNull);
    expect(suggestion!.calories, isNot(1850));
    expect(suggestion.hasWeightChange, isTrue);
  });

  test('hedef reddedilince eski kalori korunur', () async {
    await profiles.saveProfile(testProfile(weight: 85, dailyCalories: 1850));
    final suggestion = targets.suggest(
      (await profiles.getProfile()).valueOrNull!,
      previousWeightKg: 90,
    )!;
    await apply.keepCurrent(suggestion, reason: GoalChangeReason.weightChange);
    expect((await profiles.getProfile()).valueOrNull!.dailyCalories, 1850);
    final history = await LocalNutritionGoalHistoryRepository(
      db,
      'user-1',
    ).watch().first;
    expect(history.single.approved, isFalse);
  });

  test('hedef kabul edilince profil güncellenir', () async {
    await profiles.saveProfile(testProfile(weight: 85, dailyCalories: 1850));
    final suggestion = targets.suggest(
      (await profiles.getProfile()).valueOrNull!,
      previousWeightKg: 90,
    )!;
    await apply.apply(suggestion, reason: GoalChangeReason.weightChange);
    final profile = (await profiles.getProfile()).valueOrNull!;
    expect(profile.dailyCalories, suggestion.calories);
    expect(profile.proteinGoal, suggestion.proteinG);
  });

  test('su ekleme, silme ve gün değişimi', () async {
    await water.addWater(250, at: testNow);
    await water.addWater(100, at: testNow);
    expect(
      (await water.watchDay(testNow).first).fold(0, (s, l) => s + l.amountMl),
      350,
    );
    final logs = await water.watchDay(testNow).first;
    await water.deleteLog(logs.first.id);
    expect(await water.watchDay(testNow.add(const Duration(days: 1))).first, isEmpty);
    expect(await water.watchDay(testNow).first, isNotEmpty);
  });

  test('öğün bildirimi doğru saatte planlanır', () {
    final settings = const NotificationSettings(enabled: true).update(
      ReminderType.breakfast,
      const ReminderSetting(enabled: true, minutes: 8 * 60 + 30),
    );
    final planned = ReminderPlanner.plan(
      settings: settings,
      now: DateTime(2026, 9, 28, 9),
    );
    expect(
      planned.where((r) => r.type == ReminderType.breakfast).single.minutes,
      8 * 60 + 30,
    );
  });

  test('uyku saatlerinde su hatırlatması planlanmaz', () {
    final settings = const NotificationSettings(
      enabled: true,
      sleepStartMinutes: 23 * 60,
      sleepEndMinutes: 7 * 60,
    ).update(
      ReminderType.water,
      const ReminderSetting(
        enabled: true,
        minutes: 6 * 60,
        intervalMinutes: 60,
      ),
    );
    final planned = ReminderPlanner.plan(
      settings: settings,
      now: DateTime(2026, 9, 28, 9),
    );
    final waterMinutes = planned
        .where((r) => r.type == ReminderType.water)
        .map((r) => r.minutes);
    expect(waterMinutes, isNot(contains(6 * 60)));
    expect(waterMinutes, contains(7 * 60));
  });

  test('bildirim tıklaması ilgili ekrana gider', () {
    expect(
      NotificationService.payloadFor(ReminderType.water),
      AppRoutes.diaryFocus(section: AppRoutes.waterSection),
    );
    expect(
      NotificationService.payloadFor(ReminderType.breakfast),
      AppRoutes.diaryFocus(meal: MealType.breakfast),
    );
    expect(
      NotificationService.payloadFor(ReminderType.fastingEnd),
      AppRoutes.fasting,
    );
    expect(NotificationService.payloadFor(ReminderType.weighIn), AppRoutes.weight);
  });

  test('tarif malzemeleri birleştirilir ve tamamlanır', () async {
    final repo = LocalShoppingListRepository(db, 'user-1');
    final aggregator = ShoppingListAggregator(
      items: repo,
      recipes: RecipeRepositoryImpl(db, 'user-1'),
      clock: () => testNow,
      uid: () => 'user-1',
    );
    final recipe = const Recipe(
      id: 'r1',
      title: 'Salata',
      servings: 1,
      nutritionPerServing: NutritionFacts(calories: 50),
      ingredients: [
        RecipeIngredient(name: 'Domates', quantity: 3, unit: 'adet'),
        RecipeIngredient(name: 'Domates', quantity: 2, unit: 'adet'),
      ],
    );
    await aggregator.addRecipe(recipe);
    await aggregator.addRecipe(recipe);
    final items = await repo.watchItems().first;
    final tomato = items.singleWhere((i) => i.name.toLowerCase() == 'domates');
    expect(tomato.quantity, 10);
    final updated = await repo.updateItem(tomato.copyWith(isCompleted: true));
    expect(updated.valueOrNull!.isCompleted, isTrue);
  });

  test('fotoğraf ve ses adayları onaydan sonra DailyLog\'a eklenir', () async {
    final before = await meals.watchDay(testNow).first;
    final candidates = await const MockFoodVisionService().analyze(
      Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
    );
    expect(candidates, isNotEmpty);
    expect(await meals.watchDay(testNow).first, before);

    final parsed = const SpokenMealParser().parse(SpokenMealParser.samplePhrase);
    expect(
      parsed.map((item) => item.name.toLowerCase()),
      containsAll(['yumurta', 'peynir', 'ekmek']),
    );
    expect(await meals.watchDay(testNow).first, isEmpty);

    final sample = SampleFoodDatabaseService();
    final foods = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: sample,
      barcodeLookup: sample,
      clock: () => testNow,
    );
    final egg = SampleFoodCatalog.foods.firstWhere((food) => food.id == 'sample-egg-boiled');
    final confirm = ConfirmCapturedFoods(
      meals: meals,
      foods: foods,
      calculator: const FoodCalculationService(),
      clock: () => testNow,
    );
    final draft = FoodLogDraft(
      localId: 'egg',
      queryName: egg.name,
      food: egg,
      matchStatus: FoodMatchStatus.matched,
      quantity: 100,
      unit: PortionUnit.gram,
      baseAmount: 100,
      source: FoodSource.aiPhoto,
    );
    final denied = await confirm.call(
      drafts: [draft],
      mealType: MealType.lunch,
      submissionId: 'foundation-photo',
      confirmed: false,
    );
    expect(denied.isFailure, isTrue);
    expect(await meals.watchDay(testNow).first, isEmpty);

    final saved = await confirm.call(
      drafts: [draft],
      mealType: MealType.lunch,
      submissionId: 'foundation-photo',
      confirmed: true,
    );
    expect(saved.isSuccess, isTrue);
    final day = await meals.watchDay(testNow).first;
    expect(day.single.source, FoodSource.aiPhoto);
    expect(day.single.foodId, egg.id);
  });

  test('kalori servisi güvenli hedef üretir', () {
    final plan = const CalorieCalculationService(
      NutritionCalculator(),
    ).calculate(testProfile(weight: 90))!;
    expect(plan.bmr, greaterThan(1000));
    expect(plan.targetCalories, greaterThanOrEqualTo(1200));
  });

  test('offline su ve kilo kayıtları korunur', () async {
    await tracker.add(80, at: testNow);
    await water.addWater(500, at: testNow);
    expect((await weights.watchEntries().first).single.weightKg, 80);
    expect((await water.watchDay(testNow).first).single.amountMl, 500);
  });
}

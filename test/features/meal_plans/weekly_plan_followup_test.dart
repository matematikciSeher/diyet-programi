import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/core/utils/extensions/date_extensions.dart';
import 'package:diyet_programi/features/activity/domain/models/daily_activity.dart';
import 'package:diyet_programi/features/activity/domain/repositories/activity_repository.dart';
import 'package:diyet_programi/features/meal_plans/data/repositories/meal_plan_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/meal_plan_preferences.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/personalized_meal_plan_service.dart';
import 'package:diyet_programi/features/meal_plans/domain/usecases/log_planned_meal.dart';
import 'package:diyet_programi/features/meals/data/repositories/daily_log_repository_impl.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/recipes/data/datasources/recipe_catalog.dart';
import 'package:diyet_programi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_suitability.dart';
import 'package:diyet_programi/features/shopping/data/repositories/shopping_list_repository_impl.dart';
import 'package:diyet_programi/features/shopping/domain/models/shopping_list_item.dart';
import 'package:diyet_programi/features/shopping/domain/services/shopping_list_aggregator.dart';
import 'package:diyet_programi/features/water/data/repositories/water_repository_impl.dart';
import 'package:diyet_programi/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/database/persistent_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/local_first_harness.dart';
import '../../helpers/test_profile.dart';

void main() {
  const service = PersonalizedMealPlanService();
  final catalog = RecipeCatalog.all;
  final byId = {for (final recipe in catalog) recipe.id: recipe};
  final monday = DateTime(2026, 9, 28);

  List<PlannedMeal> week({
    MealPlanPreferences? prefs,
    int seed = 11,
    List<Recipe>? recipes,
  }) {
    final profile = testProfile(mealsPerDay: 3, dailyCalories: 2000);
    final planPrefs = prefs ?? MealPlanPreferences.fromProfile(profile);
    final source = recipes ?? catalog;
    final reserved = <String>[];
    final meals = <PlannedMeal>[];
    for (var i = 0; i < 7; i++) {
      final day = service.generateDay(
        day: monday.addDays(i),
        recipes: source,
        prefs: planPrefs,
        profile: profile,
        reservedRecipeIds: List<String>.from(reserved),
        seed: seed + i,
      );
      meals.addAll(day);
      reserved.addAll([
        for (final meal in day)
          if (meal.recipeId != null) meal.recipeId!,
      ]);
    }
    return meals;
  }

  group('alışveriş listesi', () {
    late InMemoryDocumentDatabase db;
    late LocalShoppingListRepository items;
    late ShoppingListAggregator aggregator;

    const chicken = Recipe(
      id: 'chicken-200',
      title: 'Tavuk 200',
      servings: 1,
      nutritionPerServing: NutritionFacts(calories: 220, proteinG: 40),
      ingredients: [RecipeIngredient(name: 'Tavuk', quantity: 200, unit: 'g')],
    );
    const chickenMore = Recipe(
      id: 'chicken-300',
      title: 'Tavuk 300',
      servings: 1,
      nutritionPerServing: NutritionFacts(calories: 330, proteinG: 60),
      ingredients: [RecipeIngredient(name: 'Tavuk', quantity: 300, unit: 'g')],
    );
    const fish = Recipe(
      id: 'fish-250',
      title: 'Balık',
      servings: 1,
      nutritionPerServing: NutritionFacts(calories: 280, proteinG: 35),
      ingredients: [RecipeIngredient(name: 'Balık', quantity: 250, unit: 'g')],
    );

    PlannedMeal meal(
      String id,
      String dayKey,
      Recipe recipe,
      double servings,
    ) => PlannedMeal(
      id: id,
      dayKey: dayKey,
      mealType: MealType.lunch,
      title: recipe.title,
      nutrition: recipe.nutritionPerServing.scale(servings),
      portionFactor: servings,
      recipeId: recipe.id,
    );

    setUp(() {
      db = InMemoryDocumentDatabase();
      items = LocalShoppingListRepository(db, 'user-1');
      aggregator = ShoppingListAggregator(
        items: items,
        recipes: RecipeRepositoryImpl(
          db,
          'user-1',
          catalog: const [chicken, chickenMore, fish],
        ),
        clock: () => testNow,
        uid: () => 'user-1',
      );
    });
    tearDown(() => db.dispose());

    test('7 günlük planda aynı malzeme birleşir', () async {
      final meals = [
        meal('d0', '2026-09-28', chicken, 1),
        meal('d1', '2026-09-29', chickenMore, 1),
      ];
      await items.addItem(
        ShoppingListItem(
          id: 'manual',
          userId: 'user-1',
          name: 'Ekmek',
          quantity: 1,
          unit: 'adet',
          category: ShoppingCategory.other,
          createdAt: testNow,
          updatedAt: testNow,
        ),
      );

      expect(await aggregator.replaceWeek(meals), 1);
      final list = await items.watchItems().first;
      expect(list.firstWhere((item) => item.name == 'Tavuk').quantity, 500);
      expect(list.any((item) => item.name == 'Ekmek'), isTrue);
    });

    test('öğün değişince eski plan malzemesi düşer, yenisi eklenir', () async {
      final original = [
        meal('d0', '2026-09-28', chicken, 1),
        meal('d1', '2026-09-29', chickenMore, 1),
      ];
      await aggregator.replaceWeek(original);
      final swapped = [original.first, meal('d1', '2026-09-29', fish, 1)];
      await aggregator.replaceWeek(swapped);
      final list = await items.watchItems().first;
      expect(list.firstWhere((item) => item.name == 'Tavuk').quantity, 200);
      expect(list.firstWhere((item) => item.name == 'Balık').quantity, 250);
      expect(list.where((item) => item.sourceMealPlanId != null), hasLength(2));
    });

    test(
      'porsiyon değişince miktar ölçeklenir ve tekrar üretmek biriktirmez',
      () async {
        final once = [meal('d0', '2026-09-28', chicken, 1)];
        await aggregator.replaceWeek(once);
        expect((await items.watchItems().first).single.quantity, 200);
        await aggregator.replaceWeek([meal('d0', '2026-09-28', chicken, 2)]);
        final list = await items.watchItems().first;
        expect(list, hasLength(1));
        expect(list.single.quantity, 400);
        await aggregator.replaceWeek([meal('d0', '2026-09-28', chicken, 3)]);
        expect((await items.watchItems().first).single.quantity, 600);
      },
    );

    test('katalog planının listesi tarif malzemelerinin toplamıdır', () async {
      final meals = week();
      final recipes = RecipeRepositoryImpl(db, 'user-1', catalog: catalog);
      final planList = ShoppingListAggregator(
        items: items,
        recipes: recipes,
        clock: () => testNow,
        uid: () => 'user-1',
      );
      expect(meals, hasLength(21));
      await planList.replaceWeek(meals);
      final stored = await items.watchItems().first;
      final expected = <String, double>{};
      for (final planned in meals) {
        final recipe = byId[planned.recipeId]!;
        final factor = planned.portionFactor / recipe.servings;
        for (final ingredient in recipe.ingredients) {
          final key = DraftShoppingItem(
            name: ingredient.name,
            quantity: 0,
            unit: ingredient.unit,
          ).mergeKey;
          expected[key] = (expected[key] ?? 0) + ingredient.quantity * factor;
        }
      }
      expect(stored, hasLength(expected.length));
      for (final item in stored) {
        final key = DraftShoppingItem(
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
        ).mergeKey;
        expect(item.quantity, closeTo(expected[key]!, 0.001));
        expect(item.sourceMealPlanId, isNotNull);
      }
    });
  });

  group('yerel kayıt ve çevrimdışı', () {
    test('kayıt, depo yeniden açılınca aynı 7 günü döner', () async {
      final storage = InMemoryKeyValueStorage();
      final firstDb = PersistentDocumentDatabase.load(storage);
      final meals = week();
      final first = MealPlanRepositoryImpl(firstDb, 'user-1');
      expect((await first.savePlan(meals)).isSuccess, isTrue);
      await firstDb.flush();
      await firstDb.dispose();

      final secondDb = PersistentDocumentDatabase.load(storage);
      addTearDown(secondDb.dispose);
      final second = MealPlanRepositoryImpl(secondDb, 'user-1');
      final loaded = await second.getCurrentPlan(monday);
      expect(
        loaded.map((meal) => meal.id).toSet(),
        meals.map((meal) => meal.id).toSet(),
      );
      expect(loaded.map((meal) => meal.dayKey).toSet(), {
        for (var i = 0; i < 7; i++) monday.addDays(i).dayKey,
      });
      for (final meal in meals) {
        final stored = loaded.firstWhere((item) => item.id == meal.id);
        expect(stored.recipeId, meal.recipeId);
        expect(stored.nutrition.calories, meal.nutrition.calories);
        expect(stored.portionFactor, meal.portionFactor);
      }
    });

    test('ağ yokken plan okunur, öğün ve porsiyon değişir', () async {
      final harness = LocalFirstHarness(failRemote: true);
      addTearDown(harness.dispose);
      final meals = week().take(3).toList();
      final repo = MealPlanRepositoryImpl(harness.db, 'user-1');
      expect((await repo.savePlan(meals)).isSuccess, isTrue);

      final reopened = MealPlanRepositoryImpl(harness.db, 'user-1');
      expect((await reopened.getDay(monday)).map((meal) => meal.id), [
        for (final meal in meals)
          if (meal.dayKey == monday.dayKey) meal.id,
      ]);

      final day = await reopened.getDay(monday);
      final replacement = day.first.copyWithTitle('Balık');
      expect(
        (await reopened.replaceMeal(monday, replacement)).isSuccess,
        isTrue,
      );
      expect(
        (await reopened.getDay(monday))
            .firstWhere((meal) => meal.id == replacement.id)
            .title,
        'Balık',
      );
      final current = (await reopened.getDay(monday)).firstWhere(
        (meal) => meal.id == replacement.id,
      );
      final scaled = service.withServings(
        current,
        2,
        recipe: byId[current.recipeId],
      );
      expect(
        (await reopened.updateMealPortion(monday, scaled)).isSuccess,
        isTrue,
      );

      final after = (await reopened.getDay(monday)).firstWhere(
        (meal) => meal.id == replacement.id,
      );
      expect(after.portionFactor, 2);
      expect(after.nutrition.calories, scaled.nutrition.calories);
      for (var attempt = 0; attempt < 20; attempt++) {
        await harness.sync.processQueue();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final pending = harness.queue.snapshot.any(
          (op) =>
              op.status == SyncStatus.pending ||
              op.status == SyncStatus.syncing,
        );
        if (!pending && harness.queue.snapshot.isNotEmpty) break;
      }
      expect(
        await harness.remote.getCollection(FirestorePaths.mealPlans('user-1')),
        isEmpty,
      );
      expect(harness.queue.snapshot, isNotEmpty);
      expect(
        harness.queue.snapshot.every((op) => op.status == SyncStatus.failed),
        isTrue,
      );
    });
  });

  group('firebase eşlemesi', () {
    test(
      'plan yalnızca sahibinin meal_plans yoluna gider, katalog kopyalanmaz',
      () async {
        final harness = LocalFirstHarness();
        addTearDown(harness.dispose);
        const uid = 'user-1';
        final repo = MealPlanRepositoryImpl(harness.db, uid);
        final meals = week().take(2).toList();
        expect((await repo.savePlan(meals)).isSuccess, isTrue);
        await harness.sync.processQueue();

        final remote = await harness.remote.getCollection(
          FirestorePaths.mealPlans(uid),
        );
        expect(remote, isNotEmpty);
        expect(
          harness.queue.snapshot.map((op) => op.documentPath),
          everyElement(contains('users/$uid/meal_plans/')),
        );
        expect(
          await MealPlanRepositoryImpl(
            harness.db,
            'user-2',
          ).getCurrentPlan(monday),
          isEmpty,
        );
        expect(
          await harness.remote.getCollection(FirestorePaths.recipes),
          isEmpty,
        );
        expect(
          await harness.remote.getCollection(FirestorePaths.userRecipes(uid)),
          isEmpty,
        );
        expect(remote.first.data['recipeId'], isNotNull);
      },
    );
  });

  group('hedef, değişim ve günlük', () {
    test('gün toplamları profil hedeflerine yaklaşır ve filtreyi bozmaz', () {
      final profile = testProfile(
        mealsPerDay: 3,
        dailyCalories: 2000,
        dietType: DietType.vegetarian,
        allergies: const ['yumurta'],
        dislikedFoods: const ['domates'],
      );
      final prefs = MealPlanPreferences.fromProfile(profile);
      final caloriesBefore = profile.dailyCalories;
      final proteinBefore = profile.proteinGoal;
      final carbBefore = profile.carbGoal;
      final fatBefore = profile.fatGoal;
      final reserved = <String>[];
      for (var i = 0; i < 7; i++) {
        final day = service.generateDay(
          day: monday.addDays(i),
          recipes: catalog,
          prefs: prefs,
          profile: profile,
          reservedRecipeIds: List<String>.from(reserved),
          seed: 4 + i,
        );
        reserved.addAll([
          for (final meal in day)
            if (meal.recipeId != null) meal.recipeId!,
        ]);
        expect(day.map((meal) => meal.mealType), prefs.slots);
        expect(day.map((meal) => meal.recipeId).toSet(), hasLength(day.length));
        final totals = day.fold(
          NutritionFacts.zero,
          (sum, meal) => sum + meal.nutrition,
        );
        expect(
          totals.calories,
          closeTo(prefs.dailyCalories, prefs.dailyCalories * 0.4),
        );
        expect(totals.proteinG, greaterThan(profile.proteinGoal! * 0.45));
        expect(totals.proteinG, lessThan(profile.proteinGoal! * 1.8));
        expect(totals.carbsG, greaterThan(0));
        expect(totals.fatG, greaterThan(0));
        expect(totals.fiberG, greaterThan(0));
        for (final meal in day) {
          final recipe = byId[meal.recipeId]!;
          expect(
            meal.nutrition.calories,
            recipe.nutritionPerServing.scale(meal.portionFactor).calories,
          );
          expect(
            RecipeSuitability.conflictsWithAllergy(recipe, 'yumurta'),
            isFalse,
          );
          expect(
            RecipeSuitability.containsDisliked(recipe, const ['domates']),
            isFalse,
          );
          expect(
            RecipeSuitability.matchesDiet(recipe, DietType.vegetarian),
            isTrue,
          );
        }
      }
      expect(profile.dailyCalories, caloriesBefore);
      expect(profile.proteinGoal, proteinBefore);
      expect(profile.carbGoal, carbBefore);
      expect(profile.fatGoal, fatBefore);
    });

    test('uygun tarif yokken yasaklı tarif kalori için seçilmez', () {
      const allowed = Recipe(
        id: 'lentil',
        title: 'Mercimek',
        servings: 1,
        mealTypes: [
          MealType.lunch,
          MealType.dinner,
          MealType.breakfast,
          MealType.snack,
        ],
        nutritionPerServing: NutritionFacts(
          calories: 280,
          proteinG: 16,
          carbsG: 40,
          fatG: 6,
          fiberG: 8,
        ),
        ingredients: [
          RecipeIngredient(name: 'Mercimek', quantity: 80, unit: 'g'),
        ],
      );
      const tempting = Recipe(
        id: 'omelette',
        title: 'Menemen',
        servings: 1,
        mealTypes: [
          MealType.lunch,
          MealType.dinner,
          MealType.breakfast,
          MealType.snack,
        ],
        nutritionPerServing: NutritionFacts(
          calories: 500,
          proteinG: 30,
          carbsG: 40,
          fatG: 20,
          fiberG: 4,
        ),
        ingredients: [
          RecipeIngredient(name: 'Yumurta', quantity: 2, unit: 'adet'),
          RecipeIngredient(name: 'Domates', quantity: 1, unit: 'adet'),
        ],
      );
      final profile = testProfile(
        mealsPerDay: 3,
        dailyCalories: 1500,
        dietType: DietType.vegetarian,
        allergies: const ['yumurta'],
        dislikedFoods: const ['domates'],
      );
      final day = service.generateDay(
        day: monday,
        recipes: [allowed, tempting],
        prefs: MealPlanPreferences.fromProfile(profile),
        profile: profile,
        seed: 1,
      );
      expect(day, isNotEmpty);
      expect(day.every((meal) => meal.recipeId == allowed.id), isTrue);
    });

    test('öğün ve porsiyon değişince gün toplamı yeni besinden gelir', () {
      final profile = testProfile();
      final prefs = MealPlanPreferences.fromProfile(profile);
      final day = service.generateDay(
        day: monday,
        recipes: catalog,
        prefs: prefs,
        profile: profile,
        seed: 8,
      );
      final target = day[1];
      final options = service.alternatives(
        meal: target,
        dayPlan: day,
        recipes: catalog,
        prefs: prefs,
        profile: profile,
      );
      final replacement = options.first;
      final swapped = [
        for (final meal in day)
          if (meal.id == target.id) replacement else meal,
      ];
      expect(
        swapped
            .where((meal) => meal.id != target.id)
            .map((meal) => meal.recipeId),
        day.where((meal) => meal.id != target.id).map((meal) => meal.recipeId),
      );
      expect(replacement.mealType, target.mealType);
      final before = day.fold(
        NutritionFacts.zero,
        (sum, meal) => sum + meal.nutrition,
      );
      final after = swapped.fold(
        NutritionFacts.zero,
        (sum, meal) => sum + meal.nutrition,
      );
      expect(
        after.calories,
        closeTo(
          before.calories -
              target.nutrition.calories +
              replacement.nutrition.calories,
          0.01,
        ),
      );

      final recipe = byId[day.first.recipeId]!;
      final two = service.withServings(day.first, 2, recipe: recipe);
      final three = service.withServings(two, 3, recipe: recipe);
      expect(two.nutrition.calories, closeTo(recipe.calories * 2, 0.01));
      expect(three.nutrition.proteinG, closeTo(recipe.protein * 3, 0.01));
      expect(three.nutrition.carbsG, closeTo(recipe.carbohydrates * 3, 0.01));
      expect(three.nutrition.fatG, closeTo(recipe.fat * 3, 0.01));
      expect(three.nutrition.fiberG, closeTo(recipe.fiber * 3, 0.01));
      final portioned = [three, for (final meal in day.skip(1)) meal];
      expect(
        portioned.fold(0.0, (sum, meal) => sum + meal.nutrition.calories),
        closeTo(
          before.calories -
              day.first.nutrition.calories +
              three.nutrition.calories,
          0.01,
        ),
      );
    });

    test(
      '1, 2 ve 3 porsiyon günlüğe ölçeklenmiş besin olarak yazılır',
      () async {
        final recipe = catalog.first;
        for (final servings in [1.0, 2.0, 3.0]) {
          final db = InMemoryDocumentDatabase();
          final meals = MealLogRepositoryImpl(
            db,
            'user-1',
            clock: () => testNow,
          );
          final daily = CompositeDailyLogRepository(
            meals: meals,
            water: WaterRepositoryImpl(db, 'user-1'),
            activity: const _EmptyActivity(),
            weights: WeightRepositoryImpl(db, 'user-1'),
            userId: 'user-1',
          );
          final logged =
              await LogPlannedMeal(meals: meals, clock: () => testNow)(
                PlannedMeal(
                  id: 'portion-$servings',
                  dayKey: testNow.dayKey,
                  mealType: MealType.dinner,
                  title: recipe.title,
                  nutrition: recipe.nutritionPerServing.scale(servings),
                  portionFactor: servings,
                  recipeId: recipe.id,
                ),
                servingLabel: (_) => '',
                mealServingLabel: '$servings porsiyon',
              );
          final entry = logged.valueOrNull!.single;
          expect(entry.quantity, servings);
          expect(entry.recipeId, recipe.id);
          expect(
            entry.nutrition.calories,
            closeTo(recipe.nutritionPerServing.scale(servings).calories, 0.01),
          );
          final log = await daily.watchDay(testNow).first;
          expect(log.totals.calories, closeTo(entry.nutrition.calories, 0.01));
          expect(log.totals.proteinG, closeTo(entry.nutrition.proteinG, 0.01));
          await db.dispose();
        }
      },
    );
  });
}

class _EmptyActivity implements ActivityRepository {
  const _EmptyActivity();

  @override
  Stream<DailyActivity> watchDay(DateTime day) =>
      Stream.value(DailyActivity.empty);
}

extension on PlannedMeal {
  PlannedMeal copyWithTitle(String title) => PlannedMeal(
    id: id,
    dayKey: dayKey,
    mealType: mealType,
    title: title,
    nutrition: nutrition,
    items: items,
    templateId: templateId,
    portionFactor: portionFactor,
    description: description,
    recipeId: recipeId,
    timeMinutes: timeMinutes,
  );
}

import 'package:diyet_programi/core/utils/extensions/date_extensions.dart';
import 'package:diyet_programi/features/meal_plans/data/repositories/meal_plan_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/meal_plan_preferences.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/personalized_meal_plan_service.dart';
import 'package:diyet_programi/features/recipes/data/datasources/recipe_catalog.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_suitability.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:diyet_programi/shared/models/user_profile.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  const service = PersonalizedMealPlanService();
  final recipes = RecipeCatalog.all;
  final byId = {for (final recipe in recipes) recipe.id: recipe};
  final monday = DateTime(2026, 9, 28);

  List<List<PlannedMeal>> weekFor({
    required MealPlanPreferences prefs,
    UserProfile? profile,
    int seed = 7,
  }) {
    final profileValue = profile;
    final reserved = <String>[];
    final days = <List<PlannedMeal>>[];
    for (var i = 0; i < 7; i++) {
      final day = monday.addDays(i);
      final plan = service.generateDay(
        day: day,
        recipes: recipes,
        prefs: prefs,
        profile: profileValue,
        reservedRecipeIds: List<String>.from(reserved),
        seed: seed + i,
      );
      days.add(plan);
      reserved.addAll([
        for (final meal in plan)
          if (meal.recipeId != null) meal.recipeId!,
      ]);
    }
    return days;
  }

  Recipe recipeOf(PlannedMeal meal) {
    final recipe = byId[meal.recipeId];
    expect(recipe, isNotNull, reason: meal.title);
    return recipe!;
  }

  test('7 gün, profildeki öğün sayısı ve gerçek tarif besinleri', () {
    final profile = testProfile(mealsPerDay: 3, dailyCalories: 2000);
    final prefs = MealPlanPreferences.fromProfile(profile);
    final before = profile.dailyCalories;
    final week = weekFor(prefs: prefs, profile: profile);

    expect(week, hasLength(7));
    expect(profile.dailyCalories, before);
    for (final day in week) {
      expect(day.map((meal) => meal.mealType), prefs.slots);
      expect(day.map((meal) => meal.recipeId).toSet(), hasLength(day.length));
      final total = day.fold<double>(
        0,
        (sum, meal) => sum + meal.nutrition.calories,
      );
      expect(total, closeTo(prefs.dailyCalories, prefs.dailyCalories * 0.35));
      for (final meal in day) {
        final recipe = recipeOf(meal);
        expect(
          meal.nutrition.calories,
          recipe.nutritionPerServing.scale(meal.portionFactor).calories,
        );
        expect(meal.portionFactor, isIn([1, 2, 3]));
      }
    }
  });

  test('aynı girdi aynı planı, farklı tohum farklı bir öğün üretir', () {
    final profile = testProfile();
    final prefs = MealPlanPreferences.fromProfile(profile);
    final first = weekFor(prefs: prefs, profile: profile, seed: 3);
    final again = weekFor(prefs: prefs, profile: profile, seed: 3);
    final other = weekFor(prefs: prefs, profile: profile, seed: 99);
    expect(first, again);
    expect(
      first.expand((day) => day.map((meal) => meal.recipeId)),
      isNot(other.expand((day) => day.map((meal) => meal.recipeId))),
    );
  });

  test(
    'alerji, sevilmeyen besin ve vejetaryen diyet malzeme bazında elenir',
    () {
      final eggFree = testProfile(allergies: const ['yumurta']);
      final noTomato = testProfile(dislikedFoods: const ['domates']);
      final vegetarian = testProfile(dietType: DietType.vegetarian);

      for (final day in weekFor(
        prefs: MealPlanPreferences.fromProfile(eggFree),
        profile: eggFree,
      ).expand((day) => day)) {
        expect(
          RecipeSuitability.conflictsWithAllergy(recipeOf(day), 'yumurta'),
          isFalse,
          reason: day.title,
        );
      }
      for (final day in weekFor(
        prefs: MealPlanPreferences.fromProfile(noTomato),
        profile: noTomato,
      ).expand((day) => day)) {
        expect(
          RecipeSuitability.containsDisliked(recipeOf(day), const ['domates']),
          isFalse,
          reason: day.title,
        );
      }
      for (final day in weekFor(
        prefs: MealPlanPreferences.fromProfile(vegetarian),
        profile: vegetarian,
      ).expand((day) => day)) {
        expect(
          RecipeSuitability.matchesDiet(recipeOf(day), DietType.vegetarian),
          isTrue,
          reason: day.title,
        );
      }
    },
  );

  test('kahvaltı istemeyen kullanıcıya kahvaltı konulmaz', () {
    final profile = testProfile().copyWith(
      breakfastPreference: BreakfastPreference.never,
      mealsPerDay: 3,
    );
    final prefs = MealPlanPreferences.fromProfile(profile);
    expect(prefs.slots, isNot(contains(MealType.breakfast)));
    for (final day in weekFor(prefs: prefs, profile: profile)) {
      expect(day.map((meal) => meal.mealType), prefs.slots);
    }
  });

  test('hafta boyunca tarifler gereksiz tekrar etmez', () {
    final profile = testProfile(mealsPerDay: 4);
    final week = weekFor(
      prefs: MealPlanPreferences.fromProfile(profile),
      profile: profile,
    );
    final ids = [
      for (final day in week)
        for (final meal in day) meal.recipeId,
    ];
    expect(ids.toSet().length, greaterThan(ids.length ~/ 2));
    for (final day in week) {
      final breakfasts = day.where(
        (meal) => meal.mealType == MealType.breakfast,
      );
      expect(
        breakfasts.map((meal) => meal.recipeId).toSet(),
        hasLength(breakfasts.length),
      );
    }
  });

  test(
    'öğün değişimi yalnızca o öğünü değiştirir, porsiyon besini ölçekler',
    () {
      final profile = testProfile();
      final prefs = MealPlanPreferences.fromProfile(profile);
      final day = service.generateDay(
        day: monday,
        recipes: recipes,
        prefs: prefs,
        profile: profile,
        seed: 4,
      );
      final meal = day.first;
      final options = service.alternatives(
        meal: meal,
        dayPlan: day,
        recipes: recipes,
        prefs: prefs,
        profile: profile,
      );
      expect(options, isNotEmpty);
      expect(
        options.map((option) => option.recipeId),
        isNot(contains(meal.recipeId)),
      );
      expect(
        options.map((option) => option.mealType),
        everyElement(meal.mealType),
      );
      expect(options.map((option) => option.id), everyElement(meal.id));
      final doubled = service.withServings(meal, 2, recipe: recipeOf(meal));
      expect(doubled.portionFactor, 2);
      expect(
        doubled.nutrition.calories,
        closeTo(recipeOf(meal).nutritionPerServing.scale(2).calories, 0.01),
      );
      expect(
        doubled.nutrition.proteinG,
        closeTo(meal.nutrition.proteinG * (2 / meal.portionFactor), 0.01),
      );
      expect(doubled.id, meal.id);
    },
  );

  test('plan yerel olarak kaydedilir, porsiyon ve öğün güncellenir', () async {
    final db = InMemoryDocumentDatabase();
    addTearDown(db.dispose);
    final repo = MealPlanRepositoryImpl(db, 'user-1');
    final profile = testProfile();
    final prefs = MealPlanPreferences.fromProfile(profile);
    final meals = service.generateDay(
      day: monday,
      recipes: recipes,
      prefs: prefs,
      profile: profile,
      seed: 2,
    );
    expect((await repo.savePlan(meals)).isSuccess, isTrue);
    expect(await repo.getCurrentPlan(monday), isNotEmpty);
    expect(await repo.getMealById(meals.first.id), meals.first);

    final scaled = service.withServings(
      meals.first,
      3,
      recipe: recipeOf(meals.first),
    );
    expect((await repo.updateMealPortion(monday, scaled)).isSuccess, isTrue);
    final stored = await repo.getMealById(meals.first.id);
    expect(stored?.portionFactor, 3);
    expect(stored?.nutrition.calories, scaled.nutrition.calories);

    final replacement = service
        .alternatives(
          meal: meals[1],
          dayPlan: meals,
          recipes: recipes,
          prefs: prefs,
          profile: profile,
        )
        .first;
    expect((await repo.replaceMeal(monday, replacement)).isSuccess, isTrue);
    final day = await repo.getDay(monday);
    expect(
      day.firstWhere((meal) => meal.id == meals[1].id).recipeId,
      replacement.recipeId,
    );
    expect(
      day.firstWhere((meal) => meal.id == meals.first.id).portionFactor,
      3,
    );

    expect((await repo.removeMeal(monday, meals.last.id)).isSuccess, isTrue);
    expect(await repo.getMealById(meals.last.id), isNull);
  });
}

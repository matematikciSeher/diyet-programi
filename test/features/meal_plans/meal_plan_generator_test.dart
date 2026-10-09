import 'dart:math';

import 'package:diyet_programi/features/meal_plans/data/datasources/meal_template_catalog.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/meal_plan_preferences.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/plan_ingredient.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generator.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/plan_change_parser.dart';
import 'package:diyet_programi/features/meal_plans/domain/usecases/apply_plan_change.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final generator = MealPlanGenerator(MealTemplateCatalog.all);
  final apply = ApplyPlanChange(generator);
  final day = DateTime(2026, 9, 28);
  const prefs = MealPlanPreferences();

  bool hasAny(List<PlannedMeal> plan, Set<PlanIngredient> ingredients) =>
      plan.any((m) => m.ingredients.any(ingredients.contains));

  test('her öğün için bir öneri, sabit sırayla ve kaloriye yakın', () {
    final plan = generator.generateDay(day, prefs);
    expect(plan.map((m) => m.mealType), prefs.slots);
    final total = plan.fold(0.0, (s, m) => s + m.nutrition.calories);
    expect(total, closeTo(prefs.dailyCalories, prefs.dailyCalories * 0.2));
    expect(plan.map((m) => m.templateId).toSet(), hasLength(plan.length));
  });

  test('aynı gün için aynı plan üretilir', () {
    expect(
      generator.generateDay(day, prefs),
      generator.generateDay(day, prefs),
    );
  });

  test('şablonlar tutarlı: her öğün tipinde vegan seçenek var', () {
    final vegan = PlanIngredient.excludedByDiet(DietType.vegan);
    for (final type in MealType.values) {
      expect(
        MealTemplateCatalog.all.where(
          (t) => t.mealType == type && t.allows(vegan),
        ),
        isNotEmpty,
        reason: type.name,
      );
    }
  });

  test('profildeki diyet, alerji ve sevilmeyenlere uyulur', () {
    final profile = UserProfile(
      id: 'u',
      createdAt: day,
      updatedAt: day,
      dietType: DietType.pescatarian,
      allergies: const ['lactose'],
      dislikedFoods: const ['Yumurta'],
      mealsPerDay: 5,
      dailyCalories: 1800,
    );
    final p = MealPlanPreferences.fromProfile(profile);
    expect(p.slots, hasLength(5));
    for (var d = 0; d < 14; d++) {
      final plan = generator.generateDay(day.add(Duration(days: d)), p);
      expect(
        hasAny(plan, {
          ...PlanIngredient.meat,
          ...PlanIngredient.dairy,
          PlanIngredient.egg,
        }),
        isFalse,
      );
    }
  });

  test('kahvaltıyı hiç yapmayan kullanıcıya kahvaltı önerilmez', () {
    expect(MealPlanPreferences.slotsFor(3, BreakfastPreference.never), [
      MealType.lunch,
      MealType.snack,
      MealType.dinner,
    ]);
  });

  group('plan değişikliği', () {
    const parser = PlanChangeParser();

    /// Tavuk içeren bir plan bulana kadar günleri dener.
    List<PlannedMeal> planWithChicken() {
      for (var d = 0; d < 60; d++) {
        final plan = generator.generateDay(day.add(Duration(days: d)), prefs);
        if (hasAny(plan, {PlanIngredient.chicken})) return plan;
      }
      fail('tavuklu plan üretilemedi');
    }

    test('"Tavuğu sevmiyorum" tavuklu öğünleri değiştirir ve hatırlanır', () {
      final plan = planWithChicken();
      final outcome = apply(
        day: day,
        plan: plan,
        request: parser.parse('Tavuğu sevmiyorum'),
        prefs: prefs,
        random: Random(1),
      );
      expect(outcome.kind, PlanChangeKind.excluded);
      expect(outcome.changed, isTrue);
      expect(outcome.remember, isTrue);
      expect(hasAny(outcome.plan, {PlanIngredient.chicken}), isFalse);
      // Tavuk içermeyen öğünlere dokunulmaz; öğün düzeni korunur.
      expect(outcome.plan.map((m) => m.id), plan.map((m) => m.id));
      for (final meal in plan) {
        if (!meal.ingredients.contains(PlanIngredient.chicken)) {
          expect(outcome.plan.firstWhere((m) => m.id == meal.id), meal);
        }
      }
    });

    test('plan zaten uygunsa değişiklik yapılmaz', () {
      final noFish = prefs.withExcluded({PlanIngredient.fish});
      final plan = generator.generateDay(day, noFish);
      final outcome = apply(
        day: day,
        plan: plan,
        request: parser.parse('Balık sevmiyorum'),
        prefs: noFish,
      );
      expect(outcome.changed, isFalse);
      expect(outcome.alreadyMatching, hasLength(plan.length));
    });

    test('öğüne özel istek yalnızca o öğünü değiştirir, hatırlanmaz', () {
      final plan = generator.generateDay(day, prefs);
      final outcome = apply(
        day: day,
        plan: plan,
        request: parser.parse('Akşam yemeğini değiştir'),
        prefs: prefs,
        random: Random(2),
      );
      expect(outcome.kind, PlanChangeKind.swapped);
      expect(outcome.changes, hasLength(1));
      expect(outcome.changes.single.before.mealType, MealType.dinner);
      expect(
        outcome.changes.single.after.templateId,
        isNot(outcome.changes.single.before.templateId),
      );
      expect(outcome.remember, isFalse);
    });

    test('istenen bileşen akşam yemeğine eklenir', () {
      final noFish = prefs.withExcluded({PlanIngredient.fish});
      final plan = generator.generateDay(day, noFish);
      final outcome = apply(
        day: day,
        plan: plan,
        request: parser.parse('Akşam balık olsun'),
        prefs: prefs,
      );
      expect(outcome.kind, PlanChangeKind.preferred);
      final dinner = outcome.plan.firstWhere(
        (m) => m.mealType == MealType.dinner,
      );
      expect(dinner.ingredients, contains(PlanIngredient.fish));
    });

    test('anlaşılmayan istek planı değiştirmez', () {
      final plan = generator.generateDay(day, prefs);
      final outcome = apply(
        day: day,
        plan: plan,
        request: parser.parse('selam'),
        prefs: prefs,
      );
      expect(outcome.kind, PlanChangeKind.notUnderstood);
      expect(outcome.plan, plan);
    });
  });

  test('PlannedMeal JSON gidiş-dönüşü kayıpsız', () {
    final meal = generator.generateDay(day, prefs).first;
    expect(PlannedMeal.fromJson(meal.toJson()), meal);
  });
}

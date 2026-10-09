import 'dart:math';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../models/meal_plan_preferences.dart';
import '../models/meal_template.dart';
import '../models/plan_ingredient.dart';
import '../models/planned_meal.dart';

/// Şablonlardan kalori hedefine ve kısıtlara uygun günlük plan üretir.
///
/// Seçim; kalori hedefine yakınlık, öğle ve akşamda aynı ana protein
/// tekrarının önlenmesi ve çeşitlilik için rastgelelik ile puanlanır.
class MealPlanGenerator {
  const MealPlanGenerator(this.templates);

  final List<MealTemplate> templates;

  static const portionSteps = [0.75, 1.0, 1.25, 1.5];

  /// Aynı gün için tekrar çağrıldığında aynı planı üretir; farklı plan için
  /// [seed] verilir.
  List<PlannedMeal> generateDay(
    DateTime day,
    MealPlanPreferences prefs, {
    int? seed,
  }) {
    final random = Random(seed ?? day.year * 10000 + day.month * 100 + day.day);
    final targets = prefs.calorieTargets;
    final meals = <PlannedMeal>[];
    for (final (index, type) in prefs.slots.indexed) {
      final template = _pick(
        type: type,
        targetKcal: targets[index],
        excluded: prefs.excluded,
        avoidIds: {for (final m in meals) ?m.templateId},
        usedProteins: _mainProteins(meals),
        random: random,
      );
      if (template == null) continue;
      meals.add(
        _build(
          template.$1,
          factor: template.$2,
          id: '${day.dayKey}-$index',
          dayKey: day.dayKey,
          timeMinutes: switch (prefs.eatingWindow) {
            final window? => windowTime(window, prefs.slots.length, index),
            null => defaultTime(prefs.slots, index),
          },
        ),
      );
    }
    return meals;
  }

  /// [meal] yerine seçilebilecek en fazla [count] farklı öneri; en uygunu
  /// önce gelir. Kalori hedefi, öğün tipi ve [prefs] kısıtları korunur.
  List<PlannedMeal> alternativesFor(
    PlannedMeal meal,
    List<PlannedMeal> plan,
    MealPlanPreferences prefs, {
    int count = 3,
    Random? random,
  }) {
    final others = plan.where((m) => m.id != meal.id).toList();
    final avoid = {?meal.templateId, for (final m in others) ?m.templateId};
    final rng = random ?? Random();
    final result = <PlannedMeal>[];
    while (result.length < count) {
      final template = _pick(
        type: meal.mealType,
        targetKcal: meal.nutrition.calories,
        excluded: prefs.excluded,
        avoidIds: avoid,
        usedProteins: _mainProteins(others),
        random: rng,
      );
      if (template == null) break;
      avoid.add(template.$1.id);
      result.add(
        _build(
          template.$1,
          factor: template.$2,
          id: meal.id,
          dayKey: meal.dayKey,
          timeMinutes: meal.timeMinutes,
        ),
      );
    }
    return result;
  }

  /// Öğünleri yeme penceresine yayar: ilk öğün pencere açılınca, son öğün
  /// pencere kapanmadan bir saat önce; aradakiler eşit aralıklı ve yarım
  /// saate yuvarlanmış.
  static int windowTime(EatingWindow window, int count, int index) {
    final first = window.start;
    final last = max(first, window.end - 60);
    if (count <= 1) return first % _minutesPerDay;
    final raw = first + (last - first) * index / (count - 1);
    return ((raw / 30).round() * 30) % _minutesPerDay;
  }

  static const _minutesPerDay = 24 * 60;

  /// [meal] yerine aynı öğün tipinde, kısıtlara uyan başka bir öneri.
  /// [preferred] verilirse yalnızca onu içeren şablonlar seçilir.
  /// Uygun şablon yoksa `null`.
  PlannedMeal? alternativeFor(
    PlannedMeal meal,
    List<PlannedMeal> plan,
    MealPlanPreferences prefs, {
    Set<PlanIngredient> preferred = const {},
    Random? random,
  }) {
    final others = plan.where((m) => m.id != meal.id).toList();
    final template = _pick(
      type: meal.mealType,
      targetKcal: meal.nutrition.calories,
      excluded: prefs.excluded,
      avoidIds: {?meal.templateId, for (final m in others) ?m.templateId},
      usedProteins: _mainProteins(others),
      preferred: preferred,
      random: random ?? Random(),
    );
    if (template == null) return null;
    return _build(
      template.$1,
      factor: template.$2,
      id: meal.id,
      dayKey: meal.dayKey,
      timeMinutes: meal.timeMinutes,
    );
  }

  (MealTemplate, double)? _pick({
    required MealType type,
    required double targetKcal,
    required Set<PlanIngredient> excluded,
    required Set<String> avoidIds,
    required Set<PlanIngredient> usedProteins,
    required Random random,
    Set<PlanIngredient> preferred = const {},
  }) {
    (MealTemplate, double)? best;
    var bestScore = double.infinity;
    for (final t in templates) {
      if (t.mealType != type || avoidIds.contains(t.id)) continue;
      if (!t.allows(excluded)) continue;
      if (preferred.isNotEmpty && !t.ingredients.any(preferred.contains)) {
        continue;
      }
      final factor = _bestFactor(t.nutrition.calories, targetKcal);
      final kcalGap =
          (t.nutrition.calories * factor - targetKcal).abs() / targetKcal;
      final repeatsProtein = t.ingredients
          .where(_proteins.contains)
          .any(usedProteins.contains);
      final score =
          kcalGap + (repeatsProtein ? 0.3 : 0) + random.nextDouble() * 0.35;
      if (score < bestScore) {
        bestScore = score;
        best = (t, factor);
      }
    }
    return best;
  }

  static double _bestFactor(double kcal, double target) {
    if (kcal <= 0) return 1;
    return portionSteps.reduce(
      (a, b) => (kcal * a - target).abs() <= (kcal * b - target).abs() ? a : b,
    );
  }

  static const _proteins = {
    PlanIngredient.chicken,
    PlanIngredient.redMeat,
    PlanIngredient.fish,
    PlanIngredient.legumes,
    PlanIngredient.egg,
  };

  static Set<PlanIngredient> _mainProteins(List<PlannedMeal> meals) => {
    for (final m in meals)
      if (m.mealType == MealType.lunch || m.mealType == MealType.dinner)
        ...m.ingredients.where(_proteins.contains),
  };

  static PlannedMeal _build(
    MealTemplate template, {
    required double factor,
    required String id,
    required String dayKey,
    int? timeMinutes,
  }) => PlannedMeal(
    id: id,
    dayKey: dayKey,
    mealType: template.mealType,
    title: template.title,
    items: template.items,
    nutrition: template.nutrition.scale(factor),
    templateId: template.id,
    portionFactor: factor,
    timeMinutes: timeMinutes,
  );

  /// Ara öğünler bir önceki ana öğüne göre konumlanır.
  static int defaultTime(List<MealType> slots, int index) {
    int main(MealType type) => switch (type) {
      MealType.breakfast => 8 * 60 + 30,
      MealType.lunch => 13 * 60,
      MealType.dinner => 19 * 60 + 30,
      MealType.snack => 16 * 60,
    };
    final type = slots[index];
    if (type != MealType.snack) return main(type);
    for (var i = index - 1; i >= 0; i--) {
      final previous = slots[i];
      if (previous == MealType.snack) continue;
      return switch (previous) {
        MealType.breakfast => 10 * 60 + 30,
        MealType.lunch => 16 * 60,
        _ => 21 * 60 + 30,
      };
    }
    return 10 * 60 + 30;
  }
}

import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../shared/models/enums.dart';
import '../../../shared/models/meal_entry.dart';
import '../../../shared/models/nutrition_targets.dart';

/// Skoru oluşturan faktörler ve 100 puan üzerinden ağırlıkları.
enum ScoreFactor {
  calories(20),
  protein(15),
  fiber(10),
  water(15),
  produce(15),
  processed(10),
  macroBalance(10),
  mealRhythm(5);

  const ScoreFactor(this.maxPoints);

  final int maxPoints;
}

enum ScoreBand {
  starting,
  fair,
  good,
  great;

  static ScoreBand of(int score) => switch (score) {
    >= 80 => great,
    >= 60 => good,
    >= 40 => fair,
    _ => starting,
  };
}

class ScoreComponent extends Equatable {
  const ScoreComponent(this.factor, this.progress);

  final ScoreFactor factor;

  /// 0–1 arası; faktörün tam puana ne kadar yakın olduğu.
  final double progress;

  double get points => progress * factor.maxPoints;

  @override
  List<Object?> get props => [factor, progress];
}

/// Günlük beslenme skoru (0–100). Genel bir alışkanlık göstergesidir;
/// tıbbi değerlendirme yerine geçmez.
class NutritionScore extends Equatable {
  const NutritionScore(this.components);

  final List<ScoreComponent> components;

  int get value => components
      .fold<double>(0, (sum, c) => sum + c.points)
      .round()
      .clamp(0, 100);

  ScoreBand get band => ScoreBand.of(value);

  /// En çok puan kaybedilen faktör; öneri mesajı için kullanılır.
  ScoreComponent? get weakest {
    if (components.isEmpty) return null;
    return components.reduce(
      (a, b) =>
          (a.factor.maxPoints - a.points) >= (b.factor.maxPoints - b.points)
          ? a
          : b,
    );
  }

  @override
  List<Object?> get props => [components];
}

abstract final class NutritionScoreCalculator {
  /// Bir porsiyon sebze/meyve (WHO: 80 g).
  static const produceServingGrams = 80.0;
  static const produceServingsTarget = 5.0;

  /// Kalorinin bu oranı ve üzeri işlenmiş gıdadan geliyorsa puan sıfırlanır.
  static const processedRatioLimit = 0.5;

  /// Ana öğünlerin "geçmiş sayıldığı" saatler.
  static const _mealDeadlines = {
    MealType.breakfast: 10,
    MealType.lunch: 14,
    MealType.dinner: 20,
  };

  static NutritionScore calculate({
    required List<MealEntry> meals,
    required NutritionTargets targets,
    required int waterMl,
    required DateTime now,
  }) {
    var calories = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    var fiber = 0.0;
    var produceGrams = 0.0;
    var processedCalories = 0.0;
    for (final m in meals) {
      calories += m.nutrition.calories;
      protein += m.nutrition.proteinG;
      carbs += m.nutrition.carbsG;
      fat += m.nutrition.fatG;
      fiber += m.nutrition.fiberG ?? 0;
      if (m.tags.contains(FoodTag.vegetable) ||
          m.tags.contains(FoodTag.fruit)) {
        produceGrams += m.quantityGrams;
      }
      if (m.tags.contains(FoodTag.processed)) {
        processedCalories += m.nutrition.calories;
      }
    }

    return NutritionScore([
      ScoreComponent(
        ScoreFactor.calories,
        _calorieProximity(calories, targets.calories),
      ),
      ScoreComponent(ScoreFactor.protein, _ratio(protein, targets.proteinG)),
      ScoreComponent(ScoreFactor.fiber, _ratio(fiber, targets.fiberG)),
      ScoreComponent(
        ScoreFactor.water,
        _ratio(waterMl.toDouble(), targets.waterMl.toDouble()),
      ),
      ScoreComponent(
        ScoreFactor.produce,
        _ratio(produceGrams / produceServingGrams, produceServingsTarget),
      ),
      ScoreComponent(
        ScoreFactor.processed,
        calories <= 0
            ? 0
            : 1 -
                  (processedCalories / calories / processedRatioLimit).clamp(
                    0.0,
                    1.0,
                  ),
      ),
      ScoreComponent(
        ScoreFactor.macroBalance,
        _macroBalance(protein, carbs, fat, targets),
      ),
      ScoreComponent(ScoreFactor.mealRhythm, _mealRhythm(meals, now)),
    ]);
  }

  /// Makroların enerji payının hedef dağılımdan toplam sapması. Bu değere
  /// kadar tam puan verilir; [macroDeviationLimit] ve üzerinde puan sıfırdır.
  static const macroDeviationTolerance = 0.10;
  static const macroDeviationLimit = 0.40;

  static double _macroBalance(
    double protein,
    double carbs,
    double fat,
    NutritionTargets targets,
  ) {
    final energy = protein * 4 + carbs * 4 + fat * 9;
    final targetEnergy =
        targets.proteinG * 4 + targets.carbsG * 4 + targets.fatG * 9;
    if (energy <= 0 || targetEnergy <= 0) return 0;
    final deviation =
        (protein * 4 / energy - targets.proteinG * 4 / targetEnergy).abs() +
        (carbs * 4 / energy - targets.carbsG * 4 / targetEnergy).abs() +
        (fat * 9 / energy - targets.fatG * 9 / targetEnergy).abs();
    if (deviation <= macroDeviationTolerance) return 1;
    return math.max(
      0,
      1 -
          (deviation - macroDeviationTolerance) /
              (macroDeviationLimit - macroDeviationTolerance),
    );
  }

  static double _ratio(double value, double target) =>
      target <= 0 ? 0 : (value / target).clamp(0.0, 1.0);

  /// Hedefin ±%10'u tam puan; altında doğrusal, üstünde %150'de sıfır.
  static double _calorieProximity(double consumed, double target) {
    if (target <= 0) return 0;
    final r = consumed / target;
    if (r < 0.9) return r / 0.9;
    if (r <= 1.1) return 1;
    return math.max(0, 1 - (r - 1.1) / 0.4);
  }

  /// Saati geçmiş ana öğünlerden kaçının kaydedildiği.
  static double _mealRhythm(List<MealEntry> meals, DateTime now) {
    final logged = meals.map((m) => m.mealType).toSet();
    final due = _mealDeadlines.entries
        .where((e) => now.hour >= e.value || logged.contains(e.key))
        .map((e) => e.key)
        .toSet();
    if (due.isEmpty) return meals.isEmpty ? 0 : 1;
    return due.where(logged.contains).length / due.length;
  }
}

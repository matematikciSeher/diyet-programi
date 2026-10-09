import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import 'bmr_formula.dart';

/// Hesaplama sonucunda kullanıcıya gösterilmesi gereken sağlık uyarıları.
enum HealthNotice {
  /// 18 yaş altı: kalori açığı sınırlandırıldı, uzman desteği önerilir.
  minor,

  /// 65 yaş ve üzeri.
  senior,

  /// VKİ < 18.5.
  underweight,

  /// VKİ ≥ 35.
  severeObesity,

  /// Seçilen tarih için gereken hız güvenli sınırın üzerinde; hız düşürüldü.
  paceAdjusted,

  /// Kalori hedefi alt güvenlik sınırına çekildi.
  calorieFloorApplied,

  /// Aralıklı oruç bu profil için dikkat gerektiriyor.
  fastingCaution,
}

class NutritionInput extends Equatable {
  const NutritionInput({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    this.targetWeightKg,
    this.exerciseFrequency = ExerciseFrequency.none,
    this.fastingPreference = FastingPreference.none,
    this.targetDate,
  });

  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final double? targetWeightKg;
  final ActivityLevel activityLevel;
  final ExerciseFrequency exerciseFrequency;
  final GoalType goal;
  final FastingPreference fastingPreference;
  final DateTime? targetDate;

  @override
  List<Object?> get props => [
    gender,
    age,
    heightCm,
    weightKg,
    targetWeightKg,
    activityLevel,
    exerciseFrequency,
    goal,
    fastingPreference,
    targetDate,
  ];
}

class NutritionPlan extends Equatable {
  const NutritionPlan({
    required this.bmr,
    required this.maintenanceCalories,
    required this.targetCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
    required this.bmi,
    required this.weeklyChangeKg,
    required this.notices,
    this.estimatedWeeks,
    this.estimatedGoalDate,
  });

  final int bmr;

  /// TDEE: günlük tahmini enerji ihtiyacı.
  final int maintenanceCalories;
  final int targetCalories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int waterMl;
  final double bmi;

  /// Hedef kaloriyle beklenen haftalık kilo değişimi (negatif = kayıp).
  final double weeklyChangeKg;

  /// Kilo değişimi hedeflenmiyorsa `null`.
  final int? estimatedWeeks;
  final DateTime? estimatedGoalDate;
  final Set<HealthNotice> notices;

  int get calorieDelta => targetCalories - maintenanceCalories;

  @override
  List<Object?> get props => [
    bmr,
    maintenanceCalories,
    targetCalories,
    proteinG,
    carbsG,
    fatG,
    waterMl,
    bmi,
    weeklyChangeKg,
    estimatedWeeks,
    estimatedGoalDate,
    notices,
  ];
}

/// BMR/TDEE ve günlük hedefleri hesaplayan saf (yan etkisiz) servis.
///
/// Güvenlik ilkeleri:
/// * Kilo kaybı en fazla haftada vücut ağırlığının %1'i (≤ 1 kg) hızla,
///   kalori açığı en fazla TDEE'nin %25'i / 1000 kcal ile sınırlıdır.
/// * Hedef kalori hiçbir zaman BMR'nin ve cinsiyete göre asgari değerin
///   (1200 / 1500 kcal) altına inmez.
/// * 18 yaş altında açık %10 ile sınırlıdır.
/// * Kilo alımında fazlalık 500 kcal'i (kas odaklı hedefte 350) aşmaz.
class NutritionCalculator {
  const NutritionCalculator({this.formula = const MifflinStJeorFormula()});

  final BmrFormula formula;

  static const kcalPerKg = 7700.0;
  static const minHealthyBmi = 18.5;
  static const defaultLossPerWeek = 0.5;
  static const defaultGainPerWeek = 0.25;
  static const defaultMusclePerWeek = 0.2;
  static const maxGainPerWeek = 0.5;
  static const maxMuscleGainPerWeek = 0.35;
  static const maxDeficitRatio = 0.25;
  static const maxDeficitRatioMinor = 0.10;
  static const maxDeficitKcal = 1000.0;
  static const maxSurplusKcal = 500.0;
  static const maxMuscleSurplusKcal = 350.0;
  static const minSurplusKcal = 150.0;

  static int calorieFloorFor(Gender gender) => switch (gender) {
    Gender.female => 1200,
    Gender.male => 1500,
    Gender.unspecified => 1350,
  };

  /// Güvenli azami haftalık kilo kaybı (kg).
  static double maxSafeWeeklyLoss(double weightKg) =>
      math.min(1.0, weightKg * 0.01);

  static double bmiOf({required double weightKg, required double heightCm}) {
    final m = heightCm / 100;
    return weightKg / (m * m);
  }

  /// Verilen boy için sağlıklı VKİ alt sınırına karşılık gelen kilo.
  static double minHealthyWeight(double heightCm) {
    final m = heightCm / 100;
    return (minHealthyBmi * m * m * 10).ceil() / 10;
  }

  /// Hedefe varsayılan güvenli hızla ulaşılacak tarih.
  static DateTime? suggestedTargetDate({
    required GoalType goal,
    required double weightKg,
    required double? targetWeightKg,
    DateTime? now,
  }) {
    final target = targetWeightKg;
    if (!goal.changesWeight || target == null) return null;
    final diff = (target - weightKg).abs();
    if (diff < 0.1) return null;
    final rate = switch (goal) {
      GoalType.loseWeight => math.min(
        defaultLossPerWeek,
        maxSafeWeeklyLoss(weightKg),
      ),
      GoalType.buildMuscle => defaultMusclePerWeek,
      _ => defaultGainPerWeek,
    };
    final weeks = (diff / rate).ceil();
    return _dateOnly(now ?? DateTime.now()).add(Duration(days: weeks * 7));
  }

  /// Kiloya ve aktiviteye göre önerilen günlük su (ml, 250'ye yuvarlanmış).
  static int recommendedWaterMl({
    required double weightKg,
    ActivityLevel activityLevel = ActivityLevel.light,
    ExerciseFrequency exerciseFrequency = ExerciseFrequency.none,
  }) {
    var ml = weightKg * 33;
    if (activityLevel.index >= ActivityLevel.active.index) ml += 250;
    if (exerciseFrequency.sessionsPerWeek >= 3) ml += 350;
    ml = ml.clamp(1500, 4000).toDouble();
    return (ml / 250).round() * 250;
  }

  double bmr(NutritionInput input) => formula.calculate(
    gender: input.gender,
    weightKg: input.weightKg,
    heightCm: input.heightCm,
    age: input.age,
  );

  double tdee(NutritionInput input) =>
      bmr(input) * input.activityLevel.multiplier;

  NutritionPlan calculate(NutritionInput input, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final notices = <HealthNotice>{};
    final bmrValue = bmr(input);
    final tdeeValue = bmrValue * input.activityLevel.multiplier;
    final bmi = bmiOf(weightKg: input.weightKg, heightCm: input.heightCm);

    if (input.age < 18) notices.add(HealthNotice.minor);
    if (input.age >= 65) notices.add(HealthNotice.senior);
    if (bmi < minHealthyBmi) notices.add(HealthNotice.underweight);
    if (bmi >= 35) notices.add(HealthNotice.severeObesity);
    if (input.fastingPreference != FastingPreference.none &&
        notices.any(_fastingRisks.contains)) {
      notices.add(HealthNotice.fastingCaution);
    }

    final target = input.targetWeightKg;
    final diffKg = target == null ? 0.0 : target - input.weightKg;
    final weeksToDate = _weeksUntil(input.targetDate, today);

    var targetKcal = tdeeValue;
    switch (input.goal) {
      case GoalType.loseWeight when diffKg < 0:
        final maxRate = maxSafeWeeklyLoss(input.weightKg);
        var rate = weeksToDate == null
            ? math.min(defaultLossPerWeek, maxRate)
            : -diffKg / weeksToDate;
        if (rate > maxRate) {
          rate = maxRate;
          notices.add(HealthNotice.paceAdjusted);
        }
        final ratioCap = input.age < 18
            ? maxDeficitRatioMinor
            : maxDeficitRatio;
        final deficit = math.min(
          rate * kcalPerKg / 7,
          math.min(tdeeValue * ratioCap, maxDeficitKcal),
        );
        targetKcal = tdeeValue - deficit;
        final floor = math.max(
          calorieFloorFor(input.gender).toDouble(),
          bmrValue,
        );
        if (targetKcal < floor) {
          targetKcal = math.min(floor, tdeeValue);
          notices.add(HealthNotice.calorieFloorApplied);
        }
      case GoalType.gainWeight when diffKg > 0:
      case GoalType.buildMuscle when diffKg > 0:
        final isMuscle = input.goal == GoalType.buildMuscle;
        final maxRate = isMuscle ? maxMuscleGainPerWeek : maxGainPerWeek;
        var rate = weeksToDate == null
            ? (isMuscle ? defaultMusclePerWeek : defaultGainPerWeek)
            : diffKg / weeksToDate;
        if (rate > maxRate) {
          rate = maxRate;
          notices.add(HealthNotice.paceAdjusted);
        }
        final surplus = (rate * kcalPerKg / 7).clamp(
          minSurplusKcal,
          isMuscle ? maxMuscleSurplusKcal : maxSurplusKcal,
        );
        targetKcal = tdeeValue + surplus;
      default:
        break;
    }

    final roundedTdee = _roundTo(tdeeValue, 10);
    final roundedTarget = _roundTo(targetKcal, 10);
    final delta = roundedTarget - roundedTdee;
    final weeklyChange = delta * 7 / kcalPerKg;

    int? estimatedWeeks;
    DateTime? estimatedDate;
    final movesTowardTarget =
        (diffKg < 0 && weeklyChange < 0) || (diffKg > 0 && weeklyChange > 0);
    if (input.goal.changesWeight && movesTowardTarget) {
      estimatedWeeks = (diffKg.abs() / weeklyChange.abs()).ceil();
      estimatedDate = today.add(Duration(days: estimatedWeeks * 7));
    }

    final macros = _macros(input, roundedTarget.toDouble());
    return NutritionPlan(
      bmr: bmrValue.round(),
      maintenanceCalories: roundedTdee,
      targetCalories: roundedTarget,
      proteinG: macros.protein,
      carbsG: macros.carbs,
      fatG: macros.fat,
      waterMl: recommendedWaterMl(
        weightKg: input.weightKg,
        activityLevel: input.activityLevel,
        exerciseFrequency: input.exerciseFrequency,
      ),
      bmi: double.parse(bmi.toStringAsFixed(1)),
      weeklyChangeKg: double.parse(weeklyChange.toStringAsFixed(2)),
      estimatedWeeks: estimatedWeeks,
      estimatedGoalDate: estimatedDate,
      notices: Set.unmodifiable(notices),
    );
  }

  static const _fastingRisks = {
    HealthNotice.minor,
    HealthNotice.senior,
    HealthNotice.underweight,
  };

  ({int protein, int carbs, int fat}) _macros(
    NutritionInput input,
    double kcal,
  ) {
    final sessions = input.exerciseFrequency.sessionsPerWeek;
    var gPerKg = switch (input.goal) {
      GoalType.loseWeight => sessions >= 3 ? 1.8 : 1.6,
      GoalType.buildMuscle => sessions >= 5 ? 2.0 : 1.8,
      GoalType.gainWeight => sessions >= 3 ? 1.6 : 1.4,
      GoalType.maintainWeight ||
      GoalType.eatHealthier => sessions >= 3 ? 1.4 : 1.2,
    };
    if (input.age >= 65) gPerKg = math.max(gPerKg, 1.2);

    // Obezitede protein, düzeltilmiş vücut ağırlığına göre hesaplanır.
    final bmi = bmiOf(weightKg: input.weightKg, heightCm: input.heightCm);
    final m = input.heightCm / 100;
    final idealWeight = 22 * m * m;
    final refWeight = bmi >= 30
        ? idealWeight + 0.4 * (input.weightKg - idealWeight)
        : input.weightKg;

    final proteinKcal = math.min(refWeight * gPerKg * 4, kcal * 0.35);
    final fatRatio = switch (input.goal) {
      GoalType.buildMuscle || GoalType.gainWeight => 0.27,
      _ => 0.30,
    };
    final fatKcal = kcal * fatRatio;
    final carbKcal = math.max(0, kcal - proteinKcal - fatKcal);
    return (
      protein: (proteinKcal / 4).round(),
      carbs: (carbKcal / 4).round(),
      fat: (fatKcal / 9).round(),
    );
  }

  static double? _weeksUntil(DateTime? date, DateTime today) {
    if (date == null) return null;
    final days = _dateOnly(date).difference(today).inDays;
    if (days <= 0) return null;
    return days / 7;
  }

  static int _roundTo(double value, int step) => (value / step).round() * step;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final bmrFormulaProvider = Provider<BmrFormula>(
  (ref) => const MifflinStJeorFormula(),
);

final nutritionCalculatorProvider = Provider<NutritionCalculator>(
  (ref) => NutritionCalculator(formula: ref.watch(bmrFormulaProvider)),
);

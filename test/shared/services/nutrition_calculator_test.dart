import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/services/nutrition/bmr_formula.dart';
import 'package:diyet_programi/shared/services/nutrition/nutrition_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = NutritionCalculator();
  final now = DateTime(2026, 9, 28);

  NutritionInput input({
    Gender gender = Gender.female,
    int age = 30,
    double height = 165,
    double weight = 70,
    double? target = 62,
    ActivityLevel activity = ActivityLevel.moderate,
    ExerciseFrequency exercise = ExerciseFrequency.none,
    GoalType goal = GoalType.loseWeight,
    FastingPreference fasting = FastingPreference.none,
    DateTime? targetDate,
  }) => NutritionInput(
    gender: gender,
    age: age,
    heightCm: height,
    weightKg: weight,
    targetWeightKg: target,
    activityLevel: activity,
    exerciseFrequency: exercise,
    goal: goal,
    fastingPreference: fasting,
    targetDate: targetDate,
  );

  int macroKcal(NutritionPlan p) => p.proteinG * 4 + p.carbsG * 4 + p.fatG * 9;

  group('BMR formülleri', () {
    test('Mifflin-St Jeor erkek ve kadın için standart değerleri verir', () {
      const f = MifflinStJeorFormula();
      expect(
        f.calculate(gender: Gender.male, weightKg: 80, heightCm: 180, age: 25),
        closeTo(1805, 0.01),
      );
      expect(
        f.calculate(
          gender: Gender.female,
          weightKg: 70,
          heightCm: 165,
          age: 30,
        ),
        closeTo(1420.25, 0.01),
      );
    });

    test('Harris-Benedict (revize) erkek değeri', () {
      expect(
        const HarrisBenedictFormula().calculate(
          gender: Gender.male,
          weightKg: 80,
          heightCm: 180,
          age: 25,
        ),
        closeTo(1882.02, 0.05),
      );
    });

    test('belirtilmemiş cinsiyet iki değerin ortalamasıdır', () {
      const f = MifflinStJeorFormula();
      double of(Gender g) =>
          f.calculate(gender: g, weightKg: 70, heightCm: 170, age: 40);
      expect(
        of(Gender.unspecified),
        closeTo((of(Gender.male) + of(Gender.female)) / 2, 0.01),
      );
    });

    test('formül değiştirilebilir', () {
      const alt = NutritionCalculator(formula: HarrisBenedictFormula());
      expect(alt.bmr(input()), isNot(closeTo(calculator.bmr(input()), 1)));
    });
  });

  group('kilo verme', () {
    test('varsayılan tempo haftada 0,5 kg ve TDEE = BMR × PAL', () {
      final plan = calculator.calculate(input(), now: now);
      expect(plan.bmr, 1420);
      expect(plan.maintenanceCalories, 2200);
      expect(plan.targetCalories, 1650);
      expect(plan.weeklyChangeKg, closeTo(-0.5, 0.01));
      expect(plan.estimatedWeeks, 16);
      expect(plan.estimatedGoalDate, now.add(const Duration(days: 16 * 7)));
      expect(plan.notices, isEmpty);
    });

    test('agresif hedef tarih güvenli tempoya ve alt sınıra çekilir', () {
      final plan = calculator.calculate(
        input(
          weight: 60,
          height: 160,
          target: 50,
          activity: ActivityLevel.sedentary,
          targetDate: now.add(const Duration(days: 14)),
        ),
        now: now,
      );
      expect(plan.notices, contains(HealthNotice.paceAdjusted));
      expect(plan.notices, contains(HealthNotice.calorieFloorApplied));
      expect(plan.targetCalories, greaterThanOrEqualTo(plan.bmr));
      expect(plan.targetCalories, greaterThanOrEqualTo(1200));
    });

    test('açık hiçbir zaman TDEE\'nin %25\'ini veya 1000 kcal\'i aşmaz', () {
      final plan = calculator.calculate(
        input(
          gender: Gender.male,
          weight: 140,
          height: 185,
          target: 90,
          activity: ActivityLevel.veryActive,
          targetDate: now.add(const Duration(days: 30)),
        ),
        now: now,
      );
      final deficit = -plan.calorieDelta;
      expect(deficit, lessThanOrEqualTo(1000));
      expect(deficit, lessThanOrEqualTo(plan.maintenanceCalories * 0.25 + 10));
      expect(plan.weeklyChangeKg.abs(), lessThanOrEqualTo(1.0));
      expect(plan.notices, contains(HealthNotice.severeObesity));
    });

    test('18 yaş altında açık %10 ile sınırlıdır', () {
      final plan = calculator.calculate(input(age: 16), now: now);
      expect(plan.notices, contains(HealthNotice.minor));
      expect(
        -plan.calorieDelta,
        lessThanOrEqualTo(plan.maintenanceCalories * 0.10 + 10),
      );
    });

    test('uzak hedef tarih daha yavaş tempo üretir', () {
      final plan = calculator.calculate(
        input(targetDate: now.add(const Duration(days: 7 * 40))),
        now: now,
      );
      expect(plan.weeklyChangeKg.abs(), closeTo(0.2, 0.02));
      expect(plan.notices, isNot(contains(HealthNotice.paceAdjusted)));
    });
  });

  group('diğer hedefler', () {
    test('koruma ve sağlıklı beslenmede hedef = TDEE, süre yok', () {
      for (final goal in [GoalType.maintainWeight, GoalType.eatHealthier]) {
        final plan = calculator.calculate(
          input(goal: goal, target: 70),
          now: now,
        );
        expect(plan.targetCalories, plan.maintenanceCalories);
        expect(plan.estimatedWeeks, isNull);
      }
    });

    test('kilo almada fazlalık 500 kcal ile sınırlıdır', () {
      final plan = calculator.calculate(
        input(
          goal: GoalType.gainWeight,
          weight: 55,
          target: 65,
          targetDate: now.add(const Duration(days: 14)),
        ),
        now: now,
      );
      expect(plan.calorieDelta, inInclusiveRange(150, 500));
      expect(plan.notices, contains(HealthNotice.paceAdjusted));
      expect(plan.estimatedWeeks, isNotNull);
    });

    test('kas geliştirmede fazlalık ≤ 350 kcal, protein ≥ 1,8 g/kg', () {
      final plan = calculator.calculate(
        input(
          gender: Gender.male,
          goal: GoalType.buildMuscle,
          weight: 75,
          height: 180,
          target: 80,
          exercise: ExerciseFrequency.fiveToSix,
        ),
        now: now,
      );
      expect(plan.calorieDelta, inInclusiveRange(150, 350));
      expect(plan.proteinG, greaterThanOrEqualTo(75 * 1.8));
    });
  });

  group('makrolar ve su', () {
    test('makro kalorileri hedef kaloriyle uyumludur', () {
      for (final goal in GoalType.values) {
        final plan = calculator.calculate(
          input(goal: goal, target: goal == GoalType.loseWeight ? 62 : 75),
          now: now,
        );
        expect(
          macroKcal(plan),
          closeTo(plan.targetCalories, 15),
          reason: goal.name,
        );
      }
    });

    test('su hedefi kiloya göre ve 250 ml katıdır', () {
      final ml = NutritionCalculator.recommendedWaterMl(weightKg: 70);
      expect(ml % 250, 0);
      expect(ml, inInclusiveRange(2000, 2750));
      expect(
        NutritionCalculator.recommendedWaterMl(weightKg: 300),
        lessThanOrEqualTo(4000),
      );
    });

    test('düşük kilolu profilde aralıklı oruç uyarısı', () {
      final plan = calculator.calculate(
        input(
          weight: 48,
          height: 170,
          goal: GoalType.gainWeight,
          target: 55,
          fasting: FastingPreference.sixteenEight,
        ),
        now: now,
      );
      expect(plan.notices, contains(HealthNotice.underweight));
      expect(plan.notices, contains(HealthNotice.fastingCaution));
    });
  });

  test('sağlıklı kilo alt sınırı VKİ 18,5\'e karşılık gelir', () {
    expect(NutritionCalculator.minHealthyWeight(170), closeTo(53.5, 0.1));
  });
}

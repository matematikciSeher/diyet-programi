import 'package:diyet_programi/features/dashboard/domain/nutrition_score.dart';
import 'package:diyet_programi/features/meals/domain/models/daily_log.dart';
import 'package:diyet_programi/features/meals/domain/models/daily_nutrition_score.dart';
import 'package:diyet_programi/features/meals/domain/services/daily_nutrition_score_service.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/nutrition_targets.dart';
import 'package:diyet_programi/shared/models/water_log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diary_test_utils.dart';

const _targets = NutritionTargets(
  calories: 2000,
  proteinG: 100,
  carbsG: 250,
  fatG: 60,
  fiberG: 25,
  waterMl: 2000,
);

void main() {
  final day = DateTime(2026, 9, 28);

  DailyLog log() => DailyLog.fromEntries(
    date: day,
    entries: [
      entry(MealType.breakfast, kcal: 300, protein: 20, carbs: 30, fat: 10),
      entry(MealType.breakfast, kcal: 150, protein: 5, carbs: 20, fat: 5),
      entry(MealType.lunch, kcal: 600, protein: 40, carbs: 60, fat: 20),
      entry(MealType.snack, kcal: 100, protein: 2, carbs: 15, fat: 3),
    ],
    waterLogs: [
      WaterLog(id: 'a', dayKey: day.toString(), amountMl: 250, loggedAt: day),
      WaterLog(id: 'b', dayKey: day.toString(), amountMl: 500, loggedAt: day),
    ],
  );

  group('DailyLog', () {
    test('günlük kalori tüm öğünlerin toplamıdır', () {
      expect(log().totals.calories, 1150);
    });

    test('öğün toplamı yalnızca o öğünün kayıtlarını içerir', () {
      final l = log();
      expect(l.meal(MealType.breakfast).total.calories, 450);
      expect(l.meal(MealType.breakfast).entries, hasLength(2));
      expect(l.meal(MealType.dinner).isEmpty, isTrue);
      expect(l.meal(MealType.dinner).total, NutritionFacts.zero);
    });

    test('makrolar doğru toplanır', () {
      final totals = log().totals;
      expect(totals.proteinG, 67);
      expect(totals.carbsG, 125);
      expect(totals.fatG, 38);
    });

    test('öğünler sabit sırada ve her zaman bulunur', () {
      expect(log().meals.map((m) => m.type), MealType.values);
      expect(DailyLog.empty(day).meals, hasLength(MealType.values.length));
    });

    test('su miktarı kayıtların toplamıdır', () {
      expect(log().waterAmount, 750);
    });

    test('boş gün boş sayılır; sadece su varsa boş değildir', () {
      expect(DailyLog.empty(day).isEmpty, isTrue);
      expect(DailyLog.empty(day).totals.calories, 0);
      expect(log().isEmpty, isFalse);
    });

    test('JSON ile gidip gelir', () {
      final original = log();
      final restored = DailyLog.fromJson(original.toJson());
      expect(restored.totals, original.totals);
      expect(restored.waterAmount, original.waterAmount);
      expect(restored.date, original.date);
    });
  });

  group('DailyNutritionScoreService', () {
    const service = DailyNutritionScoreService();

    test('Dashboard skoruyla aynı değeri üretir', () {
      final l = log();
      final score = service.calculate(log: l, targets: _targets, now: testNow);
      final dashboard = NutritionScoreCalculator.calculate(
        meals: l.entries,
        targets: _targets,
        waterMl: l.waterAmount,
        now: testNow,
      );
      expect(score.value, dashboard.value);
      expect(score.value, inInclusiveRange(0, 100));
    });

    test('boş gün 0 puan alır ve tüm faktörler eksiktir', () {
      final score = service.calculate(
        log: DailyLog.empty(day),
        targets: _targets,
        now: testNow,
      );
      expect(score.value, 0);
      expect(
        score.checks.map((c) => c.status),
        everyElement(ScoreFactorStatus.missed),
      );
    });

    test('özet kartında istenen faktörler yer alır', () {
      final score = service.calculate(
        log: log(),
        targets: _targets,
        now: testNow,
      );
      expect(
        score.checks.map((c) => c.factor),
        DailyNutritionScoreService.highlightedFactors,
      );
    });

    test('hedefe uygun makro dağılımı dengeli sayılır', () {
      // 2000 kcal: %20 protein, %50 karbonhidrat, %27 yağ = hedef oranları.
      final balanced = DailyLog.fromEntries(
        date: day,
        entries: [
          entry(MealType.lunch, kcal: 2000, protein: 100, carbs: 250, fat: 60),
        ],
      );
      final unbalanced = DailyLog.fromEntries(
        date: day,
        entries: [entry(MealType.lunch, kcal: 2000, fat: 220)],
      );
      double macro(DailyLog l) => service
          .calculate(log: l, targets: _targets, now: testNow)
          .checks
          .firstWhere((c) => c.factor == ScoreFactor.macroBalance)
          .progress;
      expect(macro(balanced), 1);
      expect(macro(unbalanced), lessThan(0.2));
    });

    test('durum eşikleri', () {
      expect(DailyNutritionScoreService.statusOf(1), ScoreFactorStatus.met);
      expect(
        DailyNutritionScoreService.statusOf(0.5),
        ScoreFactorStatus.partial,
      );
      expect(
        DailyNutritionScoreService.statusOf(0.1),
        ScoreFactorStatus.missed,
      );
    });

    test(
      'geçmiş gün gün sonuna, gelecek gün gün başına göre değerlendirilir',
      () {
        final past = DailyNutritionScoreService.referenceTime(
          DateTime(2026, 9, 20),
          testNow,
        );
        final future = DailyNutritionScoreService.referenceTime(
          DateTime(2026, 9, 30),
          testNow,
        );
        expect(past, DateTime(2026, 9, 20, 23, 59));
        expect(future, DateTime(2026, 9, 30));
        expect(DailyNutritionScoreService.referenceTime(day, testNow), testNow);
      },
    );
  });
}

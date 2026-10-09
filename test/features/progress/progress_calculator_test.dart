import 'package:diyet_programi/core/utils/extensions/date_extensions.dart';
import 'package:diyet_programi/features/progress/domain/models/progress_report.dart';
import 'package:diyet_programi/features/progress/domain/services/progress_calculator.dart';
import 'package:diyet_programi/shared/models/body_measurement.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/nutrition_targets.dart';
import 'package:diyet_programi/shared/models/user_profile.dart';
import 'package:diyet_programi/shared/models/water_log.dart';
import 'package:diyet_programi/shared/models/weight_entry.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 9, 28, 14, 30);
const targets = NutritionTargets(
  calories: 2000,
  proteinG: 100,
  carbsG: 250,
  fatG: 67,
  waterMl: 2000,
);

DateTime daysAgo(int n, [int hour = 9]) =>
    DateTime(now.year, now.month, now.day - n, hour);

WeightEntry weight(int daysBack, double kg) =>
    WeightEntry(id: 'w$daysBack', weightKg: kg, recordedAt: daysAgo(daysBack));

MealEntry meal(int daysBack, {double kcal = 2000, double protein = 100}) {
  final at = daysAgo(daysBack, 12);
  return MealEntry(
    id: 'm$daysBack-$kcal',
    dayKey: at.dayKey,
    mealType: MealType.lunch,
    name: 'Yemek',
    quantityGrams: 300,
    nutrition: NutritionFacts(
      calories: kcal,
      proteinG: protein,
      carbsG: 0,
      fatG: 0,
    ),
    loggedAt: at,
  );
}

WaterLog water(int daysBack, int ml) {
  final at = daysAgo(daysBack, 10);
  return WaterLog(
    id: 'water$daysBack',
    dayKey: at.dayKey,
    amountMl: ml,
    loggedAt: at,
  );
}

UserProfile profile({
  double? weight,
  double? targetWeight,
  DateTime? createdAt,
  GoalType? goal,
}) => UserProfile(
  id: 'u1',
  createdAt: createdAt ?? now,
  updatedAt: now,
  weight: weight,
  targetWeight: targetWeight,
  goal: goal,
);

ProgressReport build({
  ProgressRange range = ProgressRange.week,
  UserProfile? user,
  List<WeightEntry> weights = const [],
  List<BodyMeasurement> measurements = const [],
  List<MealEntry> meals = const [],
  List<WaterLog> waterLogs = const [],
}) => ProgressCalculator.build(
  range: range,
  now: now,
  targets: targets,
  profile: user,
  weightEntries: weights,
  measurements: measurements,
  meals: meals,
  waterLogs: waterLogs,
);

void main() {
  group('kilo', () {
    test('başlangıç, güncel, verilen ve kalan kilo hesaplanır', () {
      final report = build(
        user: profile(targetWeight: 70, createdAt: daysAgo(40)),
        weights: [weight(0, 76), weight(30, 80), weight(10, 77.5)],
      );
      final w = report.weight!;
      expect(w.startKg, 80);
      expect(w.currentKg, 76);
      expect(w.direction, WeightDirection.lose);
      expect(w.achievedKg, 4);
      expect(w.remainingKg, 6);
      expect(w.fraction, closeTo(0.4, 1e-9));
      expect(w.reached, isFalse);
    });

    test('onboarding kilosu ilk kayıttan önceyse başlangıç sayılır', () {
      final report = build(
        user: profile(weight: 82, targetWeight: 75, createdAt: daysAgo(60)),
        weights: [weight(5, 79)],
      );
      expect(report.weight!.startKg, 82);
      expect(report.weight!.currentKg, 79);
    });

    test('kilo alma hedefinde kalan kilo hedefe doğru ölçülür', () {
      final report = build(
        user: profile(targetWeight: 65, createdAt: daysAgo(40)),
        weights: [weight(20, 60), weight(0, 62)],
      );
      final w = report.weight!;
      expect(w.direction, WeightDirection.gain);
      expect(w.achievedKg, 2);
      expect(w.remainingKg, 3);
    });

    test('hedef aşılınca kalan 0 olur ve hedefe ulaşılmış sayılır', () {
      final report = build(
        user: profile(targetWeight: 70, createdAt: daysAgo(40)),
        weights: [weight(20, 74), weight(0, 69.5)],
      );
      expect(report.weight!.remainingKg, 0);
      expect(report.weight!.reached, isTrue);
      expect(report.weight!.fraction, 1);
    });

    test('kilo bilgisi yoksa özet boştur', () {
      expect(build().weight, isNull);
    });

    test('grafik yalnızca seçili dönemin noktalarını içerir', () {
      final report = build(
        weights: [weight(20, 80), weight(6, 79), weight(0, 78)],
      );
      expect(report.weightPoints.map((p) => p.kg), [79, 78]);
    });

    test('haftalık ortalama önceki haftayla karşılaştırılır', () {
      final report = build(
        weights: [weight(12, 81), weight(8, 80), weight(5, 79), weight(1, 78)],
      );
      expect(report.weeklyAverage.weightKg, 78.5);
      expect(report.weeklyAverage.previousWeightKg, 80.5);
      expect(report.weeklyAverage.weightChangeKg, -2);
    });
  });

  group('günlük kayıtlar', () {
    test('uyum oranları tamamlanmış ve kayıtlı günlerden hesaplanır', () {
      final report = build(
        meals: [
          meal(0, kcal: 500, protein: 20), // bugün: hesaba katılmaz
          meal(1), // hedefte
          meal(2, kcal: 2150, protein: 85), // kalori ±%10 içinde, protein düşük
          meal(3, kcal: 2600, protein: 120), // kalori fazla
        ],
        waterLogs: [water(1, 2000), water(2, 1500), water(5, 2500)],
      );
      // 1, 2, 3 ve 5 gün önce kayıt var; 4, 6, 7 kayıtsız.
      expect(
        report.calorieAdherence,
        const Adherence(hitDays: 2, trackedDays: 4),
      );
      expect(
        report.proteinAdherence,
        const Adherence(hitDays: 2, trackedDays: 4),
      );
      expect(
        report.waterAdherence,
        const Adherence(hitDays: 2, trackedDays: 4),
      );
    });

    test('skor geçmişi bugünle biten dönem kadar gün içerir', () {
      final report = build(meals: [meal(0), meal(2)]);
      expect(report.days, hasLength(7));
      expect(report.days.last.day, now.startOfDay);
      expect(report.days.last.score, isNotNull);
      expect(report.days[report.days.length - 2].score, isNull);
      expect(report.days[report.days.length - 3].score, isNotNull);
      expect(report.averageScore, isNotNull);
    });

    test('haftalık kalori ortalaması bugünü içermez', () {
      final report = build(
        meals: [meal(0, kcal: 400), meal(1, kcal: 1800), meal(3, kcal: 2200)],
      );
      expect(report.weeklyAverage.calories, 2000);
    });
  });

  test('ölçüler ilk ve son değerle karşılaştırılır', () {
    final report = build(
      measurements: [
        BodyMeasurement(
          id: 'b',
          recordedAt: daysAgo(0),
          waistCm: 88,
          bodyFatPercent: 25,
        ),
        BodyMeasurement(
          id: 'a',
          recordedAt: daysAgo(30),
          waistCm: 92,
          hipCm: 104,
        ),
      ],
    );
    expect(report.waist!.latest, 88);
    expect(report.waist!.change, -4);
    expect(report.measurements.map((m) => m.field), [
      MeasurementField.waist,
      MeasurementField.hip,
      MeasurementField.bodyFat,
    ]);
    final hip = report.measurements[1];
    expect(hip.change, 0);
  });
}

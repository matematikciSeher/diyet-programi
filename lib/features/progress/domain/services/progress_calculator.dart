import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../dashboard/domain/nutrition_score.dart';
import '../models/progress_report.dart';

/// Ham kayıtlardan [ProgressReport] üretir. Saf fonksiyondur; tarih
/// hesapları yerel gün sınırlarına göre yapılır.
abstract final class ProgressCalculator {
  /// Kalori hedefinin ±%10'u "hedefte" sayılır (skordaki tam puan aralığı).
  static const calorieTolerance = 0.10;

  /// Protein hedefinin en az %90'ı alınmışsa gün başarılı sayılır.
  static const proteinThreshold = 0.90;

  /// Uyum oranları ve haftalık ortalama için bugünden önceki gün sayısı
  /// kadar geçmiş gerekir; sağlayıcı bu aralığı yükler.
  static DateTime historyStart(DateTime now, ProgressRange range) =>
      _dayOffset(now, -range.days);

  static ProgressReport build({
    required ProgressRange range,
    required DateTime now,
    required NutritionTargets targets,
    required List<WeightEntry> weightEntries,
    required List<BodyMeasurement> measurements,
    required List<MealEntry> meals,
    required List<WaterLog> waterLogs,
    UserProfile? profile,
  }) {
    final today = now.startOfDay;
    final series = _weightSeries(weightEntries, profile);
    final days = _days(
      today: today,
      now: now,
      count: range.days + 1,
      targets: targets,
      meals: meals,
      waterLogs: waterLogs,
    );
    final completed = days.sublist(0, days.length - 1);

    final rangeStart = _dayOffset(today, -(range.days - 1));
    return ProgressReport(
      range: range,
      targets: targets,
      goal: profile?.goal,
      weight: _weightProgress(series, profile),
      weightPoints: [
        for (final p in series)
          if (!p.date.isBefore(rangeStart)) p,
      ],
      weeklyAverage: _weeklyAverage(series, completed, today),
      measurements: _measurementTrends(measurements),
      days: days.sublist(days.length - range.days),
      calorieAdherence: _adherence(completed, (d) {
        if (d.mealCount == 0 || targets.calories <= 0) return false;
        final r = d.calories / targets.calories;
        return (r - 1).abs() <= calorieTolerance;
      }),
      proteinAdherence: _adherence(
        completed,
        (d) =>
            d.mealCount > 0 &&
            d.proteinG >= targets.proteinG * proteinThreshold,
      ),
      waterAdherence: _adherence(
        completed,
        (d) => d.waterMl >= targets.waterMl,
      ),
    );
  }

  static DateTime _dayOffset(DateTime day, int offset) =>
      DateTime(day.year, day.month, day.day + offset);

  /// Kayıtlar eskiden yeniye. Profil kilosu ilk kayıttan önce girildiyse
  /// (ör. onboarding) başlangıç noktası olarak eklenir.
  static List<WeightPoint> _weightSeries(
    List<WeightEntry> entries,
    UserProfile? profile,
  ) {
    final points = [
      for (final e in entries) WeightPoint(e.recordedAt, e.weightKg),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final baseline = profile?.effectiveStartWeight;
    if (baseline != null &&
        (points.isEmpty || profile!.createdAt.isBefore(points.first.date))) {
      points.insert(0, WeightPoint(profile!.createdAt, baseline));
    }
    return points;
  }

  static WeightProgress? _weightProgress(
    List<WeightPoint> series,
    UserProfile? profile,
  ) {
    if (series.isEmpty) return null;
    final start = series.first.kg;
    final target = profile?.targetWeight;
    final WeightDirection direction;
    if (target != null && target != start) {
      direction = target < start ? WeightDirection.lose : WeightDirection.gain;
    } else {
      direction = switch (profile?.goal) {
        GoalType.gainWeight || GoalType.buildMuscle => WeightDirection.gain,
        _ => WeightDirection.lose,
      };
    }
    return WeightProgress(
      startKg: start,
      currentKg: series.last.kg,
      targetKg: target,
      direction: direction,
    );
  }

  static WeeklyAverage _weeklyAverage(
    List<WeightPoint> series,
    List<DailyProgress> completed,
    DateTime today,
  ) {
    final weekStart = _dayOffset(today, -6);
    final previousStart = _dayOffset(today, -13);
    double? avg(Iterable<double> values) =>
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

    final lastSeven = completed.skip(completed.length - 7);
    return WeeklyAverage(
      weightKg: avg(
        series.where((p) => !p.date.isBefore(weekStart)).map((p) => p.kg),
      ),
      previousWeightKg: avg(
        series
            .where(
              (p) =>
                  !p.date.isBefore(previousStart) && p.date.isBefore(weekStart),
            )
            .map((p) => p.kg),
      ),
      calories: avg(
        lastSeven.where((d) => d.mealCount > 0).map((d) => d.calories),
      ),
      score: avg(
        lastSeven.map((d) => d.score?.value.toDouble()).whereType<double>(),
      ),
    );
  }

  static List<MeasurementTrend> _measurementTrends(
    List<BodyMeasurement> measurements,
  ) {
    final sorted = [...measurements]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return [
      for (final field in MeasurementField.values) ?_trend(field, sorted),
    ];
  }

  static MeasurementTrend? _trend(
    MeasurementField field,
    List<BodyMeasurement> sorted,
  ) {
    final withValue = sorted.where((m) => field.valueOf(m) != null).toList();
    if (withValue.isEmpty) return null;
    return MeasurementTrend(
      field: field,
      first: field.valueOf(withValue.first)!,
      latest: field.valueOf(withValue.last)!,
      latestAt: withValue.last.recordedAt,
    );
  }

  /// [today] dahil geriye doğru [count] gün, eskiden yeniye.
  static List<DailyProgress> _days({
    required DateTime today,
    required DateTime now,
    required int count,
    required NutritionTargets targets,
    required List<MealEntry> meals,
    required List<WaterLog> waterLogs,
  }) {
    final mealsByDay = <String, List<MealEntry>>{};
    for (final m in meals) {
      (mealsByDay[m.dayKey] ??= []).add(m);
    }
    final waterByDay = <String, List<WaterLog>>{};
    for (final w in waterLogs) {
      (waterByDay[w.dayKey] ??= []).add(w);
    }

    return [
      for (var i = count - 1; i >= 0; i--)
        _day(
          day: _dayOffset(today, -i),
          isToday: i == 0,
          now: now,
          targets: targets,
          meals: mealsByDay[_dayOffset(today, -i).dayKey] ?? const [],
          water: waterByDay[_dayOffset(today, -i).dayKey] ?? const [],
        ),
    ];
  }

  static DailyProgress _day({
    required DateTime day,
    required bool isToday,
    required DateTime now,
    required NutritionTargets targets,
    required List<MealEntry> meals,
    required List<WaterLog> water,
  }) {
    var calories = 0.0;
    var protein = 0.0;
    for (final m in meals) {
      calories += m.nutrition.calories;
      protein += m.nutrition.proteinG;
    }
    final waterMl = water.fold(0, (sum, w) => sum + w.amountMl);
    final tracked = meals.isNotEmpty || water.isNotEmpty;
    return DailyProgress(
      day: day,
      calories: calories,
      proteinG: protein,
      waterMl: waterMl,
      mealCount: meals.length,
      waterLogCount: water.length,
      score: tracked
          ? NutritionScoreCalculator.calculate(
              meals: meals,
              targets: targets,
              waterMl: waterMl,
              // Geçmiş günler gün sonundaki haliyle puanlanır.
              now: isToday
                  ? now
                  : DateTime(day.year, day.month, day.day, 23, 59),
            )
          : null,
    );
  }

  static Adherence _adherence(
    List<DailyProgress> days,
    bool Function(DailyProgress) hit,
  ) {
    final tracked = days.where((d) => d.tracked);
    return Adherence(
      hitDays: tracked.where(hit).length,
      trackedDays: tracked.length,
    );
  }
}

import 'package:equatable/equatable.dart';

import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../dashboard/domain/nutrition_score.dart';

/// İlerleme ekranında grafik ve uyum oranlarının kapsadığı dönem.
enum ProgressRange {
  week(7),
  month(30),
  quarter(90);

  const ProgressRange(this.days);

  final int days;
}

class WeightPoint extends Equatable {
  const WeightPoint(this.date, this.kg);

  final DateTime date;
  final double kg;

  @override
  List<Object?> get props => [date, kg];
}

enum WeightDirection { lose, gain }

/// Başlangıç, güncel ve hedef kilo arasındaki ilişki.
class WeightProgress extends Equatable {
  const WeightProgress({
    required this.startKg,
    required this.currentKg,
    required this.direction,
    this.targetKg,
  });

  final double startKg;
  final double currentKg;
  final double? targetKg;
  final WeightDirection direction;

  /// Hedef yönünde kat edilen mesafe (kilo verme hedefinde verilen kilo).
  /// Ters yönde değişim negatif olur.
  double get achievedKg => direction == WeightDirection.lose
      ? startKg - currentKg
      : currentKg - startKg;

  /// Hedefe ulaşıldıysa 0.
  double? get remainingKg {
    final target = targetKg;
    if (target == null) return null;
    final left = direction == WeightDirection.lose
        ? currentKg - target
        : target - currentKg;
    return left < 0 ? 0 : left;
  }

  /// 0–1 arası; hedef yoksa `null`.
  double? get fraction {
    final target = targetKg;
    if (target == null) return null;
    final total = (target - startKg).abs();
    if (total == 0) return 1;
    return (achievedKg / total).clamp(0.0, 1.0);
  }

  bool get reached => remainingKg == 0;

  @override
  List<Object?> get props => [startKg, currentKg, targetKg, direction];
}

/// Son 7 günün ortalaması ve önceki 7 günle karşılaştırması.
class WeeklyAverage extends Equatable {
  const WeeklyAverage({
    this.weightKg,
    this.previousWeightKg,
    this.calories,
    this.score,
  });

  final double? weightKg;
  final double? previousWeightKg;

  /// Öğün kaydı olan tamamlanmış günlerin günlük ortalaması.
  final double? calories;
  final double? score;

  double? get weightChangeKg {
    final current = weightKg;
    final previous = previousWeightKg;
    if (current == null || previous == null) return null;
    return current - previous;
  }

  @override
  List<Object?> get props => [weightKg, previousWeightKg, calories, score];
}

enum MeasurementField {
  waist,
  hip,
  chest,
  neck,
  arm,
  thigh,
  bodyFat;

  double? valueOf(BodyMeasurement m) => switch (this) {
    waist => m.waistCm,
    hip => m.hipCm,
    chest => m.chestCm,
    neck => m.neckCm,
    arm => m.armCm,
    thigh => m.thighCm,
    bodyFat => m.bodyFatPercent,
  };
}

/// Bir ölçünün ilk ve son kaydı.
class MeasurementTrend extends Equatable {
  const MeasurementTrend({
    required this.field,
    required this.latest,
    required this.first,
    required this.latestAt,
  });

  final MeasurementField field;
  final double latest;
  final double first;
  final DateTime latestAt;

  double get change => latest - first;

  @override
  List<Object?> get props => [field, latest, first, latestAt];
}

/// Tek bir günün beslenme özeti.
class DailyProgress extends Equatable {
  const DailyProgress({
    required this.day,
    required this.calories,
    required this.proteinG,
    required this.waterMl,
    required this.mealCount,
    required this.waterLogCount,
    this.score,
  });

  final DateTime day;
  final double calories;
  final double proteinG;
  final int waterMl;
  final int mealCount;
  final int waterLogCount;

  /// Kayıt olmayan günlerde `null`.
  final NutritionScore? score;

  bool get tracked => mealCount > 0 || waterLogCount > 0;

  @override
  List<Object?> get props => [
    day,
    calories,
    proteinG,
    waterMl,
    mealCount,
    waterLogCount,
    score,
  ];
}

/// Hedefin tuttuğu gün sayısı / kayıt girilen gün sayısı.
class Adherence extends Equatable {
  const Adherence({required this.hitDays, required this.trackedDays});

  final int hitDays;
  final int trackedDays;

  double? get ratio => trackedDays == 0 ? null : hitDays / trackedDays;

  @override
  List<Object?> get props => [hitDays, trackedDays];
}

class ProgressReport extends Equatable {
  const ProgressReport({
    required this.range,
    required this.targets,
    required this.weightPoints,
    required this.weeklyAverage,
    required this.measurements,
    required this.days,
    required this.calorieAdherence,
    required this.proteinAdherence,
    required this.waterAdherence,
    this.weight,
    this.goal,
  });

  final ProgressRange range;
  final NutritionTargets targets;
  final GoalType? goal;

  /// `null`: hiç kilo bilgisi yok.
  final WeightProgress? weight;

  /// Seçili dönemdeki kilo noktaları, eskiden yeniye.
  final List<WeightPoint> weightPoints;
  final WeeklyAverage weeklyAverage;

  /// Kaydı olan ölçüler, [MeasurementField] sırasıyla.
  final List<MeasurementTrend> measurements;

  /// Seçili dönemin günleri (bugün dahil), eskiden yeniye.
  final List<DailyProgress> days;

  /// Uyum oranları tamamlanmış günlerden hesaplanır; bugün dahil değildir.
  final Adherence calorieAdherence;
  final Adherence proteinAdherence;
  final Adherence waterAdherence;

  MeasurementTrend? get waist =>
      measurements.where((m) => m.field == MeasurementField.waist).firstOrNull;

  double? get averageScore {
    final scores = [
      for (final d in days)
        if (d.score case final score?) score.value,
    ];
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  @override
  List<Object?> get props => [
    range,
    targets,
    goal,
    weight,
    weightPoints,
    weeklyAverage,
    measurements,
    days,
    calorieAdherence,
    proteinAdherence,
    waterAdherence,
  ];
}

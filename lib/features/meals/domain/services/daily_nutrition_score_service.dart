import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../dashboard/domain/nutrition_score.dart';
import '../models/daily_log.dart';
import '../models/daily_nutrition_score.dart';

/// Günlük beslenme skorunu hesaplar. Puanlama [NutritionScoreCalculator]
/// ile aynıdır (Dashboard ve Günlük aynı sonucu gösterir); bu servis
/// günün bağlamını (geçmiş/bugün) ve kullanıcıya gösterilecek faktör
/// durumlarını ekler.
class DailyNutritionScoreService {
  const DailyNutritionScoreService();

  /// Özet kartında gösterilen faktörler.
  static const highlightedFactors = [
    ScoreFactor.calories,
    ScoreFactor.protein,
    ScoreFactor.water,
    ScoreFactor.mealRhythm,
    ScoreFactor.produce,
    ScoreFactor.macroBalance,
  ];

  static const metThreshold = 0.8;
  static const partialThreshold = 0.4;

  DailyNutritionScore calculate({
    required DailyLog log,
    required NutritionTargets targets,
    required DateTime now,
  }) {
    final breakdown = NutritionScoreCalculator.calculate(
      meals: log.entries,
      targets: targets,
      waterMl: log.waterAmount,
      now: referenceTime(log.date, now),
    );
    final progress = {
      for (final c in breakdown.components) c.factor: c.progress,
    };
    return DailyNutritionScore(
      breakdown: breakdown,
      checks: [
        for (final factor in highlightedFactors)
          if (progress[factor] case final p?)
            ScoreFactorCheck(factor: factor, progress: p, status: statusOf(p)),
      ],
    );
  }

  static ScoreFactorStatus statusOf(double progress) {
    if (progress >= metThreshold) return ScoreFactorStatus.met;
    if (progress >= partialThreshold) return ScoreFactorStatus.partial;
    return ScoreFactorStatus.missed;
  }

  /// Öğün düzeni "saati geçmiş" öğünlere bakar: geçmiş günlerde tüm öğün
  /// saatleri geçmiştir, gelecek günlerde henüz hiçbiri gelmemiştir.
  static DateTime referenceTime(DateTime day, DateTime now) {
    if (day.isSameDay(now)) return now;
    final start = day.startOfDay;
    return start.isBefore(now)
        ? DateTime(start.year, start.month, start.day, 23, 59)
        : start;
  }
}

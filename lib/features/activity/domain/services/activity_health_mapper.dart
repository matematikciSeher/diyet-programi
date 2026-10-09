import '../../../../shared/services/health/health_data_service.dart';
import '../models/daily_activity.dart';

/// Sağlık platformu okumasını mevcut [DailyActivity] kaydına yazar.
///
/// Platform toplamı ile manuel kayıt toplanmaz. Kalori hedefi bu sınıfa
/// hiç girmez.
abstract final class ActivityHealthMapper {
  static DailyActivity fromRead({
    required DateTime syncedAt,
    int? steps,
    double? activeCalories,
    double? distanceMeters,
    List<HealthWorkout>? workouts,
  }) {
    final minutes = workouts == null
        ? 0
        : workouts.fold<int>(0, (sum, workout) => sum + workout.durationMinutes);
    return DailyActivity(
      steps: steps ?? 0,
      activeCalories: activeCalories ?? 0,
      exerciseMinutes: minutes,
      distanceMeters: distanceMeters,
      workoutCount: workouts?.length,
      source: ActivitySource.health,
      lastSyncedAt: syncedAt,
      stepsKnown: steps != null,
      caloriesKnown: activeCalories != null,
      distanceKnown: distanceMeters != null,
      workoutsKnown: workouts != null,
    );
  }

  /// [health] varsa adım, kalori ve mesafe onun toplamıdır.
  /// Manuel değer yalnızca platformun bilmediği alanın yerine geçer.
  static DailyActivity merge({
    DailyActivity? manual,
    DailyActivity? health,
  }) {
    final manualEntry = manual?.source == ActivitySource.manual ? manual : null;
    if (health == null || health.source != ActivitySource.health) {
      return manualEntry ?? DailyActivity.empty;
    }
    if (manualEntry == null) return health;
    return DailyActivity(
      steps: health.stepsKnown ? health.steps : manualEntry.steps,
      stepsKnown: health.stepsKnown || manualEntry.steps != 0,
      activeCalories: health.caloriesKnown
          ? health.activeCalories
          : manualEntry.activeCalories,
      caloriesKnown: health.caloriesKnown || manualEntry.activeCalories != 0,
      distanceMeters: health.distanceKnown
          ? health.distanceMeters
          : manualEntry.distanceMeters,
      distanceKnown: health.distanceKnown || manualEntry.distanceKnown,
      exerciseMinutes: health.workoutsKnown
          ? health.exerciseMinutes
          : manualEntry.exerciseMinutes,
      workoutCount: health.workoutCount,
      workoutsKnown: health.workoutsKnown,
      source: ActivitySource.health,
      lastSyncedAt: health.lastSyncedAt,
    );
  }
}

/// İlerleme ekranındaki hareket özeti. Yeni grafik modeli değildir.
class ActivityWeekSummary {
  const ActivityWeekSummary({
    required this.today,
    required this.weekSteps,
    required this.weekStepsKnown,
    required this.weekCalories,
    required this.weekCaloriesKnown,
    required this.weekDistanceMeters,
    required this.weekDistanceKnown,
  });

  factory ActivityWeekSummary.fromDays(List<DailyActivity> days) {
    final today = days.isEmpty ? DailyActivity.empty : days.last;
    var steps = 0;
    var calories = 0.0;
    var distance = 0.0;
    var stepsKnown = false;
    var caloriesKnown = false;
    var distanceKnown = false;
    for (final day in days) {
      if (day.stepsKnown) {
        steps += day.steps;
        stepsKnown = true;
      }
      if (day.caloriesKnown) {
        calories += day.activeCalories;
        caloriesKnown = true;
      }
      if (day.distanceKnown && day.distanceMeters != null) {
        distance += day.distanceMeters!;
        distanceKnown = true;
      }
    }
    return ActivityWeekSummary(
      today: today,
      weekSteps: steps,
      weekStepsKnown: stepsKnown,
      weekCalories: calories,
      weekCaloriesKnown: caloriesKnown,
      weekDistanceMeters: distanceKnown ? distance : null,
      weekDistanceKnown: distanceKnown,
    );
  }

  final DailyActivity today;
  final int weekSteps;
  final bool weekStepsKnown;
  final double weekCalories;
  final bool weekCaloriesKnown;
  final double? weekDistanceMeters;
  final bool weekDistanceKnown;
}

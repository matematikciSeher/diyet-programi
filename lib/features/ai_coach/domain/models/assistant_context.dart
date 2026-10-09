import 'package:equatable/equatable.dart';

import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/fasting_session.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../activity/domain/models/daily_activity.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';

/// Asistanın yanıt verirken okuduğu anlık kullanıcı verisi: profil,
/// bugünkü günlük ve su, kilo/ölçüm geçmişi, bugünkü plan ve oruç.
class AssistantContext extends Equatable {
  const AssistantContext({
    required this.now,
    required this.targets,
    this.profile,
    this.todayMeals = const [],
    this.todayWaterMl = 0,
    this.weights = const [],
    this.measurements = const [],
    this.todayPlan = const [],
    this.fastingSchedule,
    this.activeFast,
    this.todayActivity,
  });

  final DateTime now;
  final UserProfile? profile;
  final NutritionTargets targets;
  final List<MealEntry> todayMeals;
  final int todayWaterMl;

  /// En yeni önce.
  final List<WeightEntry> weights;

  /// En eski önce.
  final List<BodyMeasurement> measurements;
  final List<PlannedMeal> todayPlan;
  final FastingSchedule? fastingSchedule;
  final FastingSession? activeFast;

  /// Cihazdaki DailyActivity. Firebase'e yazılmaz; yalnızca ilgili soruda
  /// cihazdan giden asistan isteğine eklenebilir.
  final DailyActivity? todayActivity;

  NutritionFacts get consumed =>
      todayMeals.fold(NutritionFacts.zero, (sum, e) => sum + e.nutrition);

  double get remainingCalories => targets.calories - consumed.calories;
  double get remainingProtein => targets.proteinG - consumed.proteinG;

  Set<MealType> get loggedMealTypes => {for (final e in todayMeals) e.mealType};

  /// Plandaki, henüz günlüğe eklenmemiş ilk [type] öğünü.
  PlannedMeal? plannedFor(MealType type) => todayPlan
      .where((m) => m.mealType == type && !loggedMealTypes.contains(type))
      .firstOrNull;

  /// Saate göre sıradaki öğün.
  MealType get upcomingMealType {
    final minutes = now.hour * 60 + now.minute;
    for (final m in todayPlan) {
      final t = m.timeMinutes;
      if (t != null && t >= minutes - 30 && !loggedMealTypes.contains(m.mealType)) {
        return m.mealType;
      }
    }
    if (minutes < 11 * 60) return MealType.breakfast;
    if (minutes < 15 * 60) return MealType.lunch;
    if (minutes < 17 * 60 + 30) return MealType.snack;
    return MealType.dinner;
  }

  @override
  List<Object?> get props => [
    now,
    profile,
    targets,
    todayMeals,
    todayWaterMl,
    weights,
    measurements,
    todayPlan,
    fastingSchedule,
    activeFast,
    todayActivity,
  ];
}

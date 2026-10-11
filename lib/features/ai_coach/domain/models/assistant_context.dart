import 'package:equatable/equatable.dart';

import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/fasting_session.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../activity/domain/models/daily_activity.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';

/// Katalogdaki bir tarifin asistan için sade kopyası.
class AssistantKnownRecipe extends Equatable {
  const AssistantKnownRecipe({
    required this.id,
    required this.title,
    required this.calories,
    required this.proteinG,
    this.suitable = true,
  });

  final String id;
  final String title;
  final double calories;
  final double proteinG;

  /// Profildeki alerji, sevmeme ve diyete göre elenmişse `false`.
  final bool suitable;

  @override
  List<Object?> get props => [id, title, calories, proteinG, suitable];
}

/// Alışveriş satırının asistan için sade kopyası. Listeyi değiştirmez.
class AssistantShoppingLine extends Equatable {
  const AssistantShoppingLine({required this.name, required this.manual});

  final String name;

  /// Elle eklenen satır: plan veya tarif kaynağı yoktur.
  final bool manual;

  @override
  List<Object?> get props => [name, manual];
}

/// Asistanın yanıt verirken okuduğu anlık kullanıcı verisi: profil,
/// bugünkü günlük ve su, kilo/ölçüm geçmişi, bugünkü plan ve oruç.
class AssistantContext extends Equatable {
  const AssistantContext({
    required this.now,
    required this.targets,
    this.profile,
    this.todayMeals = const [],
    this.todayWaterMl = 0,
    this.todayWaterLogCount = 0,
    this.weights = const [],
    this.measurements = const [],
    this.todayPlan = const [],
    this.fastingSchedule,
    this.activeFast,
    this.todayActivity,
    this.weekMeals = const [],
    this.weekWaterLogs = const [],
    this.weekPlan = const [],
    this.knownRecipes = const [],
    this.shoppingLines = const [],
  });

  final DateTime now;
  final UserProfile? profile;
  final NutritionTargets targets;
  final List<MealEntry> todayMeals;
  final int todayWaterMl;

  /// Bugünkü su kayıtlarının sayısı. Sıfırsa miktar uydurulmaz.
  final int todayWaterLogCount;

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

  /// İçinde bulunulan haftanın bugüne kadarki öğün kayıtları.
  final List<MealEntry> weekMeals;

  /// Aynı aralıktaki su kayıtları.
  final List<WaterLog> weekWaterLogs;

  /// Kayıtlı haftalık menü. Asistan bu listeyi değiştirmez.
  final List<PlannedMeal> weekPlan;
  final List<AssistantKnownRecipe> knownRecipes;
  final List<AssistantShoppingLine> shoppingLines;

  bool get hasPersonalTargets => profile?.nutritionTargets != null;

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
    todayWaterLogCount,
    weights,
    measurements,
    todayPlan,
    fastingSchedule,
    activeFast,
    todayActivity,
    weekMeals,
    weekWaterLogs,
    weekPlan,
    knownRecipes,
    shoppingLines,
  ];
}

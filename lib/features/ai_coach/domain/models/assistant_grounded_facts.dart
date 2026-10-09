import 'package:equatable/equatable.dart';

/// Uygulamanın hesapladığı, modele ve arayüze verilen sayısal özet.
///
/// Bu değerler DailyLog, WaterLog, DailyActivity ve UserProfile'dan gelir.
/// Model bunları yeniden hesaplamaz.
class AssistantGroundedFacts extends Equatable {
  const AssistantGroundedFacts({
    this.showCalories = false,
    this.showProtein = false,
    this.showCarbs = false,
    this.showFat = false,
    this.showWater = false,
    this.showActivity = false,
    this.showPlan = false,
    this.targetsKnown = false,
    this.consumedCalories,
    this.calorieTarget,
    this.consumedProteinG,
    this.proteinTargetG,
    this.consumedCarbsG,
    this.carbTargetG,
    this.consumedFatG,
    this.fatTargetG,
    this.waterMl,
    this.waterGoalMl,
    this.steps,
    this.stepsKnown = false,
    this.distanceMeters,
    this.distanceKnown = false,
    this.activeCalories,
    this.activeCaloriesKnown = false,
    this.workoutCount,
    this.workoutsKnown = false,
    this.planLines = const [],
    this.missing = const [],
  });

  final bool showCalories;
  final bool showProtein;
  final bool showCarbs;
  final bool showFat;
  final bool showWater;
  final bool showActivity;
  final bool showPlan;
  final bool targetsKnown;
  final double? consumedCalories;
  final double? calorieTarget;
  final double? consumedProteinG;
  final double? proteinTargetG;
  final double? consumedCarbsG;
  final double? carbTargetG;
  final double? consumedFatG;
  final double? fatTargetG;
  final int? waterMl;
  final int? waterGoalMl;
  final int? steps;
  final bool stepsKnown;
  final double? distanceMeters;
  final bool distanceKnown;
  final double? activeCalories;
  final bool activeCaloriesKnown;
  final int? workoutCount;
  final bool workoutsKnown;
  final List<String> planLines;
  final List<String> missing;

  bool get hasVisibleRecord =>
      showCalories ||
      showProtein ||
      showCarbs ||
      showFat ||
      showWater ||
      showActivity ||
      showPlan;

  Map<String, Object?> toJson() => {
    'showCalories': showCalories,
    'showProtein': showProtein,
    'showCarbs': showCarbs,
    'showFat': showFat,
    'showWater': showWater,
    'showActivity': showActivity,
    'showPlan': showPlan,
    'targetsKnown': targetsKnown,
    'consumedCalories': consumedCalories,
    'calorieTarget': calorieTarget,
    'consumedProteinG': consumedProteinG,
    'proteinTargetG': proteinTargetG,
    'consumedCarbsG': consumedCarbsG,
    'carbTargetG': carbTargetG,
    'consumedFatG': consumedFatG,
    'fatTargetG': fatTargetG,
    'waterMl': waterMl,
    'waterGoalMl': waterGoalMl,
    'steps': steps,
    'stepsKnown': stepsKnown,
    'distanceMeters': distanceMeters,
    'distanceKnown': distanceKnown,
    'activeCalories': activeCalories,
    'activeCaloriesKnown': activeCaloriesKnown,
    'workoutCount': workoutCount,
    'workoutsKnown': workoutsKnown,
    'planLines': planLines,
    'missing': missing,
  };

  factory AssistantGroundedFacts.fromJson(Map<String, dynamic> json) {
    double? d(Object? value) => value is num ? value.toDouble() : null;
    int? i(Object? value) => value is num ? value.toInt() : null;
    List<String> strings(Object? value) => value is List
        ? [for (final item in value) item.toString()]
        : const [];
    return AssistantGroundedFacts(
      showCalories: json['showCalories'] == true,
      showProtein: json['showProtein'] == true,
      showCarbs: json['showCarbs'] == true,
      showFat: json['showFat'] == true,
      showWater: json['showWater'] == true,
      showActivity: json['showActivity'] == true,
      showPlan: json['showPlan'] == true,
      targetsKnown: json['targetsKnown'] == true,
      consumedCalories: d(json['consumedCalories']),
      calorieTarget: d(json['calorieTarget']),
      consumedProteinG: d(json['consumedProteinG']),
      proteinTargetG: d(json['proteinTargetG']),
      consumedCarbsG: d(json['consumedCarbsG']),
      carbTargetG: d(json['carbTargetG']),
      consumedFatG: d(json['consumedFatG']),
      fatTargetG: d(json['fatTargetG']),
      waterMl: i(json['waterMl']),
      waterGoalMl: i(json['waterGoalMl']),
      steps: i(json['steps']),
      stepsKnown: json['stepsKnown'] == true,
      distanceMeters: d(json['distanceMeters']),
      distanceKnown: json['distanceKnown'] == true,
      activeCalories: d(json['activeCalories']),
      activeCaloriesKnown: json['activeCaloriesKnown'] == true,
      workoutCount: i(json['workoutCount']),
      workoutsKnown: json['workoutsKnown'] == true,
      planLines: strings(json['planLines']),
      missing: strings(json['missing']),
    );
  }

  @override
  List<Object?> get props => [
    showCalories,
    showProtein,
    showCarbs,
    showFat,
    showWater,
    showActivity,
    showPlan,
    targetsKnown,
    consumedCalories,
    calorieTarget,
    consumedProteinG,
    proteinTargetG,
    consumedCarbsG,
    carbTargetG,
    consumedFatG,
    fatTargetG,
    waterMl,
    waterGoalMl,
    steps,
    stepsKnown,
    distanceMeters,
    distanceKnown,
    activeCalories,
    activeCaloriesKnown,
    workoutCount,
    workoutsKnown,
    planLines,
    missing,
  ];
}

class AssistantRecipeRef extends Equatable {
  const AssistantRecipeRef({
    required this.id,
    required this.title,
    required this.calories,
    required this.proteinG,
  });

  final String id;
  final String title;
  final double calories;
  final double proteinG;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'calories': calories,
    'proteinG': proteinG,
  };

  factory AssistantRecipeRef.fromJson(Map<String, dynamic> json) =>
      AssistantRecipeRef(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        calories: json['calories'] is num
            ? (json['calories'] as num).toDouble()
            : 0,
        proteinG: json['proteinG'] is num
            ? (json['proteinG'] as num).toDouble()
            : 0,
      );

  @override
  List<Object?> get props => [id, title, calories, proteinG];
}

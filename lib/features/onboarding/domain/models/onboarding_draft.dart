import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/services/nutrition/nutrition_calculator.dart';
import 'onboarding_step.dart';

/// Onboarding sırasında toplanan, henüz tamamlanmamış cevaplar.
/// Her değişiklikte yerel olarak saklanır; uygulama kapansa bile kullanıcı
/// [currentStep]'ten devam eder.
class OnboardingDraft extends Equatable {
  const OnboardingDraft({
    this.currentStep = OnboardingStep.welcome,
    this.name,
    this.goal,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.targetWeight,
    this.activityLevel,
    this.exerciseFrequency,
    this.dietType,
    this.allergies = const [],
    this.dislikedFoods = const [],
    this.mealsPerDay,
    this.breakfastPreference,
    this.waterGoal,
    this.fastingPreference,
    this.targetDate,
  });

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) {
    return OnboardingDraft(
      currentStep:
          OnboardingStep.tryParse(json['currentStep']) ??
          OnboardingStep.welcome,
      name: JsonUtils.readStringOrNull(json['name']),
      goal: JsonUtils.readEnumOrNull(GoalType.values, json['goal']),
      gender: JsonUtils.readEnumOrNull(Gender.values, json['gender']),
      age: JsonUtils.readIntOrNull(json['age']),
      height: JsonUtils.readDoubleOrNull(json['height']),
      weight: JsonUtils.readDoubleOrNull(json['weight']),
      targetWeight: JsonUtils.readDoubleOrNull(json['targetWeight']),
      activityLevel: JsonUtils.readEnumOrNull(
        ActivityLevel.values,
        json['activityLevel'],
      ),
      exerciseFrequency: JsonUtils.readEnumOrNull(
        ExerciseFrequency.values,
        json['exerciseFrequency'],
      ),
      dietType: JsonUtils.readEnumOrNull(DietType.values, json['dietType']),
      allergies: JsonUtils.readStringList(json['allergies']),
      dislikedFoods: JsonUtils.readStringList(json['dislikedFoods']),
      mealsPerDay: JsonUtils.readIntOrNull(json['mealsPerDay']),
      breakfastPreference: JsonUtils.readEnumOrNull(
        BreakfastPreference.values,
        json['breakfastPreference'],
      ),
      waterGoal: JsonUtils.readIntOrNull(json['waterGoal']),
      fastingPreference: JsonUtils.readEnumOrNull(
        FastingPreference.values,
        json['fastingPreference'],
      ),
      targetDate: JsonUtils.readDate(json['targetDate']),
    );
  }

  final OnboardingStep currentStep;
  final String? name;
  final GoalType? goal;
  final Gender? gender;
  final int? age;
  final double? height;
  final double? weight;
  final double? targetWeight;
  final ActivityLevel? activityLevel;
  final ExerciseFrequency? exerciseFrequency;
  final DietType? dietType;
  final List<String> allergies;
  final List<String> dislikedFoods;
  final int? mealsPerDay;
  final BreakfastPreference? breakfastPreference;
  final int? waterGoal;
  final FastingPreference? fastingPreference;

  /// `null`: önerilen güvenli tempo kullanılır.
  final DateTime? targetDate;

  List<OnboardingStep> get flow => OnboardingStep.flowFor(goal);

  /// Hedef kilo değiştirmiyorsa mevcut kilo hedef kabul edilir.
  double? get effectiveTargetWeight =>
      (goal?.changesWeight ?? false) ? targetWeight : weight;

  /// Hesaplama için gerekli tüm cevaplar mevcutsa girdi döner.
  NutritionInput? toNutritionInput() {
    final g = goal;
    final sex = gender;
    final a = age;
    final h = height;
    final w = weight;
    final activity = activityLevel;
    if (g == null ||
        sex == null ||
        a == null ||
        h == null ||
        w == null ||
        activity == null) {
      return null;
    }
    return NutritionInput(
      gender: sex,
      age: a,
      heightCm: h,
      weightKg: w,
      targetWeightKg: effectiveTargetWeight,
      activityLevel: activity,
      exerciseFrequency: exerciseFrequency ?? ExerciseFrequency.none,
      goal: g,
      fastingPreference: fastingPreference ?? FastingPreference.none,
      targetDate: g.changesWeight ? targetDate : null,
    );
  }

  UserProfile toProfile({
    required String id,
    required NutritionPlan plan,
    required DateTime now,
  }) {
    final changesWeight = goal?.changesWeight ?? false;
    return UserProfile(
      id: id,
      name: name?.trim().isEmpty ?? true ? null : name!.trim(),
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      startWeight: weight,
      targetWeight: effectiveTargetWeight,
      activityLevel: activityLevel,
      exerciseFrequency: exerciseFrequency,
      goal: goal,
      dietType: dietType,
      allergies: allergies,
      dislikedFoods: dislikedFoods,
      mealsPerDay: mealsPerDay,
      breakfastPreference: breakfastPreference,
      waterGoal: waterGoal ?? plan.waterMl,
      fastingPreference: fastingPreference ?? FastingPreference.none,
      targetDate: changesWeight ? targetDate : null,
      maintenanceCalories: plan.maintenanceCalories,
      dailyCalories: plan.targetCalories,
      proteinGoal: plan.proteinG,
      carbGoal: plan.carbsG,
      fatGoal: plan.fatG,
      estimatedGoalDate: plan.estimatedGoalDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  static const _unset = Object();

  /// Nullable alanlar `null` verilerek temizlenebilir; verilmeyen alanlar
  /// korunur.
  OnboardingDraft copyWith({
    OnboardingStep? currentStep,
    Object? name = _unset,
    Object? goal = _unset,
    Object? gender = _unset,
    Object? age = _unset,
    Object? height = _unset,
    Object? weight = _unset,
    Object? targetWeight = _unset,
    Object? activityLevel = _unset,
    Object? exerciseFrequency = _unset,
    Object? dietType = _unset,
    List<String>? allergies,
    List<String>? dislikedFoods,
    Object? mealsPerDay = _unset,
    Object? breakfastPreference = _unset,
    Object? waterGoal = _unset,
    Object? fastingPreference = _unset,
    Object? targetDate = _unset,
  }) {
    T? pick<T>(Object? value, T? current) =>
        identical(value, _unset) ? current : value as T?;
    double? pickNum(Object? value, double? current) =>
        identical(value, _unset) ? current : (value as num?)?.toDouble();
    return OnboardingDraft(
      currentStep: currentStep ?? this.currentStep,
      name: pick(name, this.name),
      goal: pick(goal, this.goal),
      gender: pick(gender, this.gender),
      age: pick(age, this.age),
      height: pickNum(height, this.height),
      weight: pickNum(weight, this.weight),
      targetWeight: pickNum(targetWeight, this.targetWeight),
      activityLevel: pick(activityLevel, this.activityLevel),
      exerciseFrequency: pick(exerciseFrequency, this.exerciseFrequency),
      dietType: pick(dietType, this.dietType),
      allergies: allergies ?? this.allergies,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      mealsPerDay: pick(mealsPerDay, this.mealsPerDay),
      breakfastPreference: pick(breakfastPreference, this.breakfastPreference),
      waterGoal: pick(waterGoal, this.waterGoal),
      fastingPreference: pick(fastingPreference, this.fastingPreference),
      targetDate: pick(targetDate, this.targetDate),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentStep': currentStep.name,
    'name': name,
    'goal': goal?.name,
    'gender': gender?.name,
    'age': age,
    'height': height,
    'weight': weight,
    'targetWeight': targetWeight,
    'activityLevel': activityLevel?.name,
    'exerciseFrequency': exerciseFrequency?.name,
    'dietType': dietType?.name,
    'allergies': allergies,
    'dislikedFoods': dislikedFoods,
    'mealsPerDay': mealsPerDay,
    'breakfastPreference': breakfastPreference?.name,
    'waterGoal': waterGoal,
    'fastingPreference': fastingPreference?.name,
    'targetDate': targetDate?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    currentStep,
    name,
    goal,
    gender,
    age,
    height,
    weight,
    targetWeight,
    activityLevel,
    exerciseFrequency,
    dietType,
    allergies,
    dislikedFoods,
    mealsPerDay,
    breakfastPreference,
    waterGoal,
    fastingPreference,
    targetDate,
  ];
}

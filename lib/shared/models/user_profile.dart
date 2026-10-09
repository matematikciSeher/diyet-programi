import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/json_utils.dart';
import 'enums.dart';
import 'nutrition_targets.dart';

/// Kişiselleştirilmiş plan için temel kullanıcı profili.
/// Konum: `users/{uid}`.
///
/// Uygulamadaki tüm özelliklerin (plan, günlük, kilo, oruç, asistan) ortak
/// veri kaynağıdır: kalori/makro hedefleri, güncel kilo ve oruç protokolü
/// yalnızca burada tutulur.
///
/// Onboarding yarıda kalmış ya da eski sürümden gelen kayıtlar da
/// okunabilsin diye `id` ve zaman damgaları dışındaki tüm alanlar
/// opsiyoneldir; [fromJson] bozuk/eksik değerlerde `null` döndürür.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.startWeight,
    this.targetWeight,
    this.activityLevel,
    this.exerciseFrequency,
    this.goal,
    this.dietType,
    this.allergies = const [],
    this.dislikedFoods = const [],
    this.mealsPerDay,
    this.breakfastPreference,
    this.waterGoal,
    this.fastingPreference,
    this.eatingWindowStartMinutes,
    this.targetDate,
    this.maintenanceCalories,
    this.dailyCalories,
    this.proteinGoal,
    this.carbGoal,
    this.fatGoal,
    this.estimatedGoalDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final meals = JsonUtils.readIntOrNull(json['mealsPerDay']);
    final windowStart = JsonUtils.readIntOrNull(
      json['eatingWindowStartMinutes'],
    );
    return UserProfile(
      id: JsonUtils.readString(json['id']),
      name: JsonUtils.readStringOrNull(json['name']),
      age: JsonUtils.readIntOrNull(json['age']),
      gender: JsonUtils.readEnumOrNull(Gender.values, json['gender']),
      height: JsonUtils.readDoubleOrNull(json['height']),
      weight: JsonUtils.readDoubleOrNull(json['weight']),
      startWeight: JsonUtils.readDoubleOrNull(json['startWeight']),
      targetWeight: JsonUtils.readDoubleOrNull(json['targetWeight']),
      activityLevel: JsonUtils.readEnumOrNull(
        ActivityLevel.values,
        json['activityLevel'],
      ),
      exerciseFrequency: JsonUtils.readEnumOrNull(
        ExerciseFrequency.values,
        json['exerciseFrequency'],
      ),
      goal: JsonUtils.readEnumOrNull(GoalType.values, json['goal']),
      dietType: JsonUtils.readEnumOrNull(DietType.values, json['dietType']),
      allergies: JsonUtils.readStringList(json['allergies']),
      dislikedFoods: JsonUtils.readStringList(json['dislikedFoods']),
      mealsPerDay: meals != null && meals >= 1 && meals <= 8 ? meals : null,
      breakfastPreference: JsonUtils.readEnumOrNull(
        BreakfastPreference.values,
        json['breakfastPreference'],
      ),
      waterGoal: JsonUtils.readIntOrNull(json['waterGoal']),
      fastingPreference: JsonUtils.readEnumOrNull(
        FastingPreference.values,
        json['fastingPreference'],
      ),
      eatingWindowStartMinutes:
          windowStart != null && windowStart >= 0 && windowStart < 24 * 60
          ? windowStart
          : null,
      targetDate: JsonUtils.readDate(json['targetDate']),
      maintenanceCalories: JsonUtils.readIntOrNull(json['maintenanceCalories']),
      dailyCalories: JsonUtils.readIntOrNull(json['dailyCalories']),
      proteinGoal: JsonUtils.readIntOrNull(json['proteinGoal']),
      carbGoal: JsonUtils.readIntOrNull(json['carbGoal']),
      fatGoal: JsonUtils.readIntOrNull(json['fatGoal']),
      estimatedGoalDate: JsonUtils.readDate(json['estimatedGoalDate']),
      createdAt: JsonUtils.readDateOr(json['createdAt'], now),
      updatedAt: JsonUtils.readDateOr(json['updatedAt'], now),
    );
  }

  /// Oruç protokolü seçilmiş ama pencere saati girilmemişse yeme penceresi
  /// öğlen başlar (ör. 16:8 → 12:00–20:00).
  static const defaultEatingWindowStartMinutes = 12 * 60;

  final String id;
  final String? name;
  final int? age;
  final Gender? gender;

  /// cm
  final double? height;

  /// Güncel kilo (kg). Kilo takibinde en yeni kayıt girildikçe güncellenir.
  final double? weight;

  /// Takibin başladığı kilo (kg); ilk kilo güncellemesinde sabitlenir.
  final double? startWeight;

  /// kg
  final double? targetWeight;
  final ActivityLevel? activityLevel;
  final ExerciseFrequency? exerciseFrequency;
  final GoalType? goal;
  final DietType? dietType;

  /// [Allergen] adları ve/veya kullanıcının yazdığı serbest metinler.
  final List<String> allergies;
  final List<String> dislikedFoods;
  final int? mealsPerDay;
  final BreakfastPreference? breakfastPreference;

  /// ml
  final int? waterGoal;
  final FastingPreference? fastingPreference;

  /// Yeme penceresinin başladığı saat, gece yarısından itibaren dakika.
  final int? eatingWindowStartMinutes;

  /// Kullanıcının seçtiği hedef tarih.
  final DateTime? targetDate;

  /// Tahmini günlük enerji ihtiyacı (TDEE, kcal).
  final int? maintenanceCalories;

  /// Önerilen günlük kalori hedefi (kcal).
  final int? dailyCalories;

  /// g
  final int? proteinGoal;

  /// g
  final int? carbGoal;

  /// g
  final int? fatGoal;

  /// Güvenli hızla hesaplanan tahmini hedefe ulaşma tarihi.
  final DateTime? estimatedGoalDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  double? get currentWeight => weight;
  int? get carbohydrateGoal => carbGoal;

  /// Kilo kaydı hiç güncellenmemiş eski profillerde güncel kilo başlangıçtır.
  double? get effectiveStartWeight => startWeight ?? weight;

  bool get isFasting =>
      fastingPreference != null && fastingPreference != FastingPreference.none;

  int get effectiveEatingWindowStart =>
      eatingWindowStartMinutes ?? defaultEatingWindowStartMinutes;

  double? get bmi {
    final h = height;
    final w = weight;
    if (h == null || w == null || h <= 0) return null;
    final m = h / 100;
    return w / (m * m);
  }

  /// Kalori ve makro hedefleri hesaplanmışsa dashboard'da kullanılacak özet.
  NutritionTargets? get nutritionTargets {
    final kcal = dailyCalories;
    final p = proteinGoal;
    final c = carbGoal;
    final f = fatGoal;
    if (kcal == null || p == null || c == null || f == null) return null;
    return NutritionTargets(
      calories: kcal.toDouble(),
      proteinG: p.toDouble(),
      carbsG: c.toDouble(),
      fatG: f.toDouble(),
      waterMl: waterGoal ?? AppConstants.defaultWaterGoalMl,
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? height,
    double? weight,
    double? startWeight,
    double? targetWeight,
    ActivityLevel? activityLevel,
    ExerciseFrequency? exerciseFrequency,
    GoalType? goal,
    DietType? dietType,
    List<String>? allergies,
    List<String>? dislikedFoods,
    int? mealsPerDay,
    BreakfastPreference? breakfastPreference,
    int? waterGoal,
    FastingPreference? fastingPreference,
    int? eatingWindowStartMinutes,
    DateTime? targetDate,
    int? maintenanceCalories,
    int? dailyCalories,
    int? proteinGoal,
    int? carbGoal,
    int? fatGoal,
    DateTime? estimatedGoalDate,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      createdAt: createdAt,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      startWeight: startWeight ?? this.startWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      goal: goal ?? this.goal,
      dietType: dietType ?? this.dietType,
      allergies: allergies ?? this.allergies,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      breakfastPreference: breakfastPreference ?? this.breakfastPreference,
      waterGoal: waterGoal ?? this.waterGoal,
      fastingPreference: fastingPreference ?? this.fastingPreference,
      eatingWindowStartMinutes:
          eatingWindowStartMinutes ?? this.eatingWindowStartMinutes,
      targetDate: targetDate ?? this.targetDate,
      maintenanceCalories: maintenanceCalories ?? this.maintenanceCalories,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      estimatedGoalDate: estimatedGoalDate ?? this.estimatedGoalDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender?.name,
    'height': height,
    'weight': weight,
    'startWeight': startWeight,
    'targetWeight': targetWeight,
    'activityLevel': activityLevel?.name,
    'exerciseFrequency': exerciseFrequency?.name,
    'goal': goal?.name,
    'dietType': dietType?.name,
    'allergies': allergies,
    'dislikedFoods': dislikedFoods,
    'mealsPerDay': mealsPerDay,
    'breakfastPreference': breakfastPreference?.name,
    'waterGoal': waterGoal,
    'fastingPreference': fastingPreference?.name,
    'eatingWindowStartMinutes': eatingWindowStartMinutes,
    'targetDate': targetDate?.toIso8601String(),
    'maintenanceCalories': maintenanceCalories,
    'dailyCalories': dailyCalories,
    'proteinGoal': proteinGoal,
    'carbGoal': carbGoal,
    'fatGoal': fatGoal,
    'estimatedGoalDate': estimatedGoalDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    name,
    age,
    gender,
    height,
    weight,
    startWeight,
    targetWeight,
    activityLevel,
    exerciseFrequency,
    goal,
    dietType,
    allergies,
    dislikedFoods,
    mealsPerDay,
    breakfastPreference,
    waterGoal,
    fastingPreference,
    eatingWindowStartMinutes,
    targetDate,
    maintenanceCalories,
    dailyCalories,
    proteinGoal,
    carbGoal,
    fatGoal,
    estimatedGoalDate,
    createdAt,
    updatedAt,
  ];
}

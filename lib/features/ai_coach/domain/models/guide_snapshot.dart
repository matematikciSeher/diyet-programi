import 'package:equatable/equatable.dart';

/// Kişisel sayılar yalnızca kayıt varsa doldurulur.
enum GuideDataKind {
  none,
  daily,
  calories,
  water,
  week,
  recipes,
  preferences,
  plan,
  shopping,
  weight,
}

class GuideDayAmount extends Equatable {
  const GuideDayAmount({required this.dayKey, required this.amount});

  final String dayKey;
  final double amount;

  Map<String, Object?> toJson() => {'dayKey': dayKey, 'amount': amount};

  factory GuideDayAmount.fromJson(Map<String, dynamic> json) => GuideDayAmount(
    dayKey: json['dayKey']?.toString() ?? '',
    amount: json['amount'] is num ? (json['amount'] as num).toDouble() : 0,
  );

  @override
  List<Object?> get props => [dayKey, amount];
}

/// Asistanın bir soruda kullanabildiği kayıt özeti.
///
/// Eksik alanlar `null` kalır; arayüz bunları uydurmaz.
class GuideSnapshot extends Equatable {
  const GuideSnapshot({
    this.kind = GuideDataKind.none,
    this.recordsMissing = false,
    this.personalTarget = false,
    this.consumedCalories,
    this.targetCalories,
    this.mealCount = 0,
    this.loggedMealTypes = const [],
    this.missingMealTypes = const [],
    this.foodTagsKnown = false,
    this.presentFoodTags = const [],
    this.macrosRecorded = false,
    this.proteinG,
    this.proteinTargetG,
    this.carbsG,
    this.carbsTargetG,
    this.fatG,
    this.fatTargetG,
    this.targetBelowSafeFloor = false,
    this.waterMl,
    this.waterGoalMl,
    this.waterKnown = false,
    this.elapsedDays = 0,
    this.mealDays = const [],
    this.waterDays = const [],
    this.recipeCatalogCount = 0,
    this.recipeMatchCount = 0,
    this.preferencesKnown = false,
    this.allergies = const [],
    this.dislikes = const [],
    this.dietTypeName,
    this.planLines = const [],
    this.shoppingManual = 0,
    this.shoppingFromPlan = 0,
    this.shoppingManualNames = const [],
    this.weightKg,
    this.startWeightKg,
    this.targetWeightKg,
  });

  final GuideDataKind kind;
  final bool recordsMissing;
  final bool personalTarget;
  final double? consumedCalories;
  final double? targetCalories;
  final int mealCount;
  final List<String> loggedMealTypes;
  final List<String> missingMealTypes;
  final bool foodTagsKnown;
  final List<String> presentFoodTags;
  final bool macrosRecorded;
  final double? proteinG;
  final double? proteinTargetG;
  final double? carbsG;
  final double? carbsTargetG;
  final double? fatG;
  final double? fatTargetG;
  final bool targetBelowSafeFloor;
  final int? waterMl;
  final int? waterGoalMl;
  final bool waterKnown;
  final int elapsedDays;
  final List<GuideDayAmount> mealDays;
  final List<GuideDayAmount> waterDays;
  final int recipeCatalogCount;
  final int recipeMatchCount;
  final bool preferencesKnown;
  final List<String> allergies;
  final List<String> dislikes;
  final String? dietTypeName;
  final List<String> planLines;
  final int shoppingManual;
  final int shoppingFromPlan;
  final List<String> shoppingManualNames;
  final double? weightKg;
  final double? startWeightKg;
  final double? targetWeightKg;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'recordsMissing': recordsMissing,
    'personalTarget': personalTarget,
    'consumedCalories': consumedCalories,
    'targetCalories': targetCalories,
    'mealCount': mealCount,
    'loggedMealTypes': loggedMealTypes,
    'missingMealTypes': missingMealTypes,
    'foodTagsKnown': foodTagsKnown,
    'presentFoodTags': presentFoodTags,
    'macrosRecorded': macrosRecorded,
    'proteinG': proteinG,
    'proteinTargetG': proteinTargetG,
    'carbsG': carbsG,
    'carbsTargetG': carbsTargetG,
    'fatG': fatG,
    'fatTargetG': fatTargetG,
    'targetBelowSafeFloor': targetBelowSafeFloor,
    'waterMl': waterMl,
    'waterGoalMl': waterGoalMl,
    'waterKnown': waterKnown,
    'elapsedDays': elapsedDays,
    'mealDays': [for (final day in mealDays) day.toJson()],
    'waterDays': [for (final day in waterDays) day.toJson()],
    'recipeCatalogCount': recipeCatalogCount,
    'recipeMatchCount': recipeMatchCount,
    'preferencesKnown': preferencesKnown,
    'allergies': allergies,
    'dislikes': dislikes,
    'dietTypeName': dietTypeName,
    'planLines': planLines,
    'shoppingManual': shoppingManual,
    'shoppingFromPlan': shoppingFromPlan,
    'shoppingManualNames': shoppingManualNames,
    'weightKg': weightKg,
    'startWeightKg': startWeightKg,
    'targetWeightKg': targetWeightKg,
  };

  factory GuideSnapshot.fromJson(Map<String, dynamic> json) {
    double? d(Object? value) => value is num ? value.toDouble() : null;
    int i(Object? value) => value is num ? value.toInt() : 0;
    List<String> strings(Object? value) => [
      for (final item in value is List ? value : const []) item.toString(),
    ];
    List<GuideDayAmount> days(Object? value) => [
      for (final item in value is List ? value : const [])
        if (item is Map)
          GuideDayAmount.fromJson(Map<String, dynamic>.from(item)),
    ];
    return GuideSnapshot(
      kind: GuideDataKind.values
              .where((item) => item.name == json['kind'])
              .firstOrNull ??
          GuideDataKind.none,
      recordsMissing: json['recordsMissing'] == true,
      personalTarget: json['personalTarget'] == true,
      consumedCalories: d(json['consumedCalories']),
      targetCalories: d(json['targetCalories']),
      mealCount: i(json['mealCount']),
      loggedMealTypes: strings(json['loggedMealTypes']),
      missingMealTypes: strings(json['missingMealTypes']),
      foodTagsKnown: json['foodTagsKnown'] == true,
      presentFoodTags: strings(json['presentFoodTags']),
      macrosRecorded: json['macrosRecorded'] == true,
      proteinG: d(json['proteinG']),
      proteinTargetG: d(json['proteinTargetG']),
      carbsG: d(json['carbsG']),
      carbsTargetG: d(json['carbsTargetG']),
      fatG: d(json['fatG']),
      fatTargetG: d(json['fatTargetG']),
      targetBelowSafeFloor: json['targetBelowSafeFloor'] == true,
      waterMl: json['waterMl'] is num ? (json['waterMl'] as num).toInt() : null,
      waterGoalMl: json['waterGoalMl'] is num
          ? (json['waterGoalMl'] as num).toInt()
          : null,
      waterKnown: json['waterKnown'] == true,
      elapsedDays: i(json['elapsedDays']),
      mealDays: days(json['mealDays']),
      waterDays: days(json['waterDays']),
      recipeCatalogCount: i(json['recipeCatalogCount']),
      recipeMatchCount: i(json['recipeMatchCount']),
      preferencesKnown: json['preferencesKnown'] == true,
      allergies: strings(json['allergies']),
      dislikes: strings(json['dislikes']),
      dietTypeName: json['dietTypeName'] as String?,
      planLines: strings(json['planLines']),
      shoppingManual: i(json['shoppingManual']),
      shoppingFromPlan: i(json['shoppingFromPlan']),
      shoppingManualNames: strings(json['shoppingManualNames']),
      weightKg: d(json['weightKg']),
      startWeightKg: d(json['startWeightKg']),
      targetWeightKg: d(json['targetWeightKg']),
    );
  }

  @override
  List<Object?> get props => [
    kind,
    recordsMissing,
    personalTarget,
    consumedCalories,
    targetCalories,
    mealCount,
    loggedMealTypes,
    missingMealTypes,
    foodTagsKnown,
    presentFoodTags,
    macrosRecorded,
    proteinG,
    proteinTargetG,
    carbsG,
    carbsTargetG,
    fatG,
    fatTargetG,
    targetBelowSafeFloor,
    waterMl,
    waterGoalMl,
    waterKnown,
    elapsedDays,
    mealDays,
    waterDays,
    recipeCatalogCount,
    recipeMatchCount,
    preferencesKnown,
    allergies,
    dislikes,
    dietTypeName,
    planLines,
    shoppingManual,
    shoppingFromPlan,
    shoppingManualNames,
    weightKg,
    startWeightKg,
    targetWeightKg,
  ];
}

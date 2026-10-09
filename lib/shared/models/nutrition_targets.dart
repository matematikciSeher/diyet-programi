import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/json_utils.dart';

/// Kullanıcının günlük hedefleri.
class NutritionTargets extends Equatable {
  const NutritionTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 25,
    this.waterMl = AppConstants.defaultWaterGoalMl,
    this.steps = 8000,
  });

  /// Profilde hedef hesaplanmamışsa (ör. onboarding atlanmış) kullanılır.
  static const fallback = NutritionTargets(
    calories: 2000,
    proteinG: 100,
    carbsG: 250,
    fatG: 67,
  );

  factory NutritionTargets.fromJson(Map<String, dynamic> json) {
    return NutritionTargets(
      calories: JsonUtils.readDouble(json['calories']),
      proteinG: JsonUtils.readDouble(json['proteinG']),
      carbsG: JsonUtils.readDouble(json['carbsG']),
      fatG: JsonUtils.readDouble(json['fatG']),
      fiberG: JsonUtils.readDouble(json['fiberG'], 25),
      waterMl: JsonUtils.readInt(
        json['waterMl'],
        AppConstants.defaultWaterGoalMl,
      ),
      steps: JsonUtils.readInt(json['steps'], 8000),
    );
  }

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final int waterMl;
  final int steps;

  NutritionTargets copyWith({
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    int? waterMl,
    int? steps,
  }) {
    return NutritionTargets(
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      waterMl: waterMl ?? this.waterMl,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'fiberG': fiberG,
    'waterMl': waterMl,
    'steps': steps,
  };

  @override
  List<Object?> get props => [
    calories,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    waterMl,
    steps,
  ];
}

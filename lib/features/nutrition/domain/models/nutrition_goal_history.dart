import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';

/// Kalori/makro hedefinin neden değiştiği (veya değişmediği).
enum GoalChangeReason { weightChange, profileUpdate, manualRecalculate }

/// Kullanıcının onayladığı veya reddettiği bir kalori hedefi değişikliği.
///
/// Konum: `users/{uid}/nutrition_goal_history/{id}`.
class NutritionGoalHistory extends Equatable {
  const NutritionGoalHistory({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.previousCalories,
    required this.newCalories,
    required this.approved,
    required this.reason,
    this.weightKg,
    this.previousProteinG,
    this.newProteinG,
    this.previousCarbsG,
    this.newCarbsG,
    this.previousFatG,
    this.newFatG,
  });

  factory NutritionGoalHistory.fromJson(Map<String, dynamic> json) =>
      NutritionGoalHistory(
        id: JsonUtils.readString(json['id']),
        userId: JsonUtils.readString(json['userId']),
        createdAt: JsonUtils.readDateOr(json['createdAt'], DateTime.now()),
        previousCalories: JsonUtils.readIntOrNull(json['previousCalories']),
        newCalories: JsonUtils.readInt(json['newCalories']),
        weightKg: JsonUtils.readDoubleOrNull(json['weightKg']),
        previousProteinG: JsonUtils.readIntOrNull(json['previousProteinG']),
        newProteinG: JsonUtils.readIntOrNull(json['newProteinG']),
        previousCarbsG: JsonUtils.readIntOrNull(json['previousCarbsG']),
        newCarbsG: JsonUtils.readIntOrNull(json['newCarbsG']),
        previousFatG: JsonUtils.readIntOrNull(json['previousFatG']),
        newFatG: JsonUtils.readIntOrNull(json['newFatG']),
        approved: json['approved'] == true,
        reason:
            JsonUtils.readEnumOrNull(
              GoalChangeReason.values,
              json['reason'],
            ) ??
            GoalChangeReason.manualRecalculate,
      );

  final String id;
  final String userId;
  final DateTime createdAt;
  final int? previousCalories;
  final int newCalories;
  final double? weightKg;
  final int? previousProteinG;
  final int? newProteinG;
  final int? previousCarbsG;
  final int? newCarbsG;
  final int? previousFatG;
  final int? newFatG;
  final bool approved;
  final GoalChangeReason reason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'previousCalories': previousCalories,
    'newCalories': newCalories,
    'weightKg': weightKg,
    'previousProteinG': previousProteinG,
    'newProteinG': newProteinG,
    'previousCarbsG': previousCarbsG,
    'newCarbsG': newCarbsG,
    'previousFatG': previousFatG,
    'newFatG': newFatG,
    'approved': approved,
    'reason': reason.name,
  };

  @override
  List<Object?> get props => [
    id,
    userId,
    createdAt,
    previousCalories,
    newCalories,
    weightKg,
    previousProteinG,
    newProteinG,
    previousCarbsG,
    newCarbsG,
    previousFatG,
    newFatG,
    approved,
    reason,
  ];
}

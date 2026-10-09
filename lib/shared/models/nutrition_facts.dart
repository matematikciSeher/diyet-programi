import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';

/// Enerji ve makro/mikro besin değerleri.
///
/// Birimler: kalori kcal, diğerleri gram; sodyum mg.
class NutritionFacts extends Equatable {
  const NutritionFacts({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG,
    this.sugarG,
    this.saturatedFatG,
    this.sodiumMg,
  });

  static const zero = NutritionFacts();

  factory NutritionFacts.fromJson(Map<String, dynamic> json) {
    return NutritionFacts(
      calories: JsonUtils.readDouble(json['calories']),
      proteinG: JsonUtils.readDouble(json['proteinG']),
      carbsG: JsonUtils.readDouble(json['carbsG']),
      fatG: JsonUtils.readDouble(json['fatG']),
      fiberG: JsonUtils.readDoubleOrNull(json['fiberG']),
      sugarG: JsonUtils.readDoubleOrNull(json['sugarG']),
      saturatedFatG: JsonUtils.readDoubleOrNull(json['saturatedFatG']),
      sodiumMg: JsonUtils.readDoubleOrNull(json['sodiumMg']),
    );
  }

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? saturatedFatG;
  final double? sodiumMg;

  NutritionFacts operator +(NutritionFacts other) {
    return NutritionFacts(
      calories: calories + other.calories,
      proteinG: proteinG + other.proteinG,
      carbsG: carbsG + other.carbsG,
      fatG: fatG + other.fatG,
      fiberG: _sumNullable(fiberG, other.fiberG),
      sugarG: _sumNullable(sugarG, other.sugarG),
      saturatedFatG: _sumNullable(saturatedFatG, other.saturatedFatG),
      sodiumMg: _sumNullable(sodiumMg, other.sodiumMg),
    );
  }

  /// Değerleri [factor] ile ölçekler (ör. 100 g değerinden porsiyona).
  NutritionFacts scale(double factor) {
    return NutritionFacts(
      calories: calories * factor,
      proteinG: proteinG * factor,
      carbsG: carbsG * factor,
      fatG: fatG * factor,
      fiberG: fiberG == null ? null : fiberG! * factor,
      sugarG: sugarG == null ? null : sugarG! * factor,
      saturatedFatG: saturatedFatG == null ? null : saturatedFatG! * factor,
      sodiumMg: sodiumMg == null ? null : sodiumMg! * factor,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    if (fiberG != null) 'fiberG': fiberG,
    if (sugarG != null) 'sugarG': sugarG,
    if (saturatedFatG != null) 'saturatedFatG': saturatedFatG,
    if (sodiumMg != null) 'sodiumMg': sodiumMg,
  };

  static double? _sumNullable(double? a, double? b) =>
      (a == null && b == null) ? null : (a ?? 0) + (b ?? 0);

  @override
  List<Object?> get props => [
    calories,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    sugarG,
    saturatedFatG,
    sodiumMg,
  ];
}

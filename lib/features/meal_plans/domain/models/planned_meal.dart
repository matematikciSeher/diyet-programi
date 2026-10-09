import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/nutrition_facts.dart';
import 'plan_ingredient.dart';
import 'plan_item.dart';

/// Yemek planında belirli bir gün ve öğün için önerilen yemek.
class PlannedMeal extends Equatable {
  const PlannedMeal({
    required this.id,
    required this.dayKey,
    required this.mealType,
    required this.title,
    required this.nutrition,
    this.items = const [],
    this.templateId,
    this.portionFactor = 1,
    this.description,
    this.recipeId,
    this.timeMinutes,
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
    id: JsonUtils.readString(json['id']),
    dayKey: JsonUtils.readString(json['dayKey']),
    mealType: JsonUtils.readEnum(
      MealType.values,
      json['mealType'],
      MealType.snack,
    ),
    title: JsonUtils.readString(json['title']),
    nutrition: NutritionFacts.fromJson(JsonUtils.readMap(json['nutrition'])),
    items: JsonUtils.readMapList(json['items']).map(PlanItem.fromJson).toList(),
    templateId: JsonUtils.readStringOrNull(json['templateId']),
    portionFactor: JsonUtils.readDouble(json['portionFactor'], 1),
    description: JsonUtils.readStringOrNull(json['description']),
    recipeId: JsonUtils.readStringOrNull(json['recipeId']),
    timeMinutes: JsonUtils.readIntOrNull(json['timeMinutes']),
  );

  final String id;
  final String dayKey;
  final MealType mealType;
  final String title;

  /// [portionFactor] uygulanmış toplam besin değerleri.
  final NutritionFacts nutrition;

  /// Tek porsiyon için yiyecekler; miktarlar [portionFactor] ile çarpılır.
  final List<PlanItem> items;

  /// Öğünün üretildiği şablon; aynı gün tekrar önerilmemesi için.
  final String? templateId;

  /// Kalori hedefine göre porsiyon çarpanı (ör. 1.25).
  final double portionFactor;
  final String? description;
  final String? recipeId;

  /// Gece yarısından itibaren dakika (ör. 08:30 → 510).
  final int? timeMinutes;

  Set<PlanIngredient> get ingredients => {
    for (final item in items) ...item.ingredients,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayKey': dayKey,
    'mealType': mealType.name,
    'title': title,
    'nutrition': nutrition.toJson(),
    'items': [for (final item in items) item.toJson()],
    'templateId': templateId,
    'portionFactor': portionFactor,
    'description': description,
    'recipeId': recipeId,
    'timeMinutes': timeMinutes,
  };

  @override
  List<Object?> get props => [
    id,
    dayKey,
    mealType,
    title,
    nutrition,
    items,
    templateId,
    portionFactor,
    description,
    recipeId,
    timeMinutes,
  ];
}

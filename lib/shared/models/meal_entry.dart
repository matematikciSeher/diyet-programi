import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';
import 'enums.dart';
import 'food.dart';
import 'nutrition_facts.dart';

/// Günlüğe eklenmiş tek bir yiyecek kaydı (FoodEntry).
/// Konum: `users/{uid}/meal_entries/{id}`.
class MealEntry extends Equatable {
  const MealEntry({
    required this.id,
    required this.dayKey,
    required this.mealType,
    required this.name,
    required this.quantityGrams,
    required this.nutrition,
    required this.loggedAt,
    this.foodId,
    this.recipeId,
    this.servingLabel,
    this.quantity,
    this.unit,
    this.source = FoodSource.database,
    this.tags = const {},
    this.updatedAt,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: JsonUtils.readString(json['id']),
      dayKey: JsonUtils.readString(json['dayKey']),
      mealType: JsonUtils.readEnum(
        MealType.values,
        json['mealType'],
        MealType.snack,
      ),
      name: JsonUtils.readString(json['name']),
      quantityGrams: JsonUtils.readDouble(json['quantityGrams']),
      nutrition: NutritionFacts.fromJson(JsonUtils.readMap(json['nutrition'])),
      loggedAt: JsonUtils.readDateOr(json['loggedAt'], DateTime.now()),
      foodId: json['foodId'] as String?,
      recipeId: json['recipeId'] as String?,
      servingLabel: json['servingLabel'] as String?,
      quantity: JsonUtils.readDoubleOrNull(json['quantity']),
      unit: JsonUtils.readEnumOrNull(PortionUnit.values, json['unit']),
      source: JsonUtils.readEnum(
        FoodSource.values,
        json['source'],
        FoodSource.database,
      ),
      tags: JsonUtils.readStringList(json['tags'])
          .map((t) => JsonUtils.readEnumOrNull(FoodTag.values, t))
          .nonNulls
          .toSet(),
      updatedAt: JsonUtils.readDate(json['updatedAt']),
    );
  }

  final String id;

  /// `yyyy-MM-dd`; günlük sorgular için indekslenir.
  final String dayKey;
  final MealType mealType;
  final String name;

  /// Toplam miktar, temel ölçüde (g veya ml).
  final double quantityGrams;
  final NutritionFacts nutrition;

  /// Kaydın oluşturulma zamanı (createdAt); günlükteki sıralama buna göredir.
  final DateTime loggedAt;
  final String? foodId;
  final String? recipeId;

  /// Kayıt anında oluşturulmuş yerelleştirilmiş porsiyon metni
  /// (ör. "2 dilim (50 g)"). Miktar düzenlenince temizlenir.
  final String? servingLabel;

  /// Seçilen ölçü biriminde miktar (ör. 2 × [PortionUnit.piece]).
  final double? quantity;
  final PortionUnit? unit;
  final FoodSource source;
  final Set<FoodTag> tags;
  final DateTime? updatedAt;

  DateTime get createdAt => loggedAt;
  double get calories => nutrition.calories;
  double get protein => nutrition.proteinG;
  double get carbohydrates => nutrition.carbsG;
  double get fat => nutrition.fatG;
  double? get fiber => nutrition.fiberG;

  /// Miktar ve besin değerleri oransal ölçeklenebilir mi?
  bool get isScalable => quantityGrams > 0 || (quantity ?? 0) > 0;

  MealEntry copyWith({
    String? id,
    String? dayKey,
    MealType? mealType,
    DateTime? loggedAt,
    DateTime? updatedAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      mealType: mealType ?? this.mealType,
      name: name,
      quantityGrams: quantityGrams,
      nutrition: nutrition,
      loggedAt: loggedAt ?? this.loggedAt,
      foodId: foodId,
      recipeId: recipeId,
      servingLabel: servingLabel,
      quantity: quantity,
      unit: unit,
      source: source,
      tags: tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Miktarı [factor] ile çarpar; besin değerleri de aynı oranda değişir.
  /// Eski porsiyon metni artık geçerli olmadığından kaldırılır.
  MealEntry scaled(double factor) {
    if (factor == 1) return this;
    final q = quantity;
    return MealEntry(
      id: id,
      dayKey: dayKey,
      mealType: mealType,
      name: name,
      quantityGrams: quantityGrams * factor,
      nutrition: nutrition.scale(factor),
      loggedAt: loggedAt,
      foodId: foodId,
      recipeId: recipeId,
      quantity: q == null ? null : q * factor,
      unit: unit,
      source: source,
      tags: tags,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayKey': dayKey,
    'mealType': mealType.name,
    'name': name,
    'quantityGrams': quantityGrams,
    'nutrition': nutrition.toJson(),
    'loggedAt': loggedAt.toIso8601String(),
    'foodId': foodId,
    'recipeId': recipeId,
    'servingLabel': servingLabel,
    if (quantity != null) 'quantity': quantity,
    if (unit != null) 'unit': unit!.name,
    'source': source.name,
    'tags': [for (final t in tags) t.name],
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    dayKey,
    mealType,
    name,
    quantityGrams,
    nutrition,
    loggedAt,
    foodId,
    recipeId,
    servingLabel,
    quantity,
    unit,
    source,
    tags,
    updatedAt,
  ];
}

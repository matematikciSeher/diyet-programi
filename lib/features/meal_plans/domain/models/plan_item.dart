import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/nutrition_facts.dart';
import 'plan_ingredient.dart';

/// Planlanan öğündeki tek bir yiyecek (ör. "🥚 Haşlanmış yumurta · 2 adet").
class PlanItem extends Equatable {
  const PlanItem({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.grams,
    required this.nutrition,
    this.ingredients = const {},
    this.tags = const {},
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
    emoji: JsonUtils.readString(json['emoji']),
    name: JsonUtils.readString(json['name']),
    amount: JsonUtils.readString(json['amount']),
    grams: JsonUtils.readDouble(json['grams']),
    nutrition: NutritionFacts.fromJson(JsonUtils.readMap(json['nutrition'])),
    ingredients: JsonUtils.readStringList(json['ingredients'])
        .map((i) => JsonUtils.readEnumOrNull(PlanIngredient.values, i))
        .nonNulls
        .toSet(),
    tags: JsonUtils.readStringList(
      json['tags'],
    ).map((t) => JsonUtils.readEnumOrNull(FoodTag.values, t)).nonNulls.toSet(),
  );

  final String emoji;
  final String name;

  /// Ev ölçüsüyle miktar (ör. "2 adet", "1 kase").
  final String amount;
  final double grams;

  /// [amount] miktarı için besin değerleri.
  final NutritionFacts nutrition;
  final Set<PlanIngredient> ingredients;
  final Set<FoodTag> tags;

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'name': name,
    'amount': amount,
    'grams': grams,
    'nutrition': nutrition.toJson(),
    'ingredients': [for (final i in ingredients) i.name],
    'tags': [for (final t in tags) t.name],
  };

  @override
  List<Object?> get props => [
    emoji,
    name,
    amount,
    grams,
    nutrition,
    ingredients,
    tags,
  ];
}

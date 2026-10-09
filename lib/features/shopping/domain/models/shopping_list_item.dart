import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';

enum ShoppingCategory {
  produce,
  meat,
  dairy,
  grains,
  breakfast,
  other;

  static ShoppingCategory forName(String name) {
    final n = _fold(name);
    if (_produce.any(n.contains)) return produce;
    if (_meat.any(n.contains)) return meat;
    if (_dairy.any(n.contains)) return dairy;
    if (_breakfast.any(n.contains)) return breakfast;
    if (_grains.any(n.contains)) return grains;
    return other;
  }

  static String _fold(String value) => value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  static const _produce = [
    'domates',
    'salatalik',
    'biber',
    'sogan',
    'sarimsak',
    'marul',
    'salata',
    'havuc',
    'patlican',
    'kabak',
    'brokoli',
    'ispanak',
    'maydanoz',
    'limon',
    'elma',
    'muz',
    'cilek',
    'portakal',
    'meyve',
    'sebze',
    'roka',
    'avokado',
    'patates',
  ];
  static const _meat = [
    'tavuk',
    'et',
    'kofte',
    'dana',
    'kuzu',
    'hindi',
    'balik',
    'somon',
    'ton',
    'karides',
  ];
  static const _dairy = [
    'sut',
    'yogurt',
    'peynir',
    'ayran',
    'kaymak',
    'tereyag',
    'lor',
  ];
  static const _grains = [
    'pirinc',
    'bulgur',
    'makarna',
    'nohut',
    'mercimek',
    'fasulye',
    'yulaf',
    'kinoa',
    'un',
  ];
  static const _breakfast = [
    'yumurta',
    'ekmek',
    'zeytin',
    'bal',
    'recel',
    'tahin',
    'pekmez',
    'simit',
  ];
}

class ShoppingListItem extends Equatable {
  const ShoppingListItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.sourceRecipeId,
    this.sourceMealPlanId,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) =>
      ShoppingListItem(
        id: JsonUtils.readString(json['id']),
        userId: JsonUtils.readString(json['userId']),
        name: JsonUtils.readString(json['name']),
        quantity: JsonUtils.readDouble(json['quantity'], 1),
        unit: JsonUtils.readString(json['unit']),
        category:
            JsonUtils.readEnumOrNull(
              ShoppingCategory.values,
              json['category'],
            ) ??
            ShoppingCategory.other,
        isCompleted: json['isCompleted'] == true,
        sourceRecipeId: JsonUtils.readStringOrNull(json['sourceRecipeId']),
        sourceMealPlanId: JsonUtils.readStringOrNull(json['sourceMealPlanId']),
        createdAt: JsonUtils.readDateOr(json['createdAt'], DateTime.now()),
        updatedAt: JsonUtils.readDateOr(json['updatedAt'], DateTime.now()),
      );

  final String id;
  final String userId;
  final String name;
  final double quantity;
  final String unit;
  final ShoppingCategory category;
  final bool isCompleted;
  final String? sourceRecipeId;
  final String? sourceMealPlanId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingListItem copyWith({
    double? quantity,
    bool? isCompleted,
    String? sourceRecipeId,
    String? sourceMealPlanId,
    DateTime? updatedAt,
  }) => ShoppingListItem(
    id: id,
    userId: userId,
    name: name,
    quantity: quantity ?? this.quantity,
    unit: unit,
    category: category,
    isCompleted: isCompleted ?? this.isCompleted,
    sourceRecipeId: sourceRecipeId ?? this.sourceRecipeId,
    sourceMealPlanId: sourceMealPlanId ?? this.sourceMealPlanId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'category': category.name,
    'isCompleted': isCompleted,
    'sourceRecipeId': sourceRecipeId,
    'sourceMealPlanId': sourceMealPlanId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    quantity,
    unit,
    category,
    isCompleted,
    sourceRecipeId,
    sourceMealPlanId,
    createdAt,
    updatedAt,
  ];
}

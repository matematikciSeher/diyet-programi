import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';
import 'enums.dart';
import 'nutrition_facts.dart';

/// Besin değerlerinin referans aldığı temel ölçü: 100 g ya da 100 ml.
enum NutritionBasis { gram, milliliter }

/// Kullanıcının miktar girerken seçebileceği ölçü birimleri.
enum PortionUnit {
  gram,
  milliliter,
  piece,
  slice,
  serving,
  bowl,
  glass,
  tablespoon,
  teaspoon;

  bool get isBaseUnit => this == gram || this == milliliter;
}

/// Bir ölçü biriminin temel ölçü karşılığı.
///
/// [baseAmount], 1 [unit]'in kaç gram (veya ml; bkz. [Food.basis]) olduğunu
/// belirtir. Ör. `FoodPortion(unit: piece, baseAmount: 50)` = "1 adet 50 g".
class FoodPortion extends Equatable {
  const FoodPortion({
    required this.unit,
    required this.baseAmount,
    this.description,
  });

  factory FoodPortion.fromJson(Map<String, dynamic> json) => FoodPortion(
    unit: JsonUtils.readEnum(
      PortionUnit.values,
      json['unit'],
      PortionUnit.serving,
    ),
    baseAmount: JsonUtils.readDouble(json['baseAmount']),
    description: JsonUtils.readStringOrNull(json['description']),
  );

  final PortionUnit unit;
  final double baseAmount;

  /// Veri kaynağının verdiği ek açıklama (ör. "orta boy").
  final String? description;

  Map<String, dynamic> toJson() => {
    'unit': unit.name,
    'baseAmount': baseAmount,
    if (description != null) 'description': description,
  };

  @override
  List<Object?> get props => [unit, baseAmount, description];
}

/// Tarifi oluşturan tek bir malzeme. Besin değeri, tarif kaydedildiği andaki
/// değerle saklanır; kaynak yiyecek sonradan değişse de tarif değişmez.
class FoodIngredient extends Equatable {
  const FoodIngredient({
    required this.foodId,
    required this.name,
    required this.portion,
    required this.quantity,
    required this.grams,
    required this.nutrition,
  });

  factory FoodIngredient.fromJson(Map<String, dynamic> json) => FoodIngredient(
    foodId: JsonUtils.readString(json['foodId']),
    name: JsonUtils.readString(json['name']),
    portion: FoodPortion.fromJson(JsonUtils.readMap(json['portion'])),
    quantity: JsonUtils.readDouble(json['quantity']),
    grams: JsonUtils.readDouble(json['grams']),
    nutrition: NutritionFacts.fromJson(JsonUtils.readMap(json['nutrition'])),
  );

  final String foodId;
  final String name;
  final FoodPortion portion;
  final double quantity;
  final double grams;
  final NutritionFacts nutrition;

  Map<String, dynamic> toJson() => {
    'foodId': foodId,
    'name': name,
    'portion': portion.toJson(),
    'quantity': quantity,
    'grams': grams,
    'nutrition': nutrition.toJson(),
  };

  @override
  List<Object?> get props => [
    foodId,
    name,
    portion,
    quantity,
    grams,
    nutrition,
  ];
}

/// Veritabanındaki bir yiyecek, paketli ürün, kullanıcı yiyeceği ya da tarif.
///
/// Besin değerleri [basis]'e göre 100 g veya 100 ml içindir.
class Food extends Equatable {
  const Food({
    required this.id,
    required this.name,
    required this.nutritionPer100,
    this.basis = NutritionBasis.gram,
    this.gramsPerMl,
    this.brand,
    this.barcode,
    this.imageUrl,
    this.portions = const [],
    this.keywords = const [],
    this.tags = const {},
    this.ingredients = const [],
    this.source = FoodSource.database,
    this.isVerified = false,
    this.isSample = false,
    this.dataReference,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: JsonUtils.readString(json['id']),
      name: JsonUtils.readString(json['name']),
      nutritionPer100: NutritionFacts.fromJson(
        JsonUtils.readMap(json['nutritionPer100']),
      ),
      basis: JsonUtils.readEnum(
        NutritionBasis.values,
        json['basis'],
        NutritionBasis.gram,
      ),
      gramsPerMl: JsonUtils.readDoubleOrNull(json['gramsPerMl']),
      brand: JsonUtils.readStringOrNull(json['brand']),
      barcode: JsonUtils.readStringOrNull(json['barcode']),
      imageUrl: JsonUtils.readStringOrNull(json['imageUrl']),
      portions: JsonUtils.readMapList(
        json['portions'],
      ).map(FoodPortion.fromJson).toList(),
      keywords: JsonUtils.readStringList(json['keywords']),
      tags: JsonUtils.readStringList(json['tags'])
          .map((t) => JsonUtils.readEnumOrNull(FoodTag.values, t))
          .nonNulls
          .toSet(),
      ingredients: JsonUtils.readMapList(
        json['ingredients'],
      ).map(FoodIngredient.fromJson).toList(),
      source: JsonUtils.readEnum(
        FoodSource.values,
        json['source'],
        FoodSource.database,
      ),
      isVerified: json['isVerified'] == true,
      isSample: json['isSample'] == true,
      dataReference: JsonUtils.readStringOrNull(json['dataReference']),
    );
  }

  final String id;
  final String name;
  final NutritionFacts nutritionPer100;
  final NutritionBasis basis;

  /// Yoğunluk; biliniyorsa gram ve ml birbirine çevrilebilir.
  final double? gramsPerMl;
  final String? brand;
  final String? barcode;
  final String? imageUrl;

  /// Temel ölçü (g/ml) dışındaki birimler: adet, dilim, kase...
  final List<FoodPortion> portions;

  /// Aramada eşleşecek eş anlamlılar (ör. "egg").
  final List<String> keywords;
  final Set<FoodTag> tags;

  /// Yalnızca tariflerde dolu.
  final List<FoodIngredient> ingredients;
  final FoodSource source;
  final bool isVerified;

  /// Demo/örnek veri kümesinden geliyorsa `true`; arayüzde belirtilir.
  final bool isSample;

  /// Besin değerlerinin alındığı kaynak (ör. "USDA FoodData Central").
  final String? dataReference;

  bool get isRecipe => source == FoodSource.recipe;
  bool get isUserCreated =>
      source == FoodSource.custom || source == FoodSource.recipe;

  Food copyWith({String? id, FoodSource? source}) => Food(
    id: id ?? this.id,
    name: name,
    nutritionPer100: nutritionPer100,
    basis: basis,
    gramsPerMl: gramsPerMl,
    brand: brand,
    barcode: barcode,
    imageUrl: imageUrl,
    portions: portions,
    keywords: keywords,
    tags: tags,
    ingredients: ingredients,
    source: source ?? this.source,
    isVerified: isVerified,
    isSample: isSample,
    dataReference: dataReference,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nutritionPer100': nutritionPer100.toJson(),
    'basis': basis.name,
    if (gramsPerMl != null) 'gramsPerMl': gramsPerMl,
    if (brand != null) 'brand': brand,
    if (barcode != null) 'barcode': barcode,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'portions': [for (final p in portions) p.toJson()],
    'keywords': keywords,
    'tags': [for (final t in tags) t.name],
    if (ingredients.isNotEmpty)
      'ingredients': [for (final i in ingredients) i.toJson()],
    'source': source.name,
    'isVerified': isVerified,
    'isSample': isSample,
    if (dataReference != null) 'dataReference': dataReference,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    nutritionPer100,
    basis,
    gramsPerMl,
    brand,
    barcode,
    imageUrl,
    portions,
    keywords,
    tags,
    ingredients,
    source,
    isVerified,
    isSample,
    dataReference,
  ];
}

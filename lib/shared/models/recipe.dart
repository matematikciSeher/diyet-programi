import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';
import 'enums.dart';
import 'nutrition_facts.dart';

/// Tarifin nereden geldiği. Katalog/seed uygulama içindedir; kullanıcı
/// tarifleri `users/{uid}/recipes` altındadır.
enum RecipeSource { catalog, seed, user }

class RecipeIngredient extends Equatable {
  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.id = '',
    this.foodId,
    this.grams,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        id: JsonUtils.readString(json['id']),
        name: JsonUtils.readString(json['name']),
        quantity: JsonUtils.readDouble(json['quantity']),
        unit: JsonUtils.readString(json['unit']),
        foodId: json['foodId'] as String?,
        grams: JsonUtils.readDoubleOrNull(json['grams']),
      );

  final String id;
  final String name;
  final double quantity;
  final String unit;

  /// Varsa [Food.id]. Besin değeri tarifte ikinci kez tutulmaz; hesap
  /// [foodId] ve [grams] üzerinden yapılır.
  final String? foodId;

  /// Malzemenin gram karşılığı. Bilinmiyorsa `null`.
  final double? grams;

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'foodId': foodId,
    if (grams != null) 'grams': grams,
  };

  @override
  List<Object?> get props => [id, name, quantity, unit, foodId, grams];
}

/// Uygulama kataloğundaki ya da kullanıcının oluşturduğu tarif.
///
/// Enerji ve makrolar yalnızca [nutritionPerServing] içinde tutulur.
/// [tags] hem öğün (`breakfast`) hem nitelik (`high_protein`) etiketlerini taşır.
class Recipe extends Equatable {
  const Recipe({
    required this.id,
    required this.title,
    required this.servings,
    required this.nutritionPerServing,
    this.description,
    this.imageUrl,
    this.prepMinutes,
    this.cookMinutes,
    this.ingredients = const [],
    this.steps = const [],
    this.tags = const [],
    this.isPremium = false,
    this.authorId,
    this.category,
    this.mealTypes = const [],
    this.source = RecipeSource.catalog,
    this.createdAt,
    this.updatedAt,
    this.isDemo = false,
    this.nutritionReference,
    this.allergens = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final authorId = JsonUtils.readStringOrNull(json['authorId']);
    final title = JsonUtils.readString(json['title']);
    return Recipe(
      id: JsonUtils.readString(json['id']),
      title: title.isEmpty ? JsonUtils.readString(json['name']) : title,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      servings: JsonUtils.readInt(json['servings'], 1),
      prepMinutes: json['prepMinutes'] == null
          ? JsonUtils.readIntOrNull(json['prepTimeMinutes'])
          : JsonUtils.readInt(json['prepMinutes']),
      cookMinutes: json['cookMinutes'] == null
          ? JsonUtils.readIntOrNull(json['cookTimeMinutes'])
          : JsonUtils.readInt(json['cookMinutes']),
      nutritionPerServing: NutritionFacts.fromJson(
        JsonUtils.readMap(json['nutritionPerServing']),
      ),
      ingredients: JsonUtils.readMapList(
        json['ingredients'],
      ).map(RecipeIngredient.fromJson).toList(),
      steps: JsonUtils.readStringList(
        json['steps'] is List ? json['steps'] : json['instructions'],
      ),
      tags: JsonUtils.readStringList(json['tags']),
      isPremium: json['isPremium'] == true,
      authorId: authorId,
      category: JsonUtils.readStringOrNull(json['category']),
      mealTypes: [
        for (final name in JsonUtils.readStringList(json['mealTypes']))
          ?JsonUtils.readEnumOrNull(MealType.values, name),
      ],
      source:
          JsonUtils.readEnumOrNull(RecipeSource.values, json['source']) ??
          (authorId != null ? RecipeSource.user : RecipeSource.catalog),
      createdAt: JsonUtils.readDate(json['createdAt']),
      updatedAt: JsonUtils.readDate(json['updatedAt']),
      isDemo: json['isDemo'] == true,
      nutritionReference: JsonUtils.readStringOrNull(
        json['nutritionReference'],
      ),
      allergens: JsonUtils.readStringList(json['allergens']),
    );
  }

  final String id;

  /// Görünen ad. JSON alanı tarihsel olarak `title`dır.
  final String title;
  final String? description;
  final String? imageUrl;
  final int servings;
  final int? prepMinutes;
  final int? cookMinutes;
  final NutritionFacts nutritionPerServing;
  final List<RecipeIngredient> ingredients;

  /// Hazırlanış adımları.
  final List<String> steps;
  final List<String> tags;
  final bool isPremium;

  /// Kullanıcının oluşturduğu tariflerde sahibi; katalog tariflerinde `null`.
  final String? authorId;

  /// Birincil kategori etiketi (`breakfast`, `salad`, `soup`...).
  final String? category;
  final List<MealType> mealTypes;
  final RecipeSource source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Besin değerleri örnek/demo besin verisinden hesaplandıysa `true`.
  final bool isDemo;

  /// Hesabın dayandığı kaynak (ör. USDA örnek kataloğu).
  final String? nutritionReference;

  /// [Allergen.name] değerleri. Filtre yalnızca buna güvenmez; malzeme
  /// kimlikleri de ayrıca taranır.
  final List<String> allergens;

  String get name => title;
  int get prepTimeMinutes => prepMinutes ?? 0;
  int get cookTimeMinutes => cookMinutes ?? 0;
  List<String> get instructions => steps;
  double get calories => nutritionPerServing.calories;
  double get protein => nutritionPerServing.proteinG;
  double get carbohydrates => nutritionPerServing.carbsG;
  double get fat => nutritionPerServing.fatG;
  double get fiber => nutritionPerServing.fiberG ?? 0;

  bool get isUserCreated => authorId != null || source == RecipeSource.user;

  int get totalMinutes => (prepMinutes ?? 0) + (cookMinutes ?? 0);

  Recipe copyWith({
    String? id,
    String? title,
    String? authorId,
    String? description,
    String? imageUrl,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    NutritionFacts? nutritionPerServing,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    List<String>? tags,
    bool? isPremium,
    String? category,
    List<MealType>? mealTypes,
    RecipeSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDemo,
    String? nutritionReference,
    List<String>? allergens,
  }) => Recipe(
    id: id ?? this.id,
    title: title ?? this.title,
    servings: servings ?? this.servings,
    nutritionPerServing: nutritionPerServing ?? this.nutritionPerServing,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    prepMinutes: prepMinutes ?? this.prepMinutes,
    cookMinutes: cookMinutes ?? this.cookMinutes,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    tags: tags ?? this.tags,
    isPremium: isPremium ?? this.isPremium,
    authorId: authorId ?? this.authorId,
    category: category ?? this.category,
    mealTypes: mealTypes ?? this.mealTypes,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDemo: isDemo ?? this.isDemo,
    nutritionReference: nutritionReference ?? this.nutritionReference,
    allergens: allergens ?? this.allergens,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'servings': servings,
    'prepMinutes': prepMinutes,
    'cookMinutes': cookMinutes,
    'nutritionPerServing': nutritionPerServing.toJson(),
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'steps': steps,
    'tags': tags,
    'isPremium': isPremium,
    'authorId': authorId,
    if (category != null) 'category': category,
    if (mealTypes.isNotEmpty)
      'mealTypes': [for (final m in mealTypes) m.name],
    'source': source.name,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'isDemo': isDemo,
    if (nutritionReference != null) 'nutritionReference': nutritionReference,
    if (allergens.isNotEmpty) 'allergens': allergens,
  };

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    servings,
    prepMinutes,
    cookMinutes,
    nutritionPerServing,
    ingredients,
    steps,
    tags,
    isPremium,
    authorId,
    category,
    mealTypes,
    source,
    createdAt,
    updatedAt,
    isDemo,
    nutritionReference,
    allergens,
  ];
}

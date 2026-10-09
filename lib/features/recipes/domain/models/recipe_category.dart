import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';

/// Tarif listesindeki filtreler. Öğün/tatlı/içecek kategorileri
/// [Recipe.tags]'te saklanır; "Yüksek Protein" ve "Düşük Kalori" besin
/// değerlerinden hesaplanır.
enum RecipeCategory {
  breakfast,
  lunch,
  dinner,
  snack,
  dessert,
  drink,
  highProtein,
  lowCalorie;

  /// Kullanıcının tarif oluştururken seçebildiği (saklanan) kategoriler.
  static const assignable = [breakfast, lunch, dinner, snack, dessert, drink];

  /// Porsiyon başı en az bu kadar protein (g) "Yüksek Protein" sayılır.
  static const highProteinGrams = 25.0;

  /// Porsiyon başı en fazla bu kadar enerji (kcal) "Düşük Kalori" sayılır.
  static const lowCalorieKcal = 300.0;

  bool get isComputed => this == highProtein || this == lowCalorie;

  MealType? get mealType => switch (this) {
    breakfast => MealType.breakfast,
    lunch => MealType.lunch,
    dinner => MealType.dinner,
    snack || dessert || drink => MealType.snack,
    highProtein || lowCalorie => null,
  };

  static Set<RecipeCategory> of(Recipe recipe) {
    final n = recipe.nutritionPerServing;
    return {
      for (final tag in recipe.tags) ?_stored(tag),
      if (n.proteinG >= highProteinGrams) highProtein,
      if (n.calories > 0 && n.calories <= lowCalorieKcal) lowCalorie,
    };
  }

  static RecipeCategory? _stored(String tag) {
    final normalized = switch (tag) {
      'high_protein' => 'highProtein',
      'low_calorie' => 'lowCalorie',
      _ => tag,
    };
    return RecipeCategory.values.where((c) => c.name == normalized).firstOrNull;
  }

  /// Tarifin günlüğe/plana varsayılan olarak ekleneceği öğün.
  static MealType defaultMealType(Recipe recipe) {
    for (final c in of(recipe)) {
      if (c.mealType case final type?) return type;
    }
    return MealType.snack;
  }
}

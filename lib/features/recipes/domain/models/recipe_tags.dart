/// Tarif etiketleri. Filtreler bu sabitlere bakar; ekranda ayrı boolean
/// alanlar tutulmaz.
abstract final class RecipeTags {
  static const highProtein = 'high_protein';
  static const quick = 'quick';
  static const lowCalorie = 'low_calorie';
  static const vegetarian = 'vegetarian';
  static const vegan = 'vegan';
  static const breakfast = 'breakfast';
  static const lunch = 'lunch';
  static const dinner = 'dinner';
  static const snack = 'snack';
  static const mealPrep = 'meal_prep';
  static const turkish = 'turkish';
  static const fiberRich = 'fiber_rich';
  static const salad = 'salad';
  static const soup = 'soup';
  static const practical = 'practical';

  static const dietary = [highProtein, lowCalorie, vegetarian, vegan, fiberRich];
}

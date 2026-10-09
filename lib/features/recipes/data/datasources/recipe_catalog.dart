import '../../../../shared/models/recipe.dart';
import 'recipe_seed.dart';

/// Uygulamayla gelen tarifler. Besin değerleri örnek USDA kataloğundan
/// porsiyon başına hesaplanır ve [Recipe.isDemo] ile işaretlenir.
abstract final class RecipeCatalog {
  static const idPrefix = 'catalog-';

  static List<Recipe> get all => RecipeSeed.recipes;

  static Recipe? byId(String id) => RecipeSeed.byId(id);
}

import '../../../../shared/models/recipe.dart';

import 'recipe_image_assets.dart';

/// Katalog görselleri uygulama içi dosyadır. Uzak adres yalnızca kullanıcının
/// kendi tarifinde [Recipe.imageUrl] doluysa kullanılır. Dosya yoksa veya
/// yüklenemezse arayüz yer tutucuya düşer.
abstract final class RecipeImages {
  static String? urlFor(Recipe recipe) {
    final url = recipe.imageUrl;
    if (url == null || url.isEmpty) return null;
    return url;
  }

  static String? assetFor(Recipe recipe) => recipeImageAssets[recipe.id];

  static bool hasImage(Recipe recipe) =>
      assetFor(recipe) != null || urlFor(recipe) != null;

  /// Görseli olan tarifler üstte kalır. Her grubun kendi sırası korunur.
  static List<Recipe> withImagesFirst(List<Recipe> recipes) {
    final withImage = <Recipe>[];
    final withoutImage = <Recipe>[];
    for (final recipe in recipes) {
      if (hasImage(recipe)) {
        withImage.add(recipe);
      } else {
        withoutImage.add(recipe);
      }
    }
    return [...withImage, ...withoutImage];
  }
}

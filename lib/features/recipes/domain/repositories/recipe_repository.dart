import '../../../../core/errors/result.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';

abstract interface class RecipeRepository {
  /// Kullanıcının tarifleri (en yeni önce) ardından katalog tarifleri.
  Stream<List<Recipe>> watchRecipes();

  /// Katalogda ya da kullanıcının tariflerinde yoksa `null`.
  Stream<Recipe?> watchRecipe(String id);

  /// Kullanıcı tarifini kaydeder; id boşsa yeni id üretilir.
  Future<Result<Recipe>> saveRecipe(Recipe recipe);

  Future<Result<void>> deleteRecipe(String id);

  Stream<Set<String>> watchFavoriteIds();

  Future<Result<void>> setFavorite(String recipeId, {required bool favorite});

  /// Local katalog + kullanıcı tarifleri. Ağ beklemez.
  Future<List<Recipe>> getRecipes();

  Future<Recipe?> getRecipeById(String id);

  Future<List<Recipe>> searchRecipes(String query);

  Future<List<Recipe>> getRecipesByCategory(String category);

  Future<List<Recipe>> getRecipesByMealType(MealType mealType);

  Future<List<Recipe>> getFavoriteRecipes();

  /// Favori durumunu tersine çevirir. Sonuç yeni durumdur (`true` = favori).
  Future<Result<bool>> toggleFavorite(String recipeId);

  /// Profil filtrelerine göre sıralı öneri. Plan üretmez.
  Future<List<Recipe>> getRecommendedRecipes(UserProfile? profile);

  /// Verilen etiketlerin tümünü taşıyan tarifler.
  Future<List<Recipe>> getRecipesByTags(Set<String> tags);

  /// Son görüntülenenler, yeniden eskiye. Oturum yoksa boş yayınlar.
  Stream<List<Recipe>> watchRecent({int limit = 8});

  Future<Result<void>> recordView(String recipeId);
}

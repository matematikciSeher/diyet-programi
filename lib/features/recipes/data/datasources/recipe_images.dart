import '../../../../shared/models/recipe.dart';

/// Seed tarifler uzak görsel kullanmaz. Telifli stok URL bağlanmaz;
/// [RecipeImage] yer tutucu çizer. Yükleme bu aşamada yok.
abstract final class RecipeImages {
  static String? urlFor(Recipe recipe) => recipe.imageUrl;
}

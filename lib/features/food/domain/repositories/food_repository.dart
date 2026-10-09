import '../../../../core/errors/result.dart';
import '../../../../shared/models/food.dart';
import '../models/portion_selection.dart';
import '../models/recent_food.dart';

/// Yemek arama, barkod eşleme, kullanıcının kendi yiyecekleri/tarifleri,
/// favoriler ve son kullanılanlar. Veri kaynaklarını (harici veritabanı,
/// kullanıcı koleksiyonları) tek noktada birleştirir.
abstract interface class FoodRepository {
  /// Kullanıcının yiyecekleri ve veritabanı sonuçları birlikte, alaka
  /// düzeyine göre sıralı.
  Future<Result<List<Food>>> search(String query, {int page = 1});
  Future<Result<Food?>> getById(String id);
  Future<Result<Food?>> findByBarcode(String barcode);

  /// Çevrimdışı öneriler: özel, favori ve son kullanılanlar.
  Future<Result<List<Food>>> suggestions(String query);

  /// Kullanıcının oluşturduğu yiyecekler ve tarifler.
  Stream<List<Food>> watchCustomFoods();

  /// `id` boşsa yeni id üretilir.
  Future<Result<Food>> saveCustomFood(Food food);
  Future<Result<void>> deleteCustomFood(String id);

  /// En son eklenen önce.
  Stream<List<Food>> watchFavorites();
  Future<Result<void>> setFavorite(Food food, {required bool favorite});

  /// En son kullanılan önce.
  Stream<List<RecentFood>> watchRecents({int limit = 20});
  Future<Result<void>> recordRecent(
    Food food,
    PortionSelection selection, {
    required DateTime at,
  });
}

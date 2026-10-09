import '../../models/food.dart';

/// Harici yemek veritabanı API'si soyutlaması (arama + detay).
/// Implementasyon `ApiClient` üzerinden `AppConfig.foodApiBaseUrl`'e bağlanır
/// ya da backend proxy kullanır. Dönen sonuçlar alaka düzeyine göre sıralı
/// olmalıdır.
abstract interface class FoodDatabaseService {
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  });

  Future<Food?> getById(String id);
}

class EmptyFoodDatabaseService implements FoodDatabaseService {
  const EmptyFoodDatabaseService();

  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async => const [];

  @override
  Future<Food?> getById(String id) async => null;
}

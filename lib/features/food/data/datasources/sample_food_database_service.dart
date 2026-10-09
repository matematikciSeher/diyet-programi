import '../../../../shared/models/food.dart';
import '../../../../shared/services/barcode/barcode_lookup_service.dart';
import '../../../../shared/services/food_database/food_database_service.dart';
import '../../domain/services/food_search_service.dart';
import 'sample_food_catalog.dart';

/// [SampleFoodCatalog] üzerinde çalışan yerel veritabanı. Uzak bir yiyecek
/// veritabanıyla aynı arayüzü uygular; `useFakeServices` açıkken kullanılır.
class SampleFoodDatabaseService
    implements FoodDatabaseService, BarcodeLookupService {
  SampleFoodDatabaseService({
    List<Food>? foods,
    FoodSearchService search = const FoodSearchService(),
  }) : _foods = foods ?? SampleFoodCatalog.foods,
       _search = search;

  final List<Food> _foods;
  final FoodSearchService _search;

  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async {
    final ranked = _search.rank(_foods, query);
    return ranked.skip((page - 1) * pageSize).take(pageSize).toList();
  }

  @override
  Future<Food?> getById(String id) async {
    for (final food in _foods) {
      if (food.id == id) return food;
    }
    return null;
  }

  @override
  Future<Food?> lookup(String barcode) async {
    final code = barcode.trim();
    for (final food in _foods) {
      if (food.barcode == code) return food;
    }
    return null;
  }
}

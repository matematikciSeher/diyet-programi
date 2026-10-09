import '../../../../shared/models/food.dart';
import '../../../../shared/services/barcode/barcode_digits.dart';
import '../../../../shared/services/barcode/barcode_lookup_service.dart';
import '../../../../shared/services/food_database/food_database_service.dart';
import 'barcode_lookup_log.dart';
import 'food_api_config.dart';
import 'food_lookup_cache.dart';

/// Uzak yiyecek API'sini TTL önbellekle sarar. Ağ hatasında süresi dolmuş
/// önbellek de döndürülür; böylece çevrimdışı daha önce görülen ürünler
/// kullanılabilir.
class CachingFoodDatabaseService
    implements FoodDatabaseService, BarcodeLookupService {
  CachingFoodDatabaseService({
    required FoodDatabaseService database,
    required BarcodeLookupService barcodes,
    required FoodLookupCache cache,
  }) : _database = database,
       _barcodes = barcodes,
       _cache = cache;

  final FoodDatabaseService _database;
  final BarcodeLookupService _barcodes;
  final FoodLookupCache _cache;
  final _inflightSearches = <String, Future<List<Food>>>{};
  final _inflightLookups = <String, Future<Food?>>{};

  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = FoodApiConfig.searchPageSize,
    String? locale,
  }) async {
    final key = FoodLookupCache.searchKey(
      query: query,
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
    final fresh = _cache.search(key);
    if (fresh != null) return fresh;
    final pending = _inflightSearches[key];
    if (pending != null) return pending;
    final future = _loadSearch(
      key: key,
      query: query,
      page: page,
      pageSize: pageSize,
      locale: locale,
    );
    _inflightSearches[key] = future;
    return future;
  }

  Future<List<Food>> _loadSearch({
    required String key,
    required String query,
    required int page,
    required int pageSize,
    required String? locale,
  }) async {
    try {
      final foods = await _database.search(
        query,
        page: page,
        pageSize: pageSize,
        locale: locale,
      );
      await _cache.putSearch(key, foods);
      return foods;
    } on Object {
      final stale = _cache.search(key, allowExpired: true);
      if (stale != null) return stale;
      rethrow;
    } finally {
      _inflightSearches.remove(key)?.ignore();
    }
  }

  @override
  Future<Food?> getById(String id) async {
    final cached = _cache.product(id);
    if (cached != null) return cached;
    try {
      final food = await _database.getById(id);
      if (food != null) await _cache.putProduct(food);
      return food;
    } on Object {
      return _cache.product(id, allowExpired: true);
    }
  }

  @override
  Future<Food?> lookup(String barcode) async {
    final code = BarcodeDigits.normalize(barcode);
    if (code.isEmpty) return null;
    final cached = _cache.byBarcode(code);
    if (cached != null) {
      BarcodeLookupLog.write(
        barcode: code,
        source: 'cache',
        productFound: true,
        mapped: true,
        productName: cached.name,
        code: cached.barcode,
      );
      return cached;
    }
    final pending = _inflightLookups[code];
    if (pending != null) return pending;
    final future = _loadLookup(code);
    _inflightLookups[code] = future;
    return future;
  }

  Future<Food?> _loadLookup(String code) async {
    try {
      final food = await _barcodes.lookup(code);
      if (food != null) {
        await _cache.putProduct(food);
      }
      return food;
    } on Object {
      final stale = _cache.byBarcode(code, allowExpired: true);
      if (stale != null) {
        BarcodeLookupLog.write(
          barcode: code,
          source: 'offline',
          productFound: true,
          mapped: true,
          productName: stale.name,
          code: stale.barcode,
        );
        return stale;
      }
      rethrow;
    } finally {
      _inflightLookups.remove(code)?.ignore();
    }
  }
}

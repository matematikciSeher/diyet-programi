import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/features/food/data/datasources/caching_food_database_service.dart';
import 'package:diyet_programi/features/food/data/datasources/food_lookup_cache.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/barcode/barcode_lookup_service.dart';
import 'package:diyet_programi/shared/services/food_database/food_database_service.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingDb implements FoodDatabaseService, BarcodeLookupService {
  var searches = 0;
  var lookups = 0;
  final List<Food> foods;

  _CountingDb(this.foods);

  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async {
    searches++;
    return foods;
  }

  @override
  Future<Food?> getById(String id) async =>
      foods.where((f) => f.id == id).firstOrNull;

  @override
  Future<Food?> lookup(String barcode) async {
    lookups++;
    return foods.where((f) => f.barcode == barcode).firstOrNull;
  }
}

class _FailingDb implements FoodDatabaseService, BarcodeLookupService {
  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async => throw const NetworkException('no_connection', code: 'no_connection');

  @override
  Future<Food?> getById(String id) async =>
      throw const NetworkException('no_connection', code: 'no_connection');

  @override
  Future<Food?> lookup(String barcode) async =>
      throw const NetworkException('no_connection', code: 'no_connection');
}

const _apple = Food(
  id: 'off-1',
  name: 'Elma',
  barcode: '123',
  nutritionPer100: NutritionFacts(calories: 52),
);

void main() {
  test('aynı arama ikinci kez ağa gitmez', () async {
    final inner = _CountingDb(const [_apple]);
    final now = DateTime(2026, 9, 29, 12);
    final cache = FoodLookupCache(
      InMemoryKeyValueStorage(),
      clock: () => now,
    );
    final db = CachingFoodDatabaseService(
      database: inner,
      barcodes: inner,
      cache: cache,
    );
    expect(await db.search('elma'), hasLength(1));
    expect(await db.search('elma'), hasLength(1));
    expect(inner.searches, 1);
  });

  test('ağ düşünce süresi dolmuş önbellek döner', () async {
    final inner = _CountingDb(const [_apple]);
    var now = DateTime(2026, 9, 29, 12);
    final cache = FoodLookupCache(
      InMemoryKeyValueStorage(),
      clock: () => now,
      searchTtl: const Duration(minutes: 1),
    );
    final cached = CachingFoodDatabaseService(
      database: inner,
      barcodes: inner,
      cache: cache,
    );
    await cached.search('elma');
    now = now.add(const Duration(hours: 2));
    final offline = CachingFoodDatabaseService(
      database: _FailingDb(),
      barcodes: _FailingDb(),
      cache: cache,
    );
    expect((await offline.search('elma')).single.name, 'Elma');
  });

  test('barkod ürünü kalıcı önbelleğe yazılır', () async {
    final storage = InMemoryKeyValueStorage();
    final now = DateTime(2026, 9, 29);
    final cache = FoodLookupCache(storage, clock: () => now);
    final inner = _CountingDb(const [_apple]);
    final db = CachingFoodDatabaseService(
      database: inner,
      barcodes: inner,
      cache: cache,
    );
    expect((await db.lookup('123'))?.name, 'Elma');
    final reloaded = FoodLookupCache(storage, clock: () => now);
    expect(reloaded.byBarcode('123')?.name, 'Elma');
  });
}

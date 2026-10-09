import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/errors/failures.dart';
import 'package:diyet_programi/features/food/data/datasources/caching_food_database_service.dart';
import 'package:diyet_programi/features/food/data/datasources/food_lookup_cache.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/barcode/barcode_lookup_service.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/food_database/food_database_service.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _yogurt = Food(
  id: 'off-8690000000016',
  name: 'Yoğurt',
  barcode: '8690000000016',
  nutritionPer100: NutritionFacts(calories: 61, proteinG: 4),
);

class _CountingDb implements FoodDatabaseService, BarcodeLookupService {
  var searches = 0;
  var lookups = 0;
  Food? food;

  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async {
    searches++;
    return food == null ? const [] : [food!];
  }

  @override
  Future<Food?> getById(String id) async => food;

  @override
  Future<Food?> lookup(String barcode) async {
    lookups++;
    return food?.barcode == barcode ? food : null;
  }
}

class _FailingDb implements FoodDatabaseService, BarcodeLookupService {
  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async =>
      throw const NetworkException('no_connection', code: 'no_connection');

  @override
  Future<Food?> getById(String id) async =>
      throw const NetworkException('no_connection', code: 'no_connection');

  @override
  Future<Food?> lookup(String barcode) async =>
      throw const NetworkException('no_connection', code: 'no_connection');
}

void main() {
  test('barkod cache miss uzak bakıma gider, hit gitmez', () async {
    final inner = _CountingDb()..food = _yogurt;
    final cache = FoodLookupCache(InMemoryKeyValueStorage());
    final db = CachingFoodDatabaseService(
      database: inner,
      barcodes: inner,
      cache: cache,
    );
    expect((await db.lookup('8690000000016'))?.name, 'Yoğurt');
    expect((await db.lookup('8690000000016'))?.name, 'Yoğurt');
    expect(inner.lookups, 1);
    expect(cache.byBarcode('8690000000016')?.name, 'Yoğurt');
  });

  test('status=0 başarılı product cache yazılmaz', () async {
    final inner = _CountingDb();
    final cache = FoodLookupCache(InMemoryKeyValueStorage());
    final db = CachingFoodDatabaseService(
      database: inner,
      barcodes: inner,
      cache: cache,
    );
    expect(await db.lookup('0000000000000'), isNull);
    expect(await db.lookup('0000000000000'), isNull);
    expect(inner.lookups, 2);
    expect(cache.byBarcode('0000000000000'), isNull);
  });

  test('başarılı ürün cache yazılır', () async {
    final inner = _CountingDb()..food = _yogurt;
    final cache = FoodLookupCache(InMemoryKeyValueStorage());
    final online = CachingFoodDatabaseService(
      database: inner,
      barcodes: inner,
      cache: cache,
    );
    await online.lookup('8690000000016');
    final offline = CachingFoodDatabaseService(
      database: _FailingDb(),
      barcodes: _FailingDb(),
      cache: cache,
    );
    expect((await offline.lookup('8690000000016'))?.name, 'Yoğurt');
  });

  test('çevrimdışı ve önbelleksiz barkod hata döner', () async {
    final db = InMemoryDocumentDatabase();
    addTearDown(db.dispose);
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: _FailingDb(),
      barcodeLookup: _FailingDb(),
    );
    final result = await repo.findByBarcode('3017620422003');
    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('aynı arama ikinci kez ağa gitmez', () async {
    final inner = _CountingDb()..food = _yogurt;
    final cache = FoodLookupCache(InMemoryKeyValueStorage());
    final db = CachingFoodDatabaseService(
      database: inner,
      barcodes: inner,
      cache: cache,
    );
    expect(await db.search('yoğurt'), hasLength(1));
    expect(await db.search('yoğurt'), hasLength(1));
    expect(await db.search('  Yoğurt  '), hasLength(1));
    expect(inner.searches, 1);
  });

  test('kısa sorgu uzak kataloga gitmez', () async {
    final inner = _CountingDb()..food = _yogurt;
    final db = InMemoryDocumentDatabase();
    addTearDown(db.dispose);
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: inner,
      barcodeLookup: inner,
    );
    await repo.search('a');
    expect(inner.searches, 0);
  });
}

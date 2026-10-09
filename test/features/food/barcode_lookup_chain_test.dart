import 'package:diyet_programi/core/errors/failures.dart';
import 'package:diyet_programi/core/network/api_client.dart';
import 'package:diyet_programi/features/food/data/datasources/open_food_facts_food_service.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/barcode/barcode_lookup_service.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/food_database/food_database_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingLookup implements FoodDatabaseService, BarcodeLookupService {
  String? lastBarcode;
  Food? food;

  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async => const [];

  @override
  Future<Food?> getById(String id) async => food;

  @override
  Future<Food?> lookup(String barcode) async {
    lastBarcode = barcode;
    return food?.barcode == barcode ? food : null;
  }
}

class _StatusClient implements ApiClient {
  _StatusClient(this.payloads);

  final Map<String, Object?> payloads;
  String? lastPath;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) async {
    lastPath = path;
    return decoder(payloads['product']);
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) => throw UnimplementedError();

  @override
  Future<T> put<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decoder,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(String path, {Object? body}) =>
      throw UnimplementedError();
}

void main() {
  late InMemoryDocumentDatabase db;

  setUp(() => db = InMemoryDocumentDatabase());
  tearDown(() => db.dispose());

  test('findByBarcode leading zero string olarak gider', () async {
    final lookup = _RecordingLookup();
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: lookup,
      barcodeLookup: lookup,
    );
    await repo.findByBarcode(' 0123456789012 ');
    expect(lookup.lastBarcode, '0123456789012');
    expect(lookup.lastBarcode, isNot('123456789012'));
  });

  test('findByBarcode EAN-13 zinciri Food döner', () async {
    const nutella = Food(
      id: 'off-3017620422003',
      name: 'Nutella',
      barcode: '3017620422003',
      nutritionPer100: NutritionFacts(calories: 539),
    );
    final lookup = _RecordingLookup()..food = nutella;
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: lookup,
      barcodeLookup: lookup,
    );
    final result = await repo.findByBarcode('3017620422003');
    expect(result.valueOrNull?.barcode, '3017620422003');
    expect(lookup.lastBarcode, '3017620422003');
  });

  test('OFF status=0 repository not found döner', () async {
    final service = OpenFoodFactsFoodService(
      _StatusClient({
        'product': {'status': 0, 'code': '8690000000000'},
      }),
    );
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: service,
      barcodeLookup: service,
    );
    expect((await repo.findByBarcode('8690000000000')).valueOrNull, isNull);
  });

  test('status=1 eksik ürün IncompleteCatalogFoodFailure döner', () async {
    final service = OpenFoodFactsFoodService(
      _StatusClient({
        'product': {
          'status': 1,
          'code': '8691422701433',
          'product': {'code': '8691422701433'},
        },
      }),
    );
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: service,
      barcodeLookup: service,
    );
    final result = await repo.findByBarcode('8691422701433');
    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<IncompleteCatalogFoodFailure>());
  });
}

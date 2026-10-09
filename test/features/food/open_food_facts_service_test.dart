import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/network/api_client.dart';
import 'package:diyet_programi/features/food/data/datasources/food_api_config.dart';
import 'package:diyet_programi/features/food/data/datasources/open_food_facts_food_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MapApiClient implements ApiClient {
  _MapApiClient(this.payloads);

  final Map<String, Object?> payloads;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) async {
    final key = path.contains('/product/') ? 'product' : 'search';
    return decoder(payloads[key]);
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
  Future<void> delete(String path, {Object? body}) => throw UnimplementedError();
}

void main() {
  test('arama ürün listesini Food listesine çevirir', () async {
    final service = OpenFoodFactsFoodService(
      _MapApiClient({
        'search': {
          'products': [
            {
              'code': '111',
              'product_name': 'Yoğurt',
              'nutriments': {'energy-kcal_100g': 61, 'proteins_100g': 4},
            },
            {
              'code': '222',
              'product_name': 'Eksik',
              'nutriments': <String, Object?>{},
            },
          ],
        },
      }),
    );
    final foods = await service.search('yogurt');
    expect(foods, hasLength(1));
    expect(foods.single.id, FoodApiConfig.productId('111'));
    expect(foods.single.nutritionPer100.calories, 61);
  });

  test('ürün bulunamazsa null döner', () async {
    final service = OpenFoodFactsFoodService(
      _MapApiClient({
        'product': {'status': 0},
      }),
    );
    expect(await service.lookup('000'), isNull);
  });

  test('sayfa parametresi arama sorgusuna eklenir', () async {
    final client = _RecordingApiClient();
    final service = OpenFoodFactsFoodService(client);
    await service.search('yogurt', page: 2, pageSize: 24);
    expect(client.lastQuery?['page'], 2);
    expect(client.lastQuery?['page_size'], 24);
    expect(client.lastQuery?['search_terms'], 'yogurt');
  });

  test('OFF v2 path barkodu string olarak korur', () async {
    final client = _RecordingApiClient()
      ..payload = {'status': 0, 'product': <String, Object?>{}};
    final service = OpenFoodFactsFoodService(client);
    await service.lookup('0123456789012');
    expect(client.lastPath, '/api/v2/product/0123456789012.json');
    expect(
      client.lastPath!.split('/').last,
      isNot('123456789012.json'),
    );
    expect(
      FoodApiConfig.productUrl('0123456789012'),
      'https://world.openfoodfacts.org/api/v2/product/0123456789012.json',
    );
  });

  test('status=1 ve product Food döner', () async {
    final service = OpenFoodFactsFoodService(
      _MapApiClient({
        'product': {
          'code': '3017620422003',
          'status': 1,
          'product': {
            'code': '3017620422003',
            'product_name': 'Nutella',
            'product_name_tr': 'Nutella',
            'generic_name': 'Hazelnut spread',
            'brands': 'Ferrero',
            'image_front_small_url': 'https://example.com/n.jpg',
            'nutriments': {'energy-kcal_100g': 539, 'proteins_100g': 6.3},
          },
        },
      }),
    );
    final food = await service.lookup('3017620422003');
    expect(food, isNotNull);
    expect(food!.barcode, '3017620422003');
    expect(food.name, 'Nutella');
    expect(food.source.name, 'barcode');
  });

  test('status yok ama product varsa ürün bulunur', () async {
    final service = OpenFoodFactsFoodService(
      _MapApiClient({
        'product': {
          'code': '3017620422003',
          'product': {
            'code': '3017620422003',
            'product_name': 'Nutella',
            'nutriments': {'energy-kcal_100g': 539},
          },
        },
      }),
    );
    expect((await service.lookup('3017620422003'))?.name, 'Nutella');
  });

  test('status=1 ama isim/kalori yoksa incomplete exception', () async {
    final service = OpenFoodFactsFoodService(
      _MapApiClient({
        'product': {
          'code': '8691422701433',
          'status': 1,
          'status_verbose': 'product found',
          'product': {
            'code': '8691422701433',
            'quantity': '300 g',
          },
        },
      }),
    );
    expect(
      () => service.lookup('8691422701433'),
      throwsA(
        isA<IncompleteCatalogFoodException>().having(
          (e) => e.barcode,
          'barcode',
          '8691422701433',
        ),
      ),
    );
  });
}

class _RecordingApiClient implements ApiClient {
  Map<String, dynamic>? lastQuery;
  String? lastPath;
  Object? payload = {'products': <Object>[]};

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    return decoder(payload);
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
  Future<void> delete(String path, {Object? body}) => throw UnimplementedError();
}

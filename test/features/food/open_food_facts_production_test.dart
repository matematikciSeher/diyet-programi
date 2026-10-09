import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/network/api_client.dart';
import 'package:diyet_programi/features/food/data/datasources/food_api_config.dart';
import 'package:diyet_programi/features/food/data/datasources/open_food_facts_food_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingClient implements ApiClient {
  _ThrowingClient(this.error);

  final Object error;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) async => throw error;

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

class _PayloadClient implements ApiClient {
  _PayloadClient(this.payload);

  final Object? payload;
  Map<String, dynamic>? query;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) async {
    query = queryParameters;
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
  Future<void> delete(String path, {Object? body}) =>
      throw UnimplementedError();
}

void main() {
  test('429 NetworkException olarak yükselir', () async {
    final service = OpenFoodFactsFoodService(
      _ThrowingClient(
        const NetworkException('rate_limited', code: 'rate_limited'),
      ),
    );
    expect(
      () => service.search('yogurt'),
      throwsA(
        isA<NetworkException>().having((e) => e.code, 'code', 'rate_limited'),
      ),
    );
  });

  test('503 NetworkException olarak yükselir', () async {
    final service = OpenFoodFactsFoodService(
      _ThrowingClient(const NetworkException('unavailable', code: '503')),
    );
    expect(
      () => service.lookup('3017620422003'),
      throwsA(isA<NetworkException>().having((e) => e.code, 'code', '503')),
    );
  });

  test('bozuk JSON güvenli NetworkException verir', () async {
    final service = OpenFoodFactsFoodService(_PayloadClient('not-json'));
    expect(
      () => service.lookup('111'),
      throwsA(
        isA<NetworkException>().having(
          (e) => e.code,
          'code',
          'malformed_response',
        ),
      ),
    );
    expect(await service.search('yogurt'), isEmpty);
  });

  test('HTTP 404 ürün bulunamadı döner', () async {
    final service = OpenFoodFactsFoodService(
      _ThrowingClient(const NotFoundException('not_found', code: '404')),
    );
    expect(await service.lookup('3017620422003'), isNull);
  });

  test('HTTP 429 lookup rate limit hatası verir', () async {
    final service = OpenFoodFactsFoodService(
      _ThrowingClient(
        const NetworkException('rate_limited', code: 'rate_limited'),
      ),
    );
    expect(
      () => service.lookup('3017620422003'),
      throwsA(
        isA<NetworkException>().having((e) => e.code, 'code', 'rate_limited'),
      ),
    );
  });

  test('status=0 ürün yok sayılır', () async {
    final service = OpenFoodFactsFoodService(
      _PayloadClient({'status': 0, 'product': <String, Object?>{}}),
    );
    expect(await service.lookup('000'), isNull);
  });

  test('Türkçe locale lc=tr olarak gönderilir', () async {
    final client = _PayloadClient({'products': <Object>[]});
    final service = OpenFoodFactsFoodService(client);
    await service.search('yoğurt', locale: 'tr');
    expect(client.query?['lc'], 'tr');
    expect(client.query?['search_terms'], 'yoğurt');
  });

  test('minimum karakter altındaki arama uzak isteğe gitmez', () async {
    final client = _PayloadClient({'products': <Object>[]});
    final service = OpenFoodFactsFoodService(client);
    final foods = await service.search('a');
    expect(foods, isEmpty);
    expect(client.query, isNull);
    expect(FoodApiConfig.isRemoteSearchQuery('a'), isFalse);
  });
}

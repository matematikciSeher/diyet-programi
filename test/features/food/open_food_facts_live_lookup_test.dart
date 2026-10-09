import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/network/dio_api_client.dart';
import 'package:diyet_programi/features/food/data/datasources/food_api_config.dart';
import 'package:diyet_programi/features/food/data/datasources/open_food_facts_food_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gerçek Open Food Facts HTTP bakımı. Ağ yoksa test atlanır; yeşil sayılmaz.
void main() {
  test('canlı OFF 3017620422003 ürünü bulunur', () async {
    final service = OpenFoodFactsFoodService(
      DioApiClient.create(
        baseUrl: FoodApiConfig.openFoodFactsBaseUrl,
        headers: {
          'User-Agent': FoodApiConfig.userAgentFor(
            contactEmail: 'dev@localhost',
          ),
        },
      ),
    );
    try {
      final food = await service.lookup('3017620422003');
      expect(food, isNotNull, reason: 'HTTP 200 + OFF status 1 beklenir');
      expect(food!.barcode, '3017620422003');
      expect(food.name.toLowerCase(), contains('nutella'));
    } on NetworkException catch (error) {
      final code = error.code ?? '';
      if (code == 'timeout' ||
          code == 'no_connection' ||
          code == 'unavailable' ||
          code == '500' ||
          code == '502' ||
          code == '503') {
        markTestSkipped('canlı test yapılamadı: $code');
        return;
      }
      rethrow;
    }
  });

  test('canlı OFF 8691422701433 kayıtlıdır (eksik veri uydurulmaz)', () async {
    final service = OpenFoodFactsFoodService(
      DioApiClient.create(
        baseUrl: FoodApiConfig.openFoodFactsBaseUrl,
        headers: {
          'User-Agent': FoodApiConfig.userAgentFor(
            contactEmail: 'dev@localhost',
          ),
        },
      ),
    );
    try {
      final food = await service.lookup('8691422701433');
      if (food != null) {
        expect(food.barcode, '8691422701433');
        return;
      }
      fail('status=1 ürün null dönmemeli');
    } on IncompleteCatalogFoodException catch (error) {
      expect(error.barcode, '8691422701433');
    } on NetworkException catch (error) {
      final code = error.code ?? '';
      if (code == 'timeout' ||
          code == 'no_connection' ||
          code == 'unavailable' ||
          code == '500' ||
          code == '502' ||
          code == '503') {
        markTestSkipped('canlı test yapılamadı: $code');
        return;
      }
      rethrow;
    }
  });
}

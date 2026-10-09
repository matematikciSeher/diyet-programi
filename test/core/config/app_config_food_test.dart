import 'package:diyet_programi/core/config/app_config.dart';
import 'package:diyet_programi/core/config/app_environment.dart';
import 'package:diyet_programi/features/food/data/datasources/food_api_config.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig _config({required String foodApiBaseUrl}) => AppConfig(
  environment: AppEnvironment.dev,
  appName: 'Test',
  apiBaseUrl: '',
  aiProxyBaseUrl: '',
  foodApiBaseUrl: foodApiBaseUrl,
  revenueCatApiKeyIos: '',
  revenueCatApiKeyAndroid: '',
  enableAnalytics: false,
  enableCrashReporting: false,
  useFakeServices: true,
);

void main() {
  test('boş veya örnek FOOD_API_BASE_URL Open Food Facts kullanır', () {
    expect(
      _config(foodApiBaseUrl: '').foodDatabaseBaseUrl,
      'https://world.openfoodfacts.org',
    );
    expect(
      _config(foodApiBaseUrl: 'https://food.example.com').foodDatabaseBaseUrl,
      'https://world.openfoodfacts.org',
    );
  });

  test('özel proxy adresi olduğu gibi kullanılır', () {
    expect(
      _config(foodApiBaseUrl: 'https://food-proxy.internal/').foodDatabaseBaseUrl,
      'https://food-proxy.internal',
    );
  });

  test('release derlemede USE_FAKE_SERVICES=true yok sayılır', () {
    expect(
      AppConfig.resolveUseFakeServices(
        requestedFakeServices: true,
        isRelease: false,
      ),
      isTrue,
    );
    expect(
      AppConfig.resolveUseFakeServices(
        requestedFakeServices: true,
        isRelease: true,
      ),
      isFalse,
    );
    expect(
      AppConfig.resolveUseFakeServices(
        requestedFakeServices: false,
        isRelease: true,
      ),
      isFalse,
    );
  });

  test('production AppConfig iletişim e-postasını User-Agent biçimine bağlar', () {
    const config = AppConfig(
      environment: AppEnvironment.prod,
      appName: 'Diyet Programı',
      apiBaseUrl: '',
      aiProxyBaseUrl: '',
      foodApiBaseUrl: '',
      foodApiContactEmail: 'contact@example.org',
      revenueCatApiKeyIos: '',
      revenueCatApiKeyAndroid: '',
      enableAnalytics: true,
      enableCrashReporting: true,
      useFakeServices: false,
    );
    expect(config.useFakeServices, isFalse);
    expect(config.foodDatabaseBaseUrl, 'https://world.openfoodfacts.org');
    expect(
      FoodApiConfig.userAgentFor(contactEmail: config.foodApiContactEmail),
      'DiyetProgrami/1.0.0 (contact@example.org)',
    );
  });
}

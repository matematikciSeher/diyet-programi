import 'package:diyet_programi/features/food/data/datasources/food_api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('e-posta yoksa mevcut User-Agent korunur', () {
    expect(FoodApiConfig.userAgentFor(), FoodApiConfig.userAgent);
    expect(FoodApiConfig.userAgentFor(contactEmail: ''), FoodApiConfig.userAgent);
    expect(FoodApiConfig.userAgentFor(contactEmail: '  '), FoodApiConfig.userAgent);
  });

  test('e-posta varsa AppName/Version (email) biçimini kullanır', () {
    expect(
      FoodApiConfig.userAgentFor(contactEmail: 'reuse@example.org'),
      'DiyetProgrami/${FoodApiConfig.appVersion} (reuse@example.org)',
    );
  });

  test('atıf URL resmi Open Food Facts adresidir', () {
    expect(FoodApiConfig.attributionUrl, 'https://openfoodfacts.org');
    expect(
      FoodApiConfig.termsOfUseUrl,
      'https://world.openfoodfacts.org/terms-of-use',
    );
    expect(Uri.parse(FoodApiConfig.attributionUrl).isAbsolute, isTrue);
  });

  test('kısa sorgu uzak aramaya gitmez', () {
    expect(FoodApiConfig.isRemoteSearchQuery(''), isFalse);
    expect(FoodApiConfig.isRemoteSearchQuery('a'), isFalse);
    expect(FoodApiConfig.isRemoteSearchQuery('su'), isTrue);
    expect(FoodApiConfig.normalizeQuery('  Yoğurt  '), 'yoğurt');
  });

  test('OFF product URL barkodu path string olarak korur', () {
    expect(
      FoodApiConfig.productPath('3017620422003'),
      '/api/v2/product/3017620422003.json',
    );
    expect(
      FoodApiConfig.productUrl('0123456789012'),
      'https://world.openfoodfacts.org/api/v2/product/0123456789012.json',
    );
  });

  test('fake kapalı ve e-posta boşken production uyarısı yolu çalışır', () {
    FoodApiConfig.logContactEmailStatus('', useFakeServices: false);
    FoodApiConfig.logContactEmailStatus('  ', useFakeServices: true);
  });
}

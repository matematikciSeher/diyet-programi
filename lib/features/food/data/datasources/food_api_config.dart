import '../../../../core/utils/app_logger.dart';

/// Açık yiyecek veritabanı (Open Food Facts) istemci ayarları.
///
/// API anahtarı yoktur; kimlik [userAgent] / [userAgentFor] ile bildirilir.
/// Ticari kullanım ODbL atıfı ile serbesttir; veri OFF'a yazılmaz.
abstract final class FoodApiConfig {
  static const openFoodFactsBaseUrl = 'https://world.openfoodfacts.org';

  /// Resmi atıf hedefi (ODbL reuse şartı).
  static const attributionUrl = 'https://openfoodfacts.org';

  /// Resmi kullanım koşulları.
  static const termsOfUseUrl = 'https://world.openfoodfacts.org/terms-of-use';

  /// ODbL lisans özeti.
  static const odblLicenseUrl =
      'https://opendatacommons.org/licenses/odbl/1.0/';

  static const appVersion = '1.0.0';

  /// E-posta yokken kullanılan kimlik. Production'da iletişim e-postası
  /// [userAgentFor] ile eklenmelidir.
  static const userAgent = 'DiyetProgrami/1.0 (Flutter; nutrition-app)';

  static const dataReference = 'Open Food Facts';
  static const searchPageSize = 24;
  static const searchCacheTtl = Duration(minutes: 15);
  static const productCacheTtl = Duration(days: 7);
  static const maxCachedProducts = 200;
  static const idPrefix = 'off-';

  /// OFF search 10 req/min/IP. Kısa sorguları ve tuş başına isteği keser.
  static const minSearchQueryLength = 2;
  static const searchDebounce = Duration(milliseconds: 400);

  static String productId(String barcode) => '$idPrefix$barcode';

  /// `/api/v2/product/{barcode}.json` — barkod string olarak path'e yazılır.
  static String productPath(String barcode) =>
      '/api/v2/product/${Uri.encodeComponent(barcode)}.json';

  static String productUrl(
    String barcode, {
    String baseUrl = openFoodFactsBaseUrl,
  }) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$base${productPath(barcode)}';
  }

  static String? barcodeFromId(String id) {
    if (!id.startsWith(idPrefix)) return null;
    final code = id.substring(idPrefix.length).trim();
    return code.isEmpty ? null : code;
  }

  static bool isPlaceholderBaseUrl(String url) {
    final trimmed = url.trim();
    return trimmed.isEmpty || trimmed.contains('example.com');
  }

  static String normalizeQuery(String query) =>
      query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static bool isRemoteSearchQuery(String query) =>
      normalizeQuery(query).length >= minSearchQueryLength;

  /// OFF'un önerdiği `AppName/Version (ContactEmail)` biçimi.
  /// E-posta yoksa mevcut [userAgent] korunur.
  static String userAgentFor({String? contactEmail}) {
    final email = contactEmail?.trim() ?? '';
    if (email.isEmpty) return userAgent;
    return 'DiyetProgrami/$appVersion ($email)';
  }

  static void logContactEmailStatus(
    String? contactEmail, {
    required bool useFakeServices,
  }) {
    if (useFakeServices) return;
    final email = contactEmail?.trim() ?? '';
    if (email.isEmpty) {
      AppLogger.warning(
        'FOOD_API_CONTACT_EMAIL tanımlı değil; Open Food Facts '
        'User-Agent iletişim bilgisi içermiyor. Production için env '
        'üzerinden bir iletişim e-postası ekleyin.',
      );
    }
  }
}

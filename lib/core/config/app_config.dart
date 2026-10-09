import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';
import 'app_environment.dart';

/// Derleme zamanında `--dart-define-from-file=env/<env>.env` ile verilen
/// değerlerden oluşturulan uygulama yapılandırması.
///
/// Gizli anahtarlar burada tutulmaz; yalnızca istemcide bulunması güvenli olan
/// uç noktalar, public SDK anahtarları ve özellik bayrakları okunur.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.aiProxyBaseUrl,
    required this.foodApiBaseUrl,
    this.foodApiContactEmail = '',
    required this.revenueCatApiKeyIos,
    required this.revenueCatApiKeyAndroid,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.useFakeServices,
    this.aiModel = '',
    this.aiTimeoutSeconds = 20,
    this.aiMaxOutputTokens = 512,
    this.aiMaxInputChars = 6000,
    this.aiMaxMessageChars = 2000,
    this.aiMaxRequestsPerMinute = 8,
    this.aiMaxRetries = 0,
    this.foodVisionMaxImageBytes = 1500000,
    this.foodVisionMaxImageDimension = 1280,
    this.foodVisionJpegQuality = 80,
    this.voiceMaxDurationSeconds = 30,
    this.privacyPolicyUrl = '',
    this.privacyContactEmail = '',
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      environment: AppEnvironment.fromName(
        const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
      ),
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Diyet Programı',
      ),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      aiProxyBaseUrl: const String.fromEnvironment('AI_PROXY_BASE_URL'),
      foodApiBaseUrl: const String.fromEnvironment('FOOD_API_BASE_URL'),
      foodApiContactEmail: const String.fromEnvironment(
        'FOOD_API_CONTACT_EMAIL',
      ),
      revenueCatApiKeyIos: const String.fromEnvironment(
        'REVENUECAT_API_KEY_IOS',
      ),
      revenueCatApiKeyAndroid: const String.fromEnvironment(
        'REVENUECAT_API_KEY_ANDROID',
      ),
      enableAnalytics: const bool.fromEnvironment('ENABLE_ANALYTICS'),
      enableCrashReporting: const bool.fromEnvironment(
        'ENABLE_CRASH_REPORTING',
      ),
      useFakeServices: resolveUseFakeServices(
        requestedFakeServices: const bool.fromEnvironment(
          'USE_FAKE_SERVICES',
          defaultValue: true,
        ),
      ),
      aiModel: const String.fromEnvironment('AI_MODEL'),
      aiTimeoutSeconds: const int.fromEnvironment(
        'AI_TIMEOUT_SECONDS',
        defaultValue: 20,
      ),
      aiMaxOutputTokens: const int.fromEnvironment(
        'AI_MAX_OUTPUT_TOKENS',
        defaultValue: 512,
      ),
      aiMaxInputChars: const int.fromEnvironment(
        'AI_MAX_INPUT_CHARS',
        defaultValue: 6000,
      ),
      aiMaxMessageChars: const int.fromEnvironment(
        'AI_MAX_MESSAGE_CHARS',
        defaultValue: 2000,
      ),
      aiMaxRequestsPerMinute: const int.fromEnvironment(
        'AI_MAX_REQUESTS_PER_MINUTE',
        defaultValue: 8,
      ),
      aiMaxRetries: const int.fromEnvironment('AI_MAX_RETRIES', defaultValue: 0),
      foodVisionMaxImageBytes: const int.fromEnvironment(
        'FOOD_VISION_MAX_IMAGE_BYTES',
        defaultValue: 1500000,
      ),
      foodVisionMaxImageDimension: const int.fromEnvironment(
        'FOOD_VISION_MAX_IMAGE_DIMENSION',
        defaultValue: 1280,
      ),
      foodVisionJpegQuality: const int.fromEnvironment(
        'FOOD_VISION_JPEG_QUALITY',
        defaultValue: 80,
      ),
      voiceMaxDurationSeconds: const int.fromEnvironment(
        'VOICE_MAX_DURATION_SECONDS',
        defaultValue: 30,
      ),
      privacyPolicyUrl: const String.fromEnvironment('PRIVACY_POLICY_URL'),
      privacyContactEmail: const String.fromEnvironment(
        'PRIVACY_CONTACT_EMAIL',
      ),
    );
  }

  /// Debug/test: dart-define değeri. Release: her zaman `false`.
  ///
  /// `flutter test` debug derlemedir; mevcut fake katalog testleri bozulmaz.
  static bool resolveUseFakeServices({
    required bool requestedFakeServices,
    bool isRelease = kReleaseMode,
  }) {
    if (isRelease && requestedFakeServices) {
      AppLogger.warning(
        'Release build: USE_FAKE_SERVICES=true yok sayıldı; '
        'örnek katalog ve fake servisler kullanılmayacak.',
      );
    }
    return isRelease ? false : requestedFakeServices;
  }

  final AppEnvironment environment;
  final String appName;
  final String apiBaseUrl;
  final String aiProxyBaseUrl;
  final String foodApiBaseUrl;

  /// Open Food Facts User-Agent iletişim e-postası. Boşsa mevcut UA korunur.
  final String foodApiContactEmail;
  final String revenueCatApiKeyIos;
  final String revenueCatApiKeyAndroid;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool useFakeServices;

  /// İstemcide güvenli olan model adı. Sağlayıcı anahtarı değildir.
  final String aiModel;
  final int aiTimeoutSeconds;
  final int aiMaxOutputTokens;
  final int aiMaxInputChars;
  final int aiMaxMessageChars;
  final int aiMaxRequestsPerMinute;
  final int aiMaxRetries;

  /// Fotoğraf AI'ye gitmeden önce uygulanan üst sınırlar. Sağlayıcı anahtarı değildir.
  final int foodVisionMaxImageBytes;
  final int foodVisionMaxImageDimension;
  final int foodVisionJpegQuality;
  final int voiceMaxDurationSeconds;

  /// Mağaza / uygulama içi Gizlilik Politikası sayfası. Boş veya geçersizse
  /// bağlantı açılmaz.
  final String privacyPolicyUrl;

  /// Gizlilik politikası iletişim e-postası. Boş veya örnekse yayınlanmaz;
  /// sahte adres üretilmez.
  final String privacyContactEmail;

  int get effectiveFoodVisionMaxImageBytes =>
      _clamp(foodVisionMaxImageBytes, 200000, 4000000, 1500000);

  int get effectiveFoodVisionMaxImageDimension =>
      _clamp(foodVisionMaxImageDimension, 640, 2048, 1280);

  int get effectiveFoodVisionJpegQuality =>
      _clamp(foodVisionJpegQuality, 50, 90, 80);

  int get effectiveVoiceMaxDurationSeconds =>
      _clamp(voiceMaxDurationSeconds, 5, 120, 30);

  static int _clamp(int value, int min, int max, int fallback) {
    if (value < min || value > max) return fallback;
    return value;
  }

  bool get isProduction => environment.isProduction;

  /// Boş veya örnek adres üretim proxy'si sayılmaz.
  bool get isAiProxyConfigured {
    final url = aiProxyBaseUrl.trim();
    if (url.isEmpty || url.contains('example.com')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    return uri.isScheme('https') || uri.isScheme('http');
  }

  /// Gizlilik Politikası URL'si http(s) ve geçerli host ile tanımlı mı.
  bool get isPrivacyPolicyUrlConfigured {
    final url = privacyPolicyUrl.trim();
    if (url.isEmpty || url.contains('example.com')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    return uri.isScheme('https') || uri.isScheme('http');
  }

  /// Yapılandırılmışsa açılabilir URI; aksi halde `null`.
  Uri? get privacyPolicyUri {
    if (!isPrivacyPolicyUrlConfigured) return null;
    return Uri.tryParse(privacyPolicyUrl.trim());
  }

  /// Gerçek bir iletişim e-postası var mı. Örnek veya boş değer yayınlanmaz.
  bool get isPrivacyContactEmailConfigured {
    final email = privacyContactEmail.trim();
    if (email.isEmpty || email.contains('example.com')) return false;
    final at = email.indexOf('@');
    return at > 0 && at < email.length - 1;
  }

  /// Open Food Facts varsayılanı; `FOOD_API_BASE_URL` örnek/boşsa kullanılır.
  /// Özel bir backend proxy varsa env'deki adres alınır (auth token gönderilmez).
  String get foodDatabaseBaseUrl {
    final url = foodApiBaseUrl.trim();
    if (url.isEmpty || url.contains('example.com')) {
      return 'https://world.openfoodfacts.org';
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}

/// `bootstrap` içinde gerçek değerle override edilir.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

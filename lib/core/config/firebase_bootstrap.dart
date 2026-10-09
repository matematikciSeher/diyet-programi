import 'package:firebase_core/firebase_core.dart';

import '../utils/app_logger.dart';
import 'app_config.dart';
import 'firebase_options_loader.dart';

/// Firebase başlatma sonucu. Başarısızlık uygulamayı durdurmaz.
class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.isAvailable,
    this.error,
  });

  const FirebaseBootstrapResult.unavailable([this.error])
    : isAvailable = false;

  const FirebaseBootstrapResult.available() : isAvailable = true, error = null;

  final bool isAvailable;
  final Object? error;
}

/// Firebase'i güvenli biçimde başlatır. Yapılandırma yoksa, native
/// `google-services.json` / `GoogleService-Info.plist` yoksa veya ağ
/// hatası olursa [FirebaseBootstrapResult.isAvailable] false kalır.
abstract final class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize(AppConfig config) async {
    if (Firebase.apps.isNotEmpty) {
      return const FirebaseBootstrapResult.available();
    }

    try {
      final options = FirebaseOptionsLoader.currentPlatform();
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        // Native yapılandırma dosyası varsa (flutterfire configure) onu kullan.
        await Firebase.initializeApp();
      }
      AppLogger.info('Firebase başlatıldı [${config.environment.name}]');
      return const FirebaseBootstrapResult.available();
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Firebase kullanılamıyor; uygulama çevrimdışı devam edecek',
        error: error,
      );
      AppLogger.debug('$stackTrace');
      return FirebaseBootstrapResult.unavailable(error);
    }
  }
}

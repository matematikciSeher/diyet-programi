import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Gizlilik Politikası sayfasını [AppConfig.privacyPolicyUri] ile açar.
///
/// Adres boş, örnek veya geçersizse tarayıcı çağrılmaz.
abstract final class PrivacyPolicyLink {
  @visibleForTesting
  static Future<bool> Function(Uri uri)? debugLaunch;

  static Future<bool> open(AppConfig config) async {
    final uri = config.privacyPolicyUri;
    if (uri == null) return false;
    final launch = debugLaunch ?? _launch;
    try {
      return await launch(uri);
    } on Object {
      return false;
    }
  }

  static Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Merkezi loglama. Release modunda debug/info logları yazılmaz;
/// hatalar ileride Crashlytics'e bu noktadan yönlendirilir.
abstract final class AppLogger {
  static void debug(String message) {
    if (kDebugMode) developer.log(message, name: 'DEBUG');
  }

  static void info(String message) {
    if (kDebugMode) developer.log(message, name: 'INFO');
  }

  static void warning(String message, {Object? error}) {
    developer.log(message, name: 'WARN', error: error);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}

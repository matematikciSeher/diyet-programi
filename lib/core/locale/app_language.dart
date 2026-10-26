import 'package:flutter/widgets.dart';

/// Kullanıcının dil tercihi. [system] telefona bakar: Türkçe ise uygulama
/// Türkçe, bunun dışındaki her dilde İngilizce açılır.
enum AppLanguageChoice {
  system,
  turkish,
  english;

  static AppLanguageChoice fromStorage(String? code) => switch (code) {
    'tr' => AppLanguageChoice.turkish,
    'en' => AppLanguageChoice.english,
    _ => AppLanguageChoice.system,
  };

  /// Saklanan değer. [system] için `null` (anahtar silinir).
  String? get storageCode => switch (this) {
    AppLanguageChoice.system => null,
    AppLanguageChoice.turkish => 'tr',
    AppLanguageChoice.english => 'en',
  };
}

/// Tercih ve telefon dilinden uygulamanın kullanacağı yerel ayarı üretir.
Locale resolveAppLocale(AppLanguageChoice choice, Locale device) {
  return switch (choice) {
    AppLanguageChoice.turkish => const Locale('tr'),
    AppLanguageChoice.english => const Locale('en'),
    AppLanguageChoice.system =>
      device.languageCode.toLowerCase() == 'tr'
          ? const Locale('tr')
          : const Locale('en'),
  };
}

/// Konuşma tanıma yerel ayarı. Türkçe dışında İngilizce (ABD) kullanılır.
String speechLocaleIdFor(Locale locale) =>
    locale.languageCode == 'tr' ? 'tr_TR' : 'en_US';

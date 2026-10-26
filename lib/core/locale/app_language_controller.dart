import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/services/local_storage/key_value_storage.dart';
import '../../shared/services/service_providers.dart';
import '../constants/storage_keys.dart';
import 'app_language.dart';

/// Telefon dili değişince yenilenir. Testlerde varsayılan `en_US`'tir.
class PlatformLocaleController extends Notifier<Locale>
    with WidgetsBindingObserver {
  @override
  Locale build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    return PlatformDispatcher.instance.locale;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final next = locales != null && locales.isNotEmpty
        ? locales.first
        : PlatformDispatcher.instance.locale;
    if (next == state) return;
    state = next;
  }
}

final platformLocaleProvider =
    NotifierProvider<PlatformLocaleController, Locale>(
      PlatformLocaleController.new,
    );

/// Saklanan dil tercihi. Kayıt yoksa telefon dili izlenir.
class AppLanguageController extends Notifier<AppLanguageChoice> {
  KeyValueStorage get _storage => ref.read(keyValueStorageProvider);

  @override
  AppLanguageChoice build() {
    final stored = ref
        .watch(keyValueStorageProvider)
        .getString(StorageKeys.localeCode);
    return AppLanguageChoice.fromStorage(stored);
  }

  Future<void> setChoice(AppLanguageChoice choice) async {
    state = choice;
    final code = choice.storageCode;
    if (code == null) {
      await _storage.remove(StorageKeys.localeCode);
    } else {
      await _storage.setString(StorageKeys.localeCode, code);
    }
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageController, AppLanguageChoice>(
      AppLanguageController.new,
    );

/// Arayüzün kullandığı somut dil: `tr` ya da `en`.
final appLocaleProvider = Provider<Locale>((ref) {
  final choice = ref.watch(appLanguageProvider);
  final device = ref.watch(platformLocaleProvider);
  return resolveAppLocale(choice, device);
});

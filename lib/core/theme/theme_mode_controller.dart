import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/services/local_storage/key_value_storage.dart';
import '../../shared/services/service_providers.dart';
import '../constants/storage_keys.dart';

/// Kullanıcının tema tercihini (sistem / açık / koyu) tutar ve saklar.
class ThemeModeController extends Notifier<ThemeMode> {
  KeyValueStorage get _storage => ref.read(keyValueStorageProvider);

  @override
  ThemeMode build() {
    final stored = ref
        .watch(keyValueStorageProvider)
        .getString(StorageKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.setString(StorageKeys.themeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

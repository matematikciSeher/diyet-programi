import 'package:diyet_programi/core/locale/app_language.dart';
import 'package:diyet_programi/l10n/catalog_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('telefon Türkçe ise uygulama Türkçe olur', () {
    expect(
      resolveAppLocale(AppLanguageChoice.system, const Locale('tr', 'TR')),
      const Locale('tr'),
    );
  });

  test('Türkçe dışındaki telefon dilleri İngilizce olur', () {
    for (final code in ['en', 'de', 'fr', 'ar', 'ru']) {
      expect(
        resolveAppLocale(AppLanguageChoice.system, Locale(code)),
        const Locale('en'),
        reason: code,
      );
    }
  });

  test('kullanıcı seçimi telefon dilinin önüne geçer', () {
    expect(
      resolveAppLocale(AppLanguageChoice.english, const Locale('tr')),
      const Locale('en'),
    );
    expect(
      resolveAppLocale(AppLanguageChoice.turkish, const Locale('de')),
      const Locale('tr'),
    );
  });

  test('katalog metni ve miktar birimi dile göre değişir', () {
    expect(
      CatalogText.localize('Muz ve badem kasesi', 'en'),
      'Banana and almond bowl',
    );
    expect(CatalogText.localize('Menemen', 'en'), 'Tomato and egg skillet');
    expect(CatalogText.localize('Beyaz peynirli omlet', 'en'), 'White cheese omelette');
    expect(CatalogText.localize('Domates', 'en'), 'Tomato');
    expect(CatalogText.localize('Haşlanmış yumurta', 'en'), 'Boiled egg');
    expect(CatalogText.localize('Boiled egg', 'tr'), 'Haşlanmış yumurta');
    expect(CatalogText.localize('1 dilim', 'en'), '1 slice');
    expect(CatalogText.localize('2 dilim', 'en'), '2 slices');
    expect(CatalogText.localize('2 slices', 'tr'), '2 dilim');
    expect(CatalogText.localize('Kendi notum', 'en'), 'Kendi notum');
  });
}

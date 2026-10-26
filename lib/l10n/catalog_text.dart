import 'catalog_phrases.dart';

/// Katalog metinlerini (yiyecek, tarif, plan, birim) seçili dile çevirir.
///
/// Eşleşme tam metindir. Bilinmeyen kullanıcı metni olduğu gibi kalır.
/// Kısa miktar ifadeleri (`1 dilim`, `2 adet`) birim sözlüğüyle çevrilir.
abstract final class CatalogText {
  static final Map<String, String> _enToTr = {
    for (final entry in catalogPhrasesTrToEn.entries) entry.value: entry.key,
  };

  static const _quantityUnits = <String, ({String one, String many})>{
    'yemek kaşığı': (one: 'tablespoon', many: 'tablespoons'),
    'tatlı kaşığı': (one: 'teaspoon', many: 'teaspoons'),
    'çay kaşığı': (one: 'teaspoon', many: 'teaspoons'),
    'su bardağı': (one: 'glass', many: 'glasses'),
    'adet': (one: 'piece', many: 'pieces'),
    'dilim': (one: 'slice', many: 'slices'),
    'kase': (one: 'bowl', many: 'bowls'),
    'bardak': (one: 'glass', many: 'glasses'),
    'porsiyon': (one: 'serving', many: 'servings'),
    'tabak': (one: 'plate', many: 'plates'),
    'kutu': (one: 'can', many: 'cans'),
  };

  static final _quantityTr = RegExp(
    '(\\d+(?:[.,]\\d+)?)\\s+(${_quantityUnits.keys.join('|')})(?=\\s|\$|\\))',
  );

  static const _quantityEnToTr = <String, String>{
    'tablespoons': 'yemek kaşığı',
    'tablespoon': 'yemek kaşığı',
    'teaspoons': 'çay kaşığı',
    'teaspoon': 'çay kaşığı',
    'glasses': 'bardak',
    'glass': 'bardak',
    'pieces': 'adet',
    'piece': 'adet',
    'slices': 'dilim',
    'slice': 'dilim',
    'bowls': 'kase',
    'bowl': 'kase',
    'servings': 'porsiyon',
    'serving': 'porsiyon',
    'plates': 'tabak',
    'plate': 'tabak',
    'cans': 'kutu',
    'can': 'kutu',
    'tbsp': 'yemek kaşığı',
    'tsp': 'çay kaşığı',
  };

  static final _quantityEn = RegExp(
    '(\\d+(?:[.,]\\d+)?)\\s+(${_quantityEnToTr.keys.join('|')})(?=\\s|\$|\\))',
  );

  static String localize(String text, String languageCode) {
    if (text.isEmpty) return text;
    final english = languageCode != 'tr';
    final exact = english ? catalogPhrasesTrToEn[text] : _enToTr[text];
    if (exact != null && exact != text) return exact;
    final bare = english ? _bareToEn(text) : _bareToTr(text);
    if (bare != null) return bare;
    if (text.length > 80 && !_hasDigit(text)) return text;
    return english ? _quantitiesToEn(text) : _quantitiesToTr(text);
  }

  static bool _hasDigit(String text) => RegExp(r'\d').hasMatch(text);

  static String? _bareToEn(String text) {
    final unit = _quantityUnits[text];
    if (unit == null) return null;
    return unit.one;
  }

  static String? _bareToTr(String text) => _quantityEnToTr[text];

  static String _quantitiesToEn(String text) {
    return text.replaceAllMapped(_quantityTr, (match) {
      final raw = match.group(1)!;
      final unit = _quantityUnits[match.group(2)!]!;
      final n = double.tryParse(raw.replaceAll(',', '.')) ?? 0;
      final label = n == 1 ? unit.one : unit.many;
      return '$raw $label';
    });
  }

  static String _quantitiesToTr(String text) {
    return text.replaceAllMapped(_quantityEn, (match) {
      final raw = match.group(1)!;
      final unit = _quantityEnToTr[match.group(2)!]!;
      return '$raw $unit';
    });
  }
}

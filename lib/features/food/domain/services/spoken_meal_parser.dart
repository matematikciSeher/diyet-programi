import '../../../../shared/models/food.dart';

/// Konuşma metninden çıkarılan yiyecek. Besin değeri içermez.
class SpokenFoodMention {
  const SpokenFoodMention({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.quantityAmbiguous,
    this.spokenUnitKey,
  });

  final String name;
  final double? quantity;
  final PortionUnit? unit;
  final bool quantityAmbiguous;

  /// `tea`, `spoon`, `plate`. Mevcut birim etiketi yetmiyorsa dolu.
  final String? spokenUnitKey;

  @override
  String toString() =>
      'SpokenFoodMention($name, $quantity $unit ambiguous=$quantityAmbiguous)';
}

/// Türkçe serbest metni yiyecek adaylarına ayırır. Ağ çağrısı yapmaz.
class SpokenMealParser {
  const SpokenMealParser();

  static const samplePhrase =
      'İki yumurta, elli gram peynir ve iki dilim ekmek yedim.';

  List<SpokenFoodMention> parse(String text) {
    final original = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (original.isEmpty) return const [];
    final folded = _fold(original);
    if (folded.length != original.length) {
      return _parseAligned(folded, folded);
    }
    return _parseAligned(folded, original);
  }

  List<SpokenFoodMention> _parseAligned(String folded, String original) {
    final next = _stripEdges(folded, original);
    final clauses = _split(next.$1, next.$2);
    final items = <SpokenFoodMention>[];
    for (final clause in clauses) {
      final mention = _parseClause(clause.$1, clause.$2);
      if (mention != null) items.add(mention);
    }
    return items;
  }

  (String, String) _stripEdges(String folded, String original) {
    var f = folded.replaceAll(RegExp(r'[.!?]+$'), '');
    var o = original.replaceAll(RegExp(r'[.!?]+$'), '');
    const leading = [
      'aksam',
      'aksamleyin',
      'sabah',
      'ogle',
      'oglen',
      'kahvaltida',
      'kahvalti',
      'ogunde',
      'gece',
    ];
    for (final word in leading) {
      if (f.startsWith('$word ')) {
        final cut = word.length + 1;
        f = f.substring(cut);
        o = o.substring(cut);
        break;
      }
    }
    const trailing = [' yedim', ' yedik', ' ictim', ' ictik', ' aldim', ' aldik'];
    for (final suffix in trailing) {
      if (f.endsWith(suffix)) {
        f = f.substring(0, f.length - suffix.length);
        o = o.substring(0, o.length - suffix.length);
        break;
      }
    }
    return (f.trim(), o.trim());
  }

  List<(String, String)> _split(String folded, String original) {
    final pattern = RegExp(r',|\s+ve\s+|\s+ile\s+|\s+arti\s+');
    final parts = <(String, String)>[];
    var start = 0;
    for (final match in pattern.allMatches(folded)) {
      final f = folded.substring(start, match.start).trim();
      final o = original.substring(start, match.start).trim();
      if (f.isNotEmpty) parts.add((f, o));
      start = match.end;
    }
    final tailF = folded.substring(start).trim();
    final tailO = original.substring(start).trim();
    if (tailF.isNotEmpty) parts.add((tailF, tailO));
    return parts;
  }

  SpokenFoodMention? _parseClause(String folded, String original) {
    final ambiguous = _ambiguousPrefix(folded);
    if (ambiguous != null) {
      final name = original.substring(ambiguous.length).trim();
      if (name.isEmpty) return null;
      return SpokenFoodMention(
        name: name,
        quantity: null,
        unit: null,
        quantityAmbiguous: true,
      );
    }
    final amount = _takeAmount(folded);
    if (amount.quantity == null) {
      final name = original.trim();
      if (name.isEmpty) return null;
      return SpokenFoodMention(
        name: name,
        quantity: null,
        unit: null,
        quantityAmbiguous: true,
      );
    }
    final unit = _takeUnit(amount.rest);
    final nameFolded = (unit == null ? amount.rest : unit.rest).trim();
    if (nameFolded.isEmpty) return null;
    final name = _originalTail(original, folded, nameFolded);
    var quantity = amount.quantity!;
    var portion = unit?.unit ?? PortionUnit.piece;
    if (unit?.scaleToGrams != null) {
      quantity = quantity * unit!.scaleToGrams!;
      portion = PortionUnit.gram;
    }
    return SpokenFoodMention(
      name: name,
      quantity: quantity,
      unit: portion,
      quantityAmbiguous: false,
      spokenUnitKey: unit?.labelKey,
    );
  }

  String? _ambiguousPrefix(String folded) {
    const phrases = [
      'bir miktar',
      'birazcik',
      'biraz',
      'azicik',
      'birkac',
      'az',
    ];
    for (final phrase in phrases) {
      if (folded == phrase || folded.startsWith('$phrase ')) return phrase;
    }
    return null;
  }

  _Amount _takeAmount(String folded) {
    final digit = RegExp(r'^(\d+(?:[.,]\d+)?)').firstMatch(folded);
    if (digit != null) {
      final raw = digit.group(1)!.replaceAll(',', '.');
      return _Amount(
        quantity: double.tryParse(raw),
        rest: folded.substring(digit.end).trimLeft(),
      );
    }
    var rest = folded;
    var total = 0.0;
    var current = 0.0;
    var consumed = false;
    while (rest.isNotEmpty) {
      final token = rest.split(' ').first;
      if (token == 'bucuk') {
        current += 0.5;
        consumed = true;
        rest = _dropToken(rest, token);
        break;
      }
      if (token == 'yuz') {
        current = (current == 0 ? 1 : current) * 100;
        consumed = true;
        rest = _dropToken(rest, token);
        continue;
      }
      if (token == 'bin') {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
        consumed = true;
        rest = _dropToken(rest, token);
        continue;
      }
      final small = _small[token];
      if (small == null) break;
      current += small;
      consumed = true;
      rest = _dropToken(rest, token);
    }
    if (!consumed) return _Amount(quantity: null, rest: folded);
    return _Amount(quantity: total + current, rest: rest.trimLeft());
  }

  _UnitMatch? _takeUnit(String rest) {
    const units = <(String, PortionUnit, double?, String?)>[
      ('yemek kasigi', PortionUnit.tablespoon, null, null),
      ('tatli kasigi', PortionUnit.teaspoon, null, 'dessert'),
      ('cay kasigi', PortionUnit.teaspoon, null, 'tea'),
      ('kilogram', PortionUnit.gram, 1000, null),
      ('mililitre', PortionUnit.milliliter, null, null),
      ('gram', PortionUnit.gram, null, null),
      ('kg', PortionUnit.gram, 1000, null),
      ('gr', PortionUnit.gram, null, null),
      ('ml', PortionUnit.milliliter, null, null),
      ('adet', PortionUnit.piece, null, null),
      ('tane', PortionUnit.piece, null, null),
      ('dilim', PortionUnit.slice, null, null),
      ('bardak', PortionUnit.glass, null, null),
      ('porsiyon', PortionUnit.serving, null, null),
      ('kase', PortionUnit.bowl, null, null),
      ('tabak', PortionUnit.serving, null, 'plate'),
      ('kasik', PortionUnit.tablespoon, null, 'spoon'),
      ('g', PortionUnit.gram, null, null),
    ];
    for (final unit in units) {
      final phrase = unit.$1;
      if (rest == phrase || rest.startsWith('$phrase ')) {
        return _UnitMatch(
          unit: unit.$2,
          rest: rest.substring(phrase.length).trimLeft(),
          scaleToGrams: unit.$3,
          labelKey: unit.$4,
        );
      }
    }
    return null;
  }

  String _originalTail(String original, String folded, String nameFolded) {
    final index = folded.lastIndexOf(nameFolded);
    if (index < 0 || index + nameFolded.length > original.length) {
      return nameFolded;
    }
    return original.substring(index, index + nameFolded.length).trim();
  }

  String _dropToken(String text, String token) {
    final next = text.substring(token.length);
    return next.startsWith(' ') ? next.substring(1) : next;
  }

  String _fold(String input) {
    const map = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    final prepared = input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    final buffer = StringBuffer();
    for (final char in prepared.split('')) {
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }

  static const _small = {
    'sifir': 0.0,
    'bir': 1.0,
    'iki': 2.0,
    'uc': 3.0,
    'dort': 4.0,
    'bes': 5.0,
    'alti': 6.0,
    'yedi': 7.0,
    'sekiz': 8.0,
    'dokuz': 9.0,
    'on': 10.0,
    'yirmi': 20.0,
    'otuz': 30.0,
    'kirk': 40.0,
    'elli': 50.0,
    'altmis': 60.0,
    'yetmis': 70.0,
    'seksen': 80.0,
    'doksan': 90.0,
    'yarim': 0.5,
    'ceyrek': 0.25,
  };
}

class _Amount {
  const _Amount({required this.quantity, required this.rest});
  final double? quantity;
  final String rest;
}

class _UnitMatch {
  const _UnitMatch({
    required this.unit,
    required this.rest,
    required this.scaleToGrams,
    required this.labelKey,
  });
  final PortionUnit unit;
  final String rest;
  final double? scaleToGrams;
  final String? labelKey;
}

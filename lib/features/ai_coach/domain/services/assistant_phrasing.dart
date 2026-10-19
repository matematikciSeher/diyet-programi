/// Serbest soru metnini karşılaştırmaya hazırlar. Yanıt üretmez.
abstract final class AssistantPhrasing {
  static const _bounded = {
    'su',
    'yag',
    'kilo',
    'kalori',
    'kcal',
    'bel',
    'fat',
    'kahvalti',
    'ogle',
    'aksam',
    'atistir',
  };

  static const _suffixes = {
    'm',
    'n',
    'i',
    'e',
    'a',
    'u',
    'im',
    'in',
    'um',
    'un',
    'si',
    'su',
    'ye',
    'ya',
    'yi',
    'yu',
    'de',
    'da',
    'te',
    'ta',
    'den',
    'dan',
    'ten',
    'tan',
    'ler',
    'lar',
    'leri',
    'lari',
    'lerim',
    'larim',
    'mu',
    'mi',
    'nu',
    'ni',
    'sine',
    'sini',
    'miz',
    'niz',
    'li',
    'lu',
    'umun',
    'unun',
    'imin',
    'inin',
  };

  static const _vagueTokens = {
    'ne',
    'nasil',
    'mi',
    'mu',
    'midir',
    'acaba',
    'bir',
    've',
    'ile',
    'icin',
    'lutfen',
    'ya',
    'da',
    'bu',
    'o',
    'ben',
    'bana',
    'yapayim',
    'yapmali',
    'yapmaliyim',
    'soyler',
    'misin',
    'musun',
    'merhaba',
    'selam',
    'naber',
    'bilmiyorum',
    'yardim',
    'et',
    'tamam',
    'evet',
    'hayir',
    'sey',
    'simdi',
    'peki',
    'yani',
    'cok',
    'biraz',
  };

  /// Noktalama ve fazla boşluğu temizler. Türkçe İ/ı ayrımını korur.
  static String clean(String text) {
    var value = text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    value = value.replaceAll(RegExp(r'''[^a-zçğıöşü0-9\s]'''), ' ');
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Karşılaştırma için Türkçe karakterleri sadeleştirir.
  static String fold(String text) {
    const map = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }

  static String prepared(String text) => fold(clean(text));

  static bool has(String text, String phrase) {
    final folded = prepared(text);
    final key = prepared(phrase);
    if (key.isEmpty) return false;
    if (key.contains(' ')) return folded.contains(key);
    if (_bounded.contains(key)) return _tokenMentions(folded, key);
    return folded.contains(key);
  }

  static bool hasAny(String text, List<String> phrases) =>
      phrases.any((phrase) => has(text, phrase));

  static bool hasAll(String text, List<List<String>> groups) =>
      groups.every((group) => hasAny(text, group));

  /// Konu taşımayan kısa ifadeler. Bir kural eşleşmediyse açıklama istenir.
  static bool isVague(String text) {
    final folded = prepared(text);
    if (folded.isEmpty) return true;
    final tokens = folded.split(' ').where((token) => token.isNotEmpty);
    return tokens.every(_vagueTokens.contains);
  }

  static bool _tokenMentions(String folded, String keyword) {
    for (final token in folded.split(' ')) {
      if (token.isEmpty) continue;
      if (token == keyword) return true;
      if (!token.startsWith(keyword)) continue;
      final rest = token.substring(keyword.length);
      if (_suffixes.contains(rest)) return true;
    }
    return false;
  }
}

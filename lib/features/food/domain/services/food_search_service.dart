import '../../../../shared/models/food.dart';

/// Yerel eşleştirme ve sıralama. Büyük uzak veritabanı bağlandığında sunucu
/// tarafı arama sonuçlarını kullanıcının kendi yiyecekleriyle birleştirip
/// tek listede sıralamak için de kullanılır.
class FoodSearchService {
  const FoodSearchService();

  static const _foldMap = {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'i',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
    'â': 'a',
    'î': 'i',
    'û': 'u',
  };

  /// Büyük/küçük harf ve Türkçe karakter farkını yok sayar
  /// ("Çorba", "corba", "ÇORBA" aynıdır).
  static String normalize(String input) {
    final lower = input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(_foldMap[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<String> _tokens(String normalized) => normalized
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  /// Eşleşme puanı; 0 eşleşme yok demektir. Tüm sorgu kelimeleri ad, marka
  /// veya anahtar kelimelerde bir kelimenin başında geçmelidir.
  int score(Food food, String query) {
    final q = normalize(query);
    if (q.isEmpty) return 0;
    final queryTokens = _tokens(q);
    if (queryTokens.isEmpty) return 0;

    final name = normalize(food.name);
    final haystack = [
      name,
      if (food.brand != null) normalize(food.brand!),
      for (final k in food.keywords) normalize(k),
    ].join(' ');
    final tokens = _tokens(haystack);

    final allMatch = queryTokens.every(
      (qt) => tokens.any((t) => t.startsWith(qt)),
    );
    if (!allMatch) return 0;

    if (name == q) return 100;
    if (name.startsWith(q)) return 80;
    if (_tokens(name).any((t) => t.startsWith(queryTokens.first))) return 60;
    return 40;
  }

  /// [foods] içinden [query] ile eşleşenleri alaka düzeyine göre sıralar;
  /// aynı id'li kayıtlar tekilleştirilir (önce gelen korunur).
  List<Food> rank(Iterable<Food> foods, String query, {int? limit}) {
    final seen = <String>{};
    final scored = <(Food, int)>[];
    for (final food in foods) {
      if (!seen.add(food.id)) continue;
      final s = score(food, query);
      if (s > 0) scored.add((food, s));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      final byLength = a.$1.name.length.compareTo(b.$1.name.length);
      if (byLength != 0) return byLength;
      return normalize(a.$1.name).compareTo(normalize(b.$1.name));
    });
    final result = [for (final (food, _) in scored) food];
    return limit == null ? result : result.take(limit).toList();
  }

  /// Yerel adayları sorguya göre sıralar. Uzak API sonuçları zaten alaka
  /// düzeyine göre geldiği için yerel eşleşme şartı aranmaz; yalnızca
  /// yinelenen id'ler elenir.
  List<Food> combine({
    required Iterable<Food> local,
    required Iterable<Food> remote,
    required String query,
  }) {
    final ranked = rank([...local, ...remote], query);
    final seen = {for (final food in ranked) food.id};
    return [
      ...ranked,
      for (final food in remote)
        if (seen.add(food.id)) food,
    ];
  }
}

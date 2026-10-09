import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';
import '../models/plan_ingredient.dart';

/// Kullanıcının plan hakkında yazdığı cümleden çıkarılan istek.
class PlanChangeRequest extends Equatable {
  const PlanChangeRequest({
    this.excluded = const {},
    this.preferred = const {},
    this.mealTypes = const {},
    this.diet,
    this.regenerateAll = false,
  });

  /// "Tavuğu sevmiyorum", "kahvaltıda yumurta olmasın".
  final Set<PlanIngredient> excluded;

  /// "Akşam balık olsun".
  final Set<PlanIngredient> preferred;

  /// İsteğin sınırlı olduğu öğünler; boşsa tüm gün.
  final Set<MealType> mealTypes;

  /// "Vejetaryen olsun" gibi diyet tipi değişikliği.
  final DietType? diet;

  /// "Bu planı değiştir".
  final bool regenerateAll;

  bool get isEmpty =>
      excluded.isEmpty &&
      preferred.isEmpty &&
      mealTypes.isEmpty &&
      diet == null &&
      !regenerateAll;

  @override
  List<Object?> get props => [
    excluded,
    preferred,
    mealTypes,
    diet,
    regenerateAll,
  ];
}

/// Türkçe (ve basit İngilizce) plan değişikliği cümlelerini anahtar kelime
/// ve ek kurallarıyla yorumlar; ağ veya AI servisi gerektirmez.
///
/// Türkçe karakterler ASCII'ye indirgenerek karşılaştırılır; böylece
/// "tavugu sevmiyorum" gibi yazımlar da anlaşılır.
class PlanChangeParser {
  const PlanChangeParser();

  PlanChangeRequest parse(String text) {
    final (ingredients, normalized) = _extractPhrases(_fold(text));
    final tokens = _tokens(normalized);

    DietType? diet;
    for (final token in tokens) {
      for (final (stem, value) in _dietStems) {
        if (token.startsWith(stem)) diet = value;
      }
    }

    var hasPrivativeSuffix = false;
    for (final token in tokens) {
      final found = _ingredientsInToken(token);
      if (found.isEmpty) continue;
      ingredients.addAll(found);
      if (_privative.hasMatch(token)) hasPrivativeSuffix = true;
    }

    final mealTypes = <MealType>{
      for (final token in tokens)
        for (final (stem, type) in _mealStems)
          if (token.startsWith(stem)) type,
      if (normalized.contains(' ara ogun')) MealType.snack,
    };

    final negative =
        hasPrivativeSuffix ||
        tokens.any(
          (t) =>
              _negativeVerb.hasMatch(t) ||
              _negativeExact.contains(t) ||
              _negativePrefixes.any(t.startsWith),
        );
    final positive = tokens.any(_positiveWords.contains);
    final wantsChange = tokens.any((t) => _changeWords.any(t.startsWith));
    final mentionsWholePlan = tokens.any(
      (t) => t.startsWith('plan') || _wholeWords.contains(t),
    );

    final prefer = ingredients.isNotEmpty && positive && !negative;
    return PlanChangeRequest(
      excluded: prefer ? const {} : ingredients,
      preferred: prefer ? ingredients : const {},
      mealTypes: mealTypes,
      diet: diet,
      regenerateAll:
          ingredients.isEmpty &&
          diet == null &&
          mealTypes.isEmpty &&
          (wantsChange || mentionsWholePlan),
    );
  }

  /// Profildeki serbest metinleri ("mantar", "tavuk eti") bileşenlere
  /// çevirir.
  static Set<PlanIngredient> ingredientsIn(String text) {
    final (result, normalized) = _extractPhrases(_fold(text));
    for (final token in _tokens(normalized)) {
      result.addAll(_ingredientsInToken(token));
    }
    return result;
  }

  /// Çok kelimeli ifadeleri bulur ve metinden çıkarır.
  static (Set<PlanIngredient>, String) _extractPhrases(String normalized) {
    final found = <PlanIngredient>{};
    var rest = normalized;
    for (final (phrase, values) in _phrases) {
      if (rest.contains(phrase)) {
        found.addAll(values);
        rest = rest.replaceAll(phrase, ' ');
      }
    }
    return (found, rest);
  }

  static Set<PlanIngredient> _ingredientsInToken(String token) => {
    for (final rule in _rules)
      if (rule.exact.contains(token) || rule.prefixes.any(token.startsWith))
        ...rule.ingredients,
  };

  static String _fold(String text) {
    final lower = text
        .replaceAll(RegExp("['’`]"), '')
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
    const from = 'ıiğüşöçâîû';
    const to = 'iigusocaiu';
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      final index = from.indexOf(char);
      buffer.write(index < 0 ? char : to[index]);
    }
    return ' ${buffer.toString().replaceAll(RegExp('[^a-z0-9]+'), ' ')} ';
  }

  static List<String> _tokens(String normalized) =>
      normalized.split(' ').where((t) => t.isNotEmpty).toList();

  /// Tek kelime kurallarından önce uygulanır (ör. "beyaz et" kırmızı et,
  /// "mercimek köftesi" köfte sayılmasın).
  static const _phrases = <(String, Set<PlanIngredient>)>[
    (' mercimek kofte', {PlanIngredient.legumes, PlanIngredient.gluten}),
    (' beyaz et', {PlanIngredient.chicken}),
    (' kirmizi et', {PlanIngredient.redMeat}),
    (' deniz urun', PlanIngredient.seafood),
    (' sut urun', PlanIngredient.dairy),
    (' yer fistig', {PlanIngredient.peanut}),
    (' red meat', {PlanIngredient.redMeat}),
  ];

  static const _rules = [
    _Rule(
      {PlanIngredient.chicken},
      prefixes: ['tavuk', 'tavug', 'pilic', 'chicken', 'hindi', 'turkey'],
    ),
    _Rule(
      {PlanIngredient.redMeat},
      prefixes: [
        'kiyma',
        'kofte',
        'dana',
        'kuzu',
        'biftek',
        'sucuk',
        'pastirma',
        'karniyarik',
        'beef',
        'lamb',
      ],
      exact: ['et', 'eti', 'etli', 'ete', 'etten', 'etsiz'],
    ),
    _Rule(PlanIngredient.meat, prefixes: ['meat']),
    _Rule(
      {PlanIngredient.fish},
      prefixes: [
        'balik',
        'balig',
        'somon',
        'levrek',
        'hamsi',
        'cipura',
        'uskumru',
        'sardalya',
        'fish',
        'salmon',
        'tuna',
      ],
      exact: ['ton'],
    ),
    _Rule(
      {PlanIngredient.shellfish},
      prefixes: [
        'karides',
        'midye',
        'kalamar',
        'ahtapot',
        'shrimp',
        'shellfish',
      ],
    ),
    _Rule(PlanIngredient.seafood, prefixes: ['seafood']),
    _Rule(
      {PlanIngredient.egg},
      prefixes: ['yumurta', 'omlet', 'menemen'],
      exact: ['egg', 'eggs'],
    ),
    _Rule({PlanIngredient.milk}, prefixes: ['sut', 'milk']),
    _Rule(
      {PlanIngredient.cheese},
      prefixes: ['peynir', 'kasar', 'cheese'],
      exact: ['lor'],
    ),
    _Rule(
      {PlanIngredient.yogurt},
      prefixes: ['yogurt', 'yogurd', 'ayran', 'cacik', 'kefir'],
    ),
    _Rule(PlanIngredient.dairy, prefixes: ['laktoz', 'lactose', 'dairy']),
    _Rule(
      {PlanIngredient.legumes},
      prefixes: [
        'mercimek',
        'nohut',
        'fasulye',
        'baklagil',
        'humus',
        'piyaz',
        'lentil',
        'bean',
        'chickpea',
        'legume',
      ],
    ),
    _Rule(
      {PlanIngredient.gluten},
      prefixes: [
        'gluten',
        'ekmek',
        'ekmeg',
        'makarna',
        'bulgur',
        'bugday',
        'lavas',
        'bread',
        'pasta',
        'wheat',
      ],
    ),
    _Rule({PlanIngredient.oats}, prefixes: ['yulaf', 'oat']),
    _Rule(
      {PlanIngredient.nuts},
      prefixes: [
        'ceviz',
        'badem',
        'findik',
        'kuruyemis',
        'kaju',
        'walnut',
        'almond',
        'hazelnut',
        'nut',
      ],
    ),
    _Rule({PlanIngredient.peanut}, prefixes: ['fistik', 'peanut']),
    _Rule({PlanIngredient.sesame}, prefixes: ['susam', 'tahin', 'sesame']),
    _Rule({PlanIngredient.soy}, prefixes: ['soya', 'tofu'], exact: ['soy']),
    _Rule(
      {PlanIngredient.eggplant},
      prefixes: ['patlican', 'eggplant', 'aubergine'],
    ),
    _Rule({PlanIngredient.mushroom}, prefixes: ['mantar', 'mushroom']),
  ];

  static const _dietStems = <(String, DietType)>[
    ('vejetaryen', DietType.vegetarian),
    ('vejeteryan', DietType.vegetarian),
    ('vegetarian', DietType.vegetarian),
    ('vegan', DietType.vegan),
    ('hayvansal', DietType.vegan),
    ('pesketaryen', DietType.pescatarian),
    ('pescatarian', DietType.pescatarian),
  ];

  static const _mealStems = <(String, MealType)>[
    ('kahvalti', MealType.breakfast),
    ('breakfast', MealType.breakfast),
    ('ogle', MealType.lunch),
    ('lunch', MealType.lunch),
    ('aksam', MealType.dinner),
    ('dinner', MealType.dinner),
    ('supper', MealType.dinner),
    ('atistirma', MealType.snack),
    ('snack', MealType.snack),
  ];

  /// "-sız/-siz/-suz/-süz" (ör. "tavuksuz", "glutensiz").
  static final _privative = RegExp(r'(siz|suz)$');

  /// Olumsuz fiil ekleri: sevmiyorum, yemem, olmasın, beğenmedim, yemeyin.
  static final _negativeVerb = RegExp(
    r'(m[iu]yor|m[ae]m$|m[ae]z$|m[ae]sin|m[ae]d[iu]m|m[ae]y[ai]n)',
  );

  static const _negativePrefixes = [
    'haric',
    'cikar',
    'alerji',
    'nefret',
    'dokunuyor',
    'allergic',
    'remove',
    'avoid',
    'except',
    'without',
    'hate',
  ];

  static const _negativeExact = {'yok', 'hayir', 'dont', 'no', 'not', 'never'};

  static const _positiveWords = {
    'olsun',
    'istiyorum',
    'isterim',
    'seviyorum',
    'severim',
    'ekle',
    'koy',
    'want',
    'like',
    'love',
    'add',
    'include',
  };

  static const _changeWords = [
    'degis',
    'baska',
    'farkli',
    'yenile',
    'alternatif',
    'change',
    'swap',
    'another',
    'different',
    'replace',
  ];

  static const _wholeWords = {
    'tum',
    'tumu',
    'hepsi',
    'hepsini',
    'butun',
    'komple',
    'tamamen',
    'whole',
    'entire',
    'all',
  };
}

class _Rule {
  const _Rule(
    this.ingredients, {
    required this.prefixes,
    this.exact = const [],
  });

  final Set<PlanIngredient> ingredients;
  final List<String> prefixes;
  final List<String> exact;
}

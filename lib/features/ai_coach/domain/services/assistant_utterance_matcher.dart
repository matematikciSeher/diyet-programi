import '../catalog/assistant_catalog.dart';
import 'assistant_intent.dart';
import 'assistant_phrasing.dart';

/// Serbest yazılmış bir sorunun katalog sorusuna veya mevcut niyete bağlanması.
///
/// Cevap üretmez. Tek kelimeyle ilgisiz bir konuya kaymaz; birden fazla
/// gerçekten uygun konu varsa seçenek döner.
sealed class UtteranceResolution {
  const UtteranceResolution();
}

final class UtteranceQuestion extends UtteranceResolution {
  const UtteranceQuestion(this.id);

  final String id;
}

final class UtteranceIntent extends UtteranceResolution {
  const UtteranceIntent(this.intent);

  final AssistantIntent intent;
}

final class UtteranceAmbiguous extends UtteranceResolution {
  const UtteranceAmbiguous(this.questionIds);

  final List<String> questionIds;
}

final class UtteranceUnclear extends UtteranceResolution {
  const UtteranceUnclear();
}

final class UtteranceNone extends UtteranceResolution {
  const UtteranceNone();
}

class _Rule {
  const _Rule(this.priority, this.when, this.resolution);

  final int priority;
  final bool Function(String folded) when;
  final UtteranceResolution resolution;
}

abstract final class AssistantUtteranceMatcher {
  static UtteranceResolution resolve(
    String raw, {
    String? prior,
    String? categoryId,
  }) {
    if (_followUp(raw, prior) case final follow?) return follow;
    final current = _scopeToCategory(_match(raw), categoryId);
    if (current is! UtteranceAmbiguous) return current;
    final kept = narrow(current.questionIds, prior);
    if (kept.length == 1) return UtteranceQuestion(kept.first);
    if (kept.length != current.questionIds.length) {
      return UtteranceAmbiguous(kept);
    }
    return current;
  }

  /// Önceki mesaj tek bir kategoriye oturuyorsa seçenekleri ona daraltır.
  static List<String> narrow(List<String> questionIds, String? prior) {
    if (prior == null || prior.trim().isEmpty || questionIds.length < 2) {
      return questionIds;
    }
    final categories = _categories(_match(prior));
    if (categories.isEmpty) return questionIds;
    final kept = [
      for (final id in questionIds)
        if (categories.contains(AssistantCatalog.categoryOf(id)?.id)) id,
    ];
    return kept.length == 1 ? kept : questionIds;
  }

  static UtteranceResolution _match(String raw) {
    final exact = AssistantCatalog.exactMatches(raw);
    if (exact.length == 1) return UtteranceQuestion(exact.first.id);
    if (exact.length > 1) {
      return UtteranceAmbiguous([for (final question in exact) question.id]);
    }

    final folded = AssistantPhrasing.prepared(raw);
    if (folded.isEmpty) return const UtteranceUnclear();

    final special = _special(folded);
    if (special != null) return special;

    final matched = [for (final rule in _rules) if (rule.when(folded)) rule];
    if (matched.isEmpty) {
      return AssistantPhrasing.isVague(folded)
          ? const UtteranceUnclear()
          : const UtteranceNone();
    }
    matched.sort((a, b) => b.priority.compareTo(a.priority));
    final top = matched.first.priority;
    final winners = matched.where((rule) => rule.priority == top).toList();
    final distinct = <String, UtteranceResolution>{};
    for (final rule in winners) {
      distinct[_key(rule.resolution)] = rule.resolution;
    }
    if (distinct.length == 1) return distinct.values.first;
    final ids = <String>[];
    for (final resolution in distinct.values) {
      switch (resolution) {
        case UtteranceQuestion(:final id):
          ids.add(id);
        case UtteranceAmbiguous(:final questionIds):
          ids.addAll(questionIds);
        default:
          break;
      }
    }
    if (ids.length >= 2) return UtteranceAmbiguous(ids.take(3).toList());
    return winners.first.resolution;
  }

  static String _key(UtteranceResolution resolution) => switch (resolution) {
    UtteranceQuestion(:final id) => 'q:$id',
    UtteranceIntent(:final intent) => 'i:${intent.name}',
    UtteranceAmbiguous(:final questionIds) => 'a:${questionIds.join(',')}',
    UtteranceUnclear() => 'unclear',
    UtteranceNone() => 'none',
  };

  static Set<String> _categories(UtteranceResolution resolution) =>
      switch (resolution) {
        UtteranceQuestion(:final id) => {
          ?AssistantCatalog.categoryOf(id)?.id,
        },
        UtteranceIntent(:final intent) => {?_intentCategory(intent)},
        UtteranceAmbiguous(:final questionIds) => {
          for (final id in questionIds)
            ?AssistantCatalog.categoryOf(id)?.id,
        },
        _ => const {},
      };

  static String? _intentCategory(AssistantIntent intent) => switch (intent) {
    AssistantIntent.remainingCalories || AssistantIntent.overTarget =>
      'calories',
    AssistantIntent.dailyReview => 'balanced',
    AssistantIntent.protein => 'protein',
    AssistantIntent.carbs => 'carbs',
    AssistantIntent.fat => 'fats',
    AssistantIntent.mealSuggestion => 'meal_pattern',
    AssistantIntent.water => 'water',
    AssistantIntent.weight => 'weight_loss',
    AssistantIntent.planReview || AssistantIntent.swapPlan => 'meal_pattern',
    _ => null,
  };

  /// Belirsiz seçenekler seçili kategorideyse ona daralır. Zayıf bir
  /// benzerlikle başka konuya kaydırmaz.
  static UtteranceResolution _scopeToCategory(
    UtteranceResolution current,
    String? categoryId,
  ) {
    if (categoryId == null || categoryId.isEmpty) return current;
    if (current is! UtteranceAmbiguous) return current;
    final kept = [
      for (final id in current.questionIds)
        if (AssistantCatalog.categoryOf(id)?.id == categoryId) id,
    ];
    if (kept.length == 1) return UtteranceQuestion(kept.first);
    if (kept.length > 1) return UtteranceAmbiguous(kept);
    return current;
  }

  static List<String> preferCategory(List<String> ids, String? categoryId) {
    if (categoryId == null || categoryId.isEmpty || ids.length < 2) return ids;
    final kept = [
      for (final id in ids)
        if (AssistantCatalog.categoryOf(id)?.id == categoryId) id,
    ];
    return kept.isEmpty ? ids : kept;
  }

  static UtteranceResolution? _followUp(String raw, String? prior) {
    if (prior == null || prior.trim().isEmpty) return null;
    final folded = AssistantPhrasing.prepared(raw);
    final priorFolded = AssistantPhrasing.prepared(prior);
    final referential = AssistantPhrasing.hasAny(folded, [
      'peki',
      'hangileri',
      'hangisini',
      'bunlari',
      'bunlar',
      'onlari',
    ]);
    if (!referential) return null;
    if (AssistantPhrasing.hasAny(priorFolded, ['lif', 'lifli']) &&
        AssistantPhrasing.has(folded, 'kahvalti')) {
      return const UtteranceQuestion('fiber.breakfast');
    }
    final tokens = folded.split(' ').where((token) => token.isNotEmpty);
    if (tokens.length <= 2) return const UtteranceUnclear();
    return null;
  }

  static UtteranceResolution? _special(String folded) {
    if (AssistantPhrasing.has(folded, 'kalsiyum')) {
      final bone = AssistantPhrasing.hasAny(folded, ['kemik', 'kas']);
      final vitamin = AssistantPhrasing.has(folded, 'vitamin');
      if (bone && !vitamin) return const UtteranceQuestion('bone.calcium');
      if (vitamin && !bone) return const UtteranceQuestion('vit.calcium');
      return const UtteranceAmbiguous(['vit.calcium', 'bone.calcium']);
    }
    if (_losingWeight(folded)) {
      return const UtteranceAmbiguous(['weight.habits', 'cal.track']);
    }
    if (AssistantPhrasing.hasAny(folded, ['yorgun', 'halsiz', 'bitkin']) &&
        !AssistantPhrasing.hasAny(folded, [
          'uyku',
          'uyumak',
          'uyuya',
          'uyuyami',
          'uykusuz',
          'enerji',
        ])) {
      return const UtteranceAmbiguous([
        'energy.habits',
        'sleep.energy',
        'well.care',
      ]);
    }
    if (AssistantPhrasing.has(folded, 'demir') &&
        !AssistantPhrasing.hasAny(folded, [
          'yiyecek',
          'besin',
          'gida',
          'hangi',
          'nerede',
          'kaynak',
          'adet',
          'gebelik',
          'hamile',
          'menopoz',
          'kadin',
        ])) {
      return const UtteranceAmbiguous(['vit.iron', 'wom.iron']);
    }
    return null;
  }

  static bool _losingWeight(String folded) => AssistantPhrasing.hasAny(folded, [
    'kilo vermek',
    'kilo kaybet',
    'kilo kaybi',
    'zayiflamak',
    'kilo dusur',
  ]);

  static final _rules = <_Rule>[
    _Rule(
      15,
      (text) =>
          AssistantPhrasing.hasAny(text, [
            'lifli besin',
            'lif iceren besin',
            'lifli gida',
          ]) &&
          AssistantPhrasing.hasAny(text, ['neler', 'hangileri', 'nedir']),
      const UtteranceQuestion('shop.fiber'),
    ),
    _Rule(
      15,
      (text) =>
          AssistantPhrasing.has(text, 'tatli') &&
          AssistantPhrasing.hasAny(text, [
            'neden',
            'aksam',
            'gece',
            'alamiyor',
            'alamadim',
          ]),
      const UtteranceQuestion('sweet.evening'),
    ),
    _Rule(
      15,
      (text) =>
          AssistantPhrasing.has(text, 'seker') &&
          AssistantPhrasing.hasAny(text, ['azalt', 'istegi', 'istegim']),
      const UtteranceQuestion('sweet.reduce'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, ['siskinlik', 'siskin', 'gazim']),
      const UtteranceQuestion('bloat.habits'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, ['kabizlik', 'kabiz']),
      const UtteranceQuestion('constip.habits'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.hasAny(text, ['reflu', 'mide yanmasi']),
      const UtteranceQuestion('reflux.general'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.has(text, 'kolesterol') &&
          !AssistantPhrasing.has(text, 'ilac'),
      const UtteranceQuestion('chol.pattern'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.has(text, 'tansiyon') &&
          AssistantPhrasing.hasAny(text, ['tuz', 'beslen', 'sodyum', 'yemek']) &&
          !AssistantPhrasing.has(text, 'ilac'),
      const UtteranceQuestion('bp.pattern'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.has(text, 'menopoz'),
      const UtteranceQuestion('wom.menopause'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.hasAny(text, ['gebelik', 'hamile']) &&
          AssistantPhrasing.hasAny(text, ['beslen', 'yemek', 'dikkat']) &&
          !AssistantPhrasing.has(text, 'ilac'),
      const UtteranceQuestion('wom.pregnancy'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.hasAny(text, ['cocuk', 'cocuklarda']) &&
          AssistantPhrasing.hasAny(text, ['beslen', 'ogun', 'dengeli']) &&
          !AssistantPhrasing.has(text, 'ates') &&
          !AssistantPhrasing.has(text, 'ilac'),
      const UtteranceQuestion('child.balance'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, [
        'ileri yas',
        'yaslil',
        'yaslarda beslen',
      ]),
      const UtteranceQuestion('older.habits'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.hasAny(text, ['takviye', 'vitamin kullan']) &&
          !AssistantPhrasing.has(text, 'doz') &&
          !AssistantPhrasing.has(text, 'mg'),
      const UtteranceQuestion('supp.general'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.has(text, 'vegan'),
      const UtteranceQuestion('pref.vegan'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, ['vejetaryen', 'vegetarian']),
      const UtteranceQuestion('pref.vegetarian'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.has(text, 'gece') &&
          AssistantPhrasing.hasAny(text, ['acikir', 'gece yemek', 'gece yeme']) &&
          !AssistantPhrasing.has(text, 'tatli'),
      const UtteranceQuestion('snack.night'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, [
        'kilo koru',
        'kilomu koru',
        'kilo koruma',
      ]),
      const UtteranceQuestion('maintain.habits'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.has(text, 'dusuk kalori') &&
          AssistantPhrasing.hasAny(text, ['besin', 'yiyecek', 'yemek', 'ogun']),
      const UtteranceQuestion('lowcal.foods'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, [
        'yuksek protein',
        'proteinli besin',
      ]),
      const UtteranceQuestion('hiprot.foods'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'islenmis') &&
          AssistantPhrasing.has(text, 'gida'),
      const UtteranceQuestion('fact.processed'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'ogun atla'),
      const UtteranceQuestion('weight.skip'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'enerji yogun'),
      const UtteranceQuestion('cal.density'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'tam tahil'),
      const UtteranceQuestion('carb.wholegrain'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'zeytinyagi') &&
          AssistantPhrasing.hasAny(text, ['yag', 'doymamis', 'saglik']),
      const UtteranceQuestion('fat.olive'),
    ),
    _Rule(
      11,
      (text) =>
          AssistantPhrasing.has(text, 'kahvalti') &&
          AssistantPhrasing.has(text, 'atla'),
      const UtteranceQuestion('breakfast.skip'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'icindekiler') &&
          AssistantPhrasing.hasAny(text, ['sira', 'liste', 'etiket']),
      const UtteranceQuestion('shop.order'),
    ),
    _Rule(
      11,
      (text) =>
          AssistantPhrasing.has(text, 'yavas') &&
          AssistantPhrasing.hasAny(text, ['cign', 'cigney', 'lokma', 'yemek']),
      const UtteranceQuestion('hunger.pace'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'meyve') &&
          AssistantPhrasing.has(text, 'seker') &&
          !AssistantPhrasing.has(text, 'ilac'),
      const UtteranceQuestion('sweet.fruit'),
    ),
    _Rule(
      11,
      (text) =>
          AssistantPhrasing.has(text, 'kafein') &&
          AssistantPhrasing.hasAny(text, ['uyku', 'aksam']),
      const UtteranceQuestion('sleep.caffeine'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'fermente'),
      const UtteranceQuestion('micro.ferment'),
    ),
    _Rule(
      11,
      (text) =>
          AssistantPhrasing.has(text, 'laktoz') &&
          !AssistantPhrasing.has(text, 'ilac'),
      const UtteranceQuestion('intol.vs'),
    ),
    _Rule(
      11,
      (text) => AssistantPhrasing.has(text, 'multivitamin'),
      const UtteranceQuestion('supp.multi'),
    ),
    _Rule(
      14,
      (text) => AssistantPhrasing.hasAny(text, [
        'cok fazla',
        'fazla yedim',
        'fazla kalori',
        'fazla kacirdim',
        'hedefi astim',
        'hedefimi astim',
      ]),
      const UtteranceIntent(AssistantIntent.overTarget),
    ),
    _Rule(
      13,
      (text) =>
          AssistantPhrasing.hasAny(text, ['yedim', 'yedik', 'yemis']) &&
          AssistantPhrasing.hasAny(text, [
            'ne yapayim',
            'ne yapmali',
            'simdi ne',
          ]) &&
          !AssistantPhrasing.hasAny(text, ['tarif', 'nasil pisir', 'nasil yapar']),
      const UtteranceIntent(AssistantIntent.overTarget),
    ),
    _Rule(
      13,
      (text) =>
          AssistantPhrasing.has(text, 'su') &&
          AssistantPhrasing.hasAny(text, ['unut', 'hatirla', 'hatirlay']),
      const UtteranceQuestion('water.remind'),
    ),
    _Rule(
      13,
      (text) =>
          AssistantPhrasing.has(text, 'protein') &&
          AssistantPhrasing.hasAny(text, [
            'ne yi',
            'hangi yiyecek',
            'kaynak',
            'iceren',
            'almak icin',
          ]) &&
          !AssistantPhrasing.hasAny(text, ['ulast', 'hedefe']),
      const UtteranceQuestion('macro.protein_foods'),
    ),
    _Rule(
      13,
      (text) =>
          AssistantPhrasing.has(text, 'protein') &&
          AssistantPhrasing.hasAny(text, [
            'hedef',
            'ulast',
            'kaydim',
            'aldigim',
          ]) &&
          !AssistantPhrasing.hasAny(text, [
            'ne yi',
            'hangi yiyecek',
            'kaynak',
            'iceren',
            'almak icin',
          ]),
      const UtteranceIntent(AssistantIntent.protein),
    ),
    _Rule(
      13,
      (text) => AssistantPhrasing.hasAll(text, [
        ['menu', 'menum', 'menumde'],
        ['bugun'],
        ['ne var', 'neler var', 'ne yiyecek'],
      ]),
      const UtteranceIntent(AssistantIntent.planReview),
    ),
    _Rule(
      13,
      (text) =>
          AssistantPhrasing.has(text, 'tatli') &&
          AssistantPhrasing.hasAny(text, [
            'istiyorum',
            'canim',
            'alternatif',
            'yerine',
            'yesem',
          ]),
      const UtteranceQuestion('snack.sweet'),
    ),
    _Rule(
      13,
      (text) =>
          AssistantPhrasing.hasAny(text, ['alerji', 'alerjim', 'alerjiler']) &&
          AssistantPhrasing.hasAny(text, [
            'uygun',
            'dikkat',
            'tercih',
            'sevmed',
            'yiyeme',
          ]),
      const UtteranceQuestion('pref.choose'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.has(text, 'kalori') &&
          AssistantPhrasing.hasAny(text, [
            'aldim',
            'almisim',
            'almis',
            'tukettim',
            'tuketmis',
          ]) &&
          !AssistantPhrasing.hasAny(text, ['hakkim', 'kaldi']),
      const UtteranceQuestion('cal.consumed'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.has(text, 'kalori') &&
          AssistantPhrasing.hasAny(text, ['hakkim', 'kaldi']) &&
          !AssistantPhrasing.hasAny(text, ['aldim', 'almisim', 'tukettim']),
      const UtteranceIntent(AssistantIntent.remainingCalories),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, [
        'bugunku beslenme',
        'bugun nasil beslen',
        'nasil besleniyorum',
        'gunluk degerlendirme',
        'beslenmem nasil',
      ]),
      const UtteranceQuestion('daily.how'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, [
        'ne kadar su',
        'su ictim',
        'su icmis',
        'kac bardak su',
        'su hedef',
      ]),
      const UtteranceQuestion('water.today'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAll(text, [
        ['evde', 'hizlica', 'hizli', 'pratik'],
        ['hazirla', 'pisir', 'tarif', 'yapabilir'],
      ]),
      const UtteranceQuestion('recipe.practical'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAll(text, [
        ['alisveris'],
        ['liste', 'listem', 'listemde', 'listesi', 'neler bulun', 'neler var'],
      ]),
      const UtteranceQuestion('shop.list'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, [
        'uyumak',
        'uyuya',
        'uyku',
        'uykusuz',
        'uyuyami',
      ]),
      const UtteranceQuestion('sleep.routine'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.has(text, 'demir') &&
          AssistantPhrasing.hasAny(text, [
            'yiyecek',
            'besin',
            'gida',
            'hangi',
            'nerede',
            'kaynak',
          ]) &&
          !AssistantPhrasing.hasAny(text, [
            'adet',
            'gebelik',
            'hamile',
            'menopoz',
            'kadin',
          ]),
      const UtteranceQuestion('vit.iron'),
    ),
    _Rule(
      12,
      (text) =>
          AssistantPhrasing.has(text, 'demir') &&
          AssistantPhrasing.hasAny(text, [
            'adet',
            'gebelik',
            'hamile',
            'menopoz',
            'kadin',
          ]),
      const UtteranceQuestion('wom.iron'),
    ),
    _Rule(
      12,
      (text) => AssistantPhrasing.hasAny(text, ['sevmedigim', 'sevmiyorum']),
      const UtteranceQuestion('pref.dislikes'),
    ),
    _Rule(
      11,
      (text) =>
          AssistantPhrasing.has(text, 'karbonhidrat') &&
          AssistantPhrasing.hasAny(text, ['kayd', 'durum', 'nasil']) &&
          !AssistantPhrasing.hasAny(text, ['neler', 'nedir', 'fark', 'kompleks']),
      const UtteranceIntent(AssistantIntent.carbs),
    ),
    _Rule(
      11,
      (text) =>
          AssistantPhrasing.has(text, 'yag') &&
          AssistantPhrasing.hasAny(text, ['kayd', 'durum', 'aldim']),
      const UtteranceIntent(AssistantIntent.fat),
    ),
    _Rule(
      10,
      (text) =>
          AssistantPhrasing.hasAny(text, [
            'kahvalti',
            'ogle',
            'aksam',
            'atistir',
            'ara ogun',
          ]) &&
          AssistantPhrasing.hasAny(text, [
            'ne yesem',
            'ne yiyeyim',
            'ne yiyebilirim',
            'ne yemeli',
            'icin ne',
          ]),
      const UtteranceIntent(AssistantIntent.mealSuggestion),
    ),
  ];
}

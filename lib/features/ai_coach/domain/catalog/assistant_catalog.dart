import '../../../../shared/models/enums.dart';
import '../models/guide_snapshot.dart';
import '../services/assistant_phrasing.dart';
import '../services/assistant_text.dart';
import 'assistant_extra_phrases.dart';
import 'assistant_extra_records.dart';
import 'assistant_topics.dart';

/// Beş sabit bölüm. Sıra, kategori ekranındaki görünüm sırasıdır.
enum AssistantSection { diet, foods, habits, digestion, special }

/// Katalog sorusu mevcut tipli yanıta mı, rehbere mi gider.
enum AssistantRoute { guide, daily, calories, protein, water, meal }

class AssistantQuestion {
  const AssistantQuestion({
    required this.id,
    required this.tr,
    required this.en,
    this.route = AssistantRoute.guide,
    this.data = GuideDataKind.none,
    this.mealType,
    this.phrases = const [],
  });

  final String id;
  final String tr;
  final String en;
  final AssistantRoute route;
  final GuideDataKind data;
  final MealType? mealType;

  /// Aynı kayda giden alternatif soru cümleleri. Ekranda kart olarak görünmez.
  final List<String> phrases;

  List<String> get prompts => [tr, en, ...phrases];

  AssistantQuestion copyWith({List<String>? phrases}) => AssistantQuestion(
    id: id,
    tr: tr,
    en: en,
    route: route,
    data: data,
    mealType: mealType,
    phrases: phrases ?? this.phrases,
  );
}

class AssistantCategory {
  const AssistantCategory({
    required this.id,
    required this.section,
    required this.titleTr,
    required this.titleEn,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.keywords,
    required this.questions,
    this.cautious = false,
  });

  final String id;
  final AssistantSection section;
  final String titleTr;
  final String titleEn;
  final String descriptionTr;
  final String descriptionEn;
  final List<String> keywords;
  final List<AssistantQuestion> questions;

  /// Sağlık sınırı notu gösterilir. Sayı uyduran bir cevap değildir.
  final bool cautious;

  AssistantCategory copyWith({List<AssistantQuestion>? questions}) =>
      AssistantCategory(
        id: id,
        section: section,
        titleTr: titleTr,
        titleEn: titleEn,
        descriptionTr: descriptionTr,
        descriptionEn: descriptionEn,
        keywords: keywords,
        questions: questions ?? this.questions,
        cautious: cautious,
      );
}

/// Beslenme asistanının sabit kategori ve bilgi kayıtları.
///
/// Kimlikler derleme zamanında sabittir; uygulama her açılışta yeni
/// kategori üretmez. Soru kartları arayüzde gösterilmez. Kayıtlar yalnızca
/// yerel eşleştirme içindir.
abstract final class AssistantCatalog {
  static const nutritionSectionTitleTr = 'Beslenme ve diyet';
  static const nutritionSectionTitleEn = 'Nutrition and diet';
  static const wellnessSectionTitleTr = 'Sindirim ve genel sağlık';
  static const wellnessSectionTitleEn = 'Digestion and general health';

  static const suggestedIds = [
    'daily.how',
    'cal.left',
    'water.today',
    'snack.ideas',
    'week.how',
    'fact.fiber',
  ];

  static final List<AssistantCategory> categories = _verified(
    _expanded(buildAssistantTopics()),
  );

  static List<AssistantCategory> _verified(List<AssistantCategory> items) {
    final ids = <String>{};
    final questions = <String>{};
    for (final category in items) {
      if (!ids.add(category.id)) {
        throw StateError('Yinelenen kategori: ${category.id}');
      }
      if (category.questions.isEmpty) {
        throw StateError('Boş kategori: ${category.id}');
      }
      for (final question in category.questions) {
        if (!questions.add(question.id)) {
          throw StateError('Yinelenen soru: ${question.id}');
        }
      }
    }
    _verifyPhrases(items);
    return items;
  }

  /// Yeni cümleler mevcut bir kaydın metniyle çakışırsa katalog açılmaz.
  /// Bilerek paylaşılan eski cümleler (örneğin iki kalsiyum kaydı) durur.
  static void _verifyPhrases(List<AssistantCategory> items) {
    final owned = <String, String>{};
    for (final category in items) {
      for (final question in category.questions) {
        for (final prompt in [question.tr, question.en]) {
          final stem = _stem(prompt);
          if (stem.isEmpty) continue;
          owned.putIfAbsent(stem, () => question.id);
        }
      }
    }
    final added = <String>{};
    for (final category in items) {
      for (final question in category.questions) {
        for (final phrase in question.phrases) {
          final stem = _stem(phrase);
          if (stem.length < 12) {
            throw StateError('Ek cümle çok kısa: ${question.id}');
          }
          if (!added.add(stem)) {
            throw StateError('Yinelenen ek cümle: $stem');
          }
          final owner = owned[stem];
          if (owner != null && owner != question.id) {
            throw StateError('Ek cümle başka kayda ait: $stem');
          }
          owned[stem] = question.id;
        }
      }
    }
  }

  static List<AssistantCategory> _expanded(List<AssistantCategory> items) => [
    for (final category in items)
      category.copyWith(
        questions: [
          for (final question in category.questions)
            question.copyWith(
              phrases: assistantExtraPhrases[question.id] ?? const [],
            ),
          ...assistantExtraRecords[category.id] ?? const [],
        ],
      ),
  ];

  static List<AssistantCategory> inSection(AssistantSection section) => [
    for (final category in categories)
      if (category.section == section) category,
  ];

  static List<AssistantQuestion> get questions => [
    for (final category in categories) ...category.questions,
  ];

  static AssistantQuestion? questionById(String id) {
    for (final question in questions) {
      if (question.id == id) return question;
    }
    return null;
  }

  static AssistantCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  static AssistantCategory? categoryOf(String questionId) {
    for (final category in categories) {
      for (final question in category.questions) {
        if (question.id == questionId) return category;
      }
    }
    return null;
  }

  static List<AssistantQuestion> suggestedQuestions() => [
    for (final id in suggestedIds) ?questionById(id),
  ];

  static List<AssistantCategory> search(String raw) {
    final query = _stem(raw);
    if (query.isEmpty) return categories;
    final found = <AssistantCategory>[];
    for (final category in categories) {
      final haystack = _stem(
        [
          category.titleTr,
          category.titleEn,
          category.descriptionTr,
          category.descriptionEn,
          ...category.keywords,
          for (final question in category.questions) ...question.prompts,
        ].join(' '),
      );
      if (_queryHits(haystack, query)) found.add(category);
    }
    return found;
  }

  /// Kısa sorgular yalnızca kelime olarak aranır; "su" "sürdürülebilir"i tutmaz.
  static bool _queryHits(String haystack, String query) {
    if (query.length >= 3) return haystack.contains(query);
    return haystack.split(' ').contains(query);
  }

  /// Katalogdaki soruyla birebir aynı metin. Aynı cümle birden fazla
  /// kategorideyse hepsi döner; serbest yorum bu listeyi daraltabilir.
  static List<AssistantQuestion> exactMatches(String raw) {
    final stem = _stem(raw);
    if (stem.isEmpty) return const [];
    final found = <String, AssistantQuestion>{};
    for (final question in questions) {
      for (final prompt in question.prompts) {
        if (_stem(prompt) == stem) found[question.id] = question;
      }
    }
    return found.values.toList();
  }

  /// Serbest cümleyi hazır sorulara yaklaştırır.
  ///
  /// İki içeriği kelime paylaşılmadan veya tek kelime birçok soruda geçiyorsa
  /// eşleşme yoktur. Böylece ilgisiz bir cümle hazır cevaba kaymaz.
  static List<AssistantQuestion> closest(String raw, {String? categoryId}) {
    final asked = _contentTokens(raw);
    if (asked.isEmpty) return const [];
    final ranked = <({AssistantQuestion question, int shared, double score})>[];
    for (final question in questions) {
      final tokens = _contentTokens(question.tr);
      if (tokens.isEmpty) continue;
      final shared = _shared(asked, tokens);
      if (shared == 0) continue;
      final unique = shared == 1 && _unique(asked, tokens);
      if (shared < 2 && !unique) continue;
      final coverage = shared / tokens.length;
      final recall = shared / asked.length;
      if (!unique && coverage < 0.5 && recall < 0.67) continue;
      ranked.add((
        question: question,
        shared: shared,
        score: coverage + recall + shared / 10,
      ));
    }
    if (ranked.isEmpty) return const [];
    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : b.shared.compareTo(a.shared);
    });
    final best = ranked.first.score;
    final close = [
      for (final item in ranked)
        if (item.score >= best - 0.2) item,
    ];
    if (categoryId != null && categoryId.isNotEmpty) {
      final inCategory = [
        for (final item in close)
          if (categoryOf(item.question.id)?.id == categoryId) item.question,
      ];
      if (inCategory.length == 1) return inCategory;
      if (inCategory.length > 1) return inCategory.take(3).toList();
    }
    if (close.length == 1) return [close.first.question];
    final second = ranked[1];
    if (ranked.first.shared > second.shared || best > second.score + 0.12) {
      return [ranked.first.question];
    }
    return [for (final item in close.take(3)) item.question];
  }

  static const _filler = {
    'ne',
    'nasil',
    'mi',
    'mu',
    'midir',
    'mudur',
    'nedir',
    'neler',
    'nelerdir',
    'nelere',
    'hangi',
    'hangileri',
    'bir',
    've',
    'ile',
    'icin',
    'da',
    'de',
    'bu',
    'o',
    'ben',
    'bana',
    'var',
    'yok',
    'daha',
    'cok',
    'neden',
    'niye',
    'hakkinda',
    'genel',
    'olarak',
    'bugun',
    'kac',
    'kadar',
    'boyle',
    'sey',
  };

  static const _endings = [
    'leri',
    'lari',
    'ler',
    'lar',
    'dir',
    'dur',
    'tir',
    'tur',
    'den',
    'dan',
    'ten',
    'tan',
    'nin',
    'nun',
    'lik',
    'luk',
    'luk',
  ];

  static Set<String> _contentTokens(String raw) {
    final tokens = <String>{};
    for (final token in _stem(raw).split(' ')) {
      if (token.length < 3 || _filler.contains(token)) continue;
      tokens.add(_base(token));
    }
    return tokens;
  }

  static String _base(String token) {
    if (token.length < 7) return token;
    for (final ending in _endings) {
      if (token.length - ending.length < 5) continue;
      if (token.endsWith(ending)) {
        return token.substring(0, token.length - ending.length);
      }
    }
    return token;
  }

  static int _shared(Set<String> asked, Set<String> tokens) {
    var count = 0;
    for (final token in asked) {
      if (tokens.any((other) => _same(token, other))) count++;
    }
    return count;
  }

  static bool _same(String a, String b) {
    if (a == b) return true;
    if (a.length < 5 || b.length < 5) return false;
    final longer = a.length >= b.length ? a : b;
    final shorter = a.length >= b.length ? b : a;
    if (!longer.startsWith(shorter)) return false;
    final rest = longer.substring(shorter.length);
    return rest.length >= 2 && rest.length <= 4;
  }

  static bool _unique(Set<String> asked, Set<String> tokens) {
    final shared = [
      for (final token in asked)
        if (tokens.any((other) => _same(token, other))) token,
    ];
    if (shared.length != 1 || shared.first.length < 6) return false;
    final word = shared.first;
    var owners = 0;
    for (final question in questions) {
      final tokens = _contentTokens(question.tr);
      if (tokens.any((token) => _same(token, word))) owners++;
      if (owners > 1) return false;
    }
    return owners == 1;
  }

  /// Kullanıcı metni katalog sorusunun tamamını içeriyorsa o soru.
  /// Kısa bir parçanın uzun sorunun içinde geçmesi eşleşme sayılmaz.
  static AssistantQuestion? matchContained(String raw) {
    final normalized = _stem(raw);
    if (normalized.length < 12) return null;
    AssistantQuestion? best;
    var bestLength = 0;
    for (final question in questions) {
      for (final prompt in question.prompts) {
        final stem = _stem(prompt);
        if (stem.length >= 12 &&
            stem.length > bestLength &&
            normalized.contains(stem)) {
          best = question;
          bestLength = stem.length;
        }
      }
    }
    return best;
  }

  /// Tam soru ya da yeterince ayırt edici bir parça.
  static AssistantQuestion? match(String raw) {
    final normalized = _stem(raw);
    if (normalized.isEmpty) return null;
    AssistantQuestion? best;
    var bestScore = 0;
    var bestStemLength = 1 << 30;
    for (final question in questions) {
      for (final prompt in question.prompts) {
        final stem = _stem(prompt);
        if (stem.isEmpty) continue;
        var score = 0;
        if (normalized == stem) {
          score = 100000 + stem.length;
        } else if (normalized.length >= 12 && stem.contains(normalized)) {
          score = 1000 + normalized.length;
        } else if (stem.length >= 12 && normalized.contains(stem)) {
          score = stem.length;
        }
        final closer =
            score == bestScore && score > 0 && stem.length < bestStemLength;
        if (score > bestScore || closer) {
          best = question;
          bestScore = score;
          bestStemLength = stem.length;
        }
      }
    }
    return bestScore == 0 ? null : best;
  }

  static String _stem(String value) {
    final folded = AssistantPhrasing.prepared(value);
    if (folded.isNotEmpty) return folded;
    return AssistantText.normalize(value);
  }
}

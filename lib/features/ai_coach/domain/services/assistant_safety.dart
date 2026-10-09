import '../models/assistant_reply.dart';

/// Yanıt üretilmeden önce soruyu güvenlik açısından sınıflandırır.
abstract final class AssistantSafety {
  /// Günlük bu değerin altındaki enerji hedefleri aşırı kısıtlama sayılır.
  static const minSafeDailyKcal = 1200;

  static const _eatingDisorder = [
    'kusmak',
    'kusma',
    'kustum',
    'kusuyorum',
    'kusarak',
    'yeme bozuklu',
    'anoreks',
    'bulimi',
    'tıkınırcasına',
    'tıkınma',
    'laksatif',
    'müshil',
    'kendimi aç bırak',
    'kendimi cezalandır',
    'yemek yemeyi bırak',
    'vomit',
    'purge',
    'eating disorder',
    'anorexi',
    'bulimia',
    'binge',
    'laxative',
    'starve myself',
  ];

  static const _extremeRestriction = [
    'aç kalay',
    'aç kalmak',
    'aç kalı',
    'aç kalın',
    'hiç yemesem',
    'hiç yemek yemesem',
    'hiçbir şey yemesem',
    'sadece su',
    'hızlı kilo ver',
    'çok hızlı zayıf',
    'bir haftada 5',
    'bir haftada 10',
    'haftada 5 kilo',
    'haftada 10 kilo',
    'ayda 15',
    'ayda 20',
    'detoks',
    'stop eating',
    'only water',
    'lose weight fast',
    'crash diet',
  ];

  static const _medical = [
    'hastalı',
    'teşhis',
    'tanı koy',
    'ilaç',
    'diyabet',
    'şeker hasta',
    'insülin',
    'tansiyon',
    'böbrek',
    'karaciğer',
    'tiroid',
    'kanser',
    'hamile',
    'gebe',
    'emzir',
    'kalp krizi',
    'göğüs ağrı',
    'reçete',
    'disease',
    'diagnos',
    'medication',
    'diabetes',
    'insulin',
    'blood pressure',
    'kidney',
    'thyroid',
    'pregnan',
    'breastfeed',
  ];

  static final _kcalAmount = RegExp(r'(\d{2,4})\s*(kcal|kalori|calorie)');

  static SafetyConcern? check(String normalized) {
    bool any(List<String> words) => words.any(normalized.contains);
    if (any(_eatingDisorder)) return SafetyConcern.eatingDisorder;
    if (any(_extremeRestriction)) return SafetyConcern.extremeRestriction;
    for (final m in _kcalAmount.allMatches(normalized)) {
      final value = int.parse(m.group(1)!);
      final aboutDaily =
          normalized.contains('günde') ||
          normalized.contains('günlük') ||
          normalized.contains('per day') ||
          normalized.contains('a day');
      if (aboutDaily && value < minSafeDailyKcal) {
        return SafetyConcern.extremeRestriction;
      }
    }
    if (any(_medical)) return SafetyConcern.medical;
    return null;
  }
}

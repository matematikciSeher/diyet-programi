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

  static const _emergency = [
    'göğüs ağr',
    'gogus agr',
    'nefes dar',
    'nefesi dar',
    'nefesim dar',
    'bayıl',
    'bayil',
    'bayıld',
    'bayildi',
    'ani güçsüz',
    'ani gucsuz',
    'chest pain',
    'shortness of breath',
    'short of breath',
    "can't breathe",
    'cannot breathe',
    'fainting',
    'i fainted',
    'passed out',
    'sudden weakness',
  ];

  static const _dose = [
    'kaç mg',
    'kac mg',
    'kaç iu',
    'kac iu',
    'mg almal',
    'mg almali',
    'dozunu değiş',
    'dozunu degis',
    'doz değiş',
    'doz degis',
    'ilaç doz',
    'ilac doz',
    'takviye doz',
    'how many mg',
    'what dose',
    'supplement dose',
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

  /// Acil belirti, yeme bozukluğu, aşırı kısıtlama ve doz soruları.
  /// Katalogdaki genel bilgilendirme soruları bu süzgeçten geçer;
  /// geniş tıbbi kelime listesi yalnızca serbest metinde kullanılır.
  static SafetyConcern? checkUrgent(String normalized) {
    bool any(List<String> words) => words.any(normalized.contains);
    if (any(_emergency)) return SafetyConcern.emergency;
    if (any(_eatingDisorder)) return SafetyConcern.eatingDisorder;
    if (any(_extremeRestriction)) return SafetyConcern.extremeRestriction;
    if (any(_dose)) return SafetyConcern.medical;
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
    return null;
  }

  static SafetyConcern? check(String normalized) {
    if (checkUrgent(normalized) case final concern?) return concern;
    bool any(List<String> words) => words.any(normalized.contains);
    if (any(_medical)) return SafetyConcern.medical;
    return null;
  }
}

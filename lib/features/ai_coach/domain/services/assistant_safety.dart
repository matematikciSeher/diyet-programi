import '../models/assistant_reply.dart';
import 'assistant_phrasing.dart';

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
    'kusacak',
    'kusacag',
    'kusmuk',
    'kustur',
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
    'intihar',
    'suicide',
    'kendime zarar',
    'kill myself',
    'baygin',
    'anafilaksi',
    'alerji sok',
    'bilinc kayb',
    'kanama durmuyor',
    'inme gecir',
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
    'doz',
    'dosage',
    'kac tablet',
    'how many tablet',
  ];

  static const _medical = [
    'hastalı',
    'teşhis',
    'tanı koy',
    'ilaç',
    'şeker hasta',
    'insülin',
    'böbrek',
    'karaciğer',
    'tiroid',
    'kanser',
    'kalp krizi',
    'göğüs ağrı',
    'reçete',
    'disease',
    'diagnos',
    'medication',
    'insulin',
    'blood pressure',
    'kidney',
    'thyroid',
    'hipoglisemi',
    'hypogly',
    'my blood sugar',
    'blood sugar is high',
    'tedavi yerine',
    'doktorun verdigi',
    'mucize diyet',
    'kanseri yener',
    'hastaligi tedavi',
    'bebege ilac',
    'cocuga ilac',
    'cocuguma ilac',
  ];

  /// Kişiye özel hastalık yönetimi. Konu adının kendisi yasak değildir.
  static const _personal = [
    'kan sekerim',
    'sekerim yuksek',
    'sekerim dusuk',
    'tansiyonum',
    'hamileyim',
    'gebeyim',
    'hastaligim ne',
    'bana tani',
    'cocugum ates',
    'bebek ates',
    'cocuk ates',
  ];

  static final _kcalAmount = RegExp(r'(\d{2,4})\s*(kcal|kalori|calorie)');
  static final _doseAmount = RegExp(r'\d{1,5}\s*(mg|iu|mcg)');

  /// Acil belirti, yeme bozukluğu, aşırı kısıtlama ve doz soruları.
  /// Katalogdaki genel bilgilendirme soruları bu süzgeçten geçer;
  /// geniş tıbbi kelime listesi yalnızca serbest metinde kullanılır.
  static SafetyConcern? checkUrgent(String normalized) {
    final folded = AssistantPhrasing.prepared(normalized);
    if (folded.isEmpty) return null;
    if (_has(folded, _emergency) || _urgentSymptom(folded)) {
      return SafetyConcern.emergency;
    }
    if (_childFever(folded)) return SafetyConcern.emergency;
    if (_has(folded, _eatingDisorder)) return SafetyConcern.eatingDisorder;
    if (_has(folded, _extremeRestriction) || _lowDailyTarget(folded)) {
      return SafetyConcern.extremeRestriction;
    }
    if (_has(folded, _dose) || _doseAmount.hasMatch(folded)) {
      return SafetyConcern.medical;
    }
    return null;
  }

  static SafetyConcern? check(String normalized) {
    if (checkUrgent(normalized) case final concern?) return concern;
    final folded = AssistantPhrasing.prepared(normalized);
    if (_has(folded, _medical) || _has(folded, _personal)) {
      return SafetyConcern.medical;
    }
    return null;
  }

  static bool _has(String folded, List<String> words) => words.any(
    (word) => folded.contains(AssistantPhrasing.prepared(word)),
  );

  static bool _lowDailyTarget(String folded) {
    final aboutDaily =
        folded.contains('gunde') ||
        folded.contains('gunluk') ||
        folded.contains('per day') ||
        folded.contains('a day');
    if (!aboutDaily) return false;
    for (final match in _kcalAmount.allMatches(folded)) {
      final value = int.parse(match.group(1)!);
      if (value < minSafeDailyKcal) return true;
    }
    return false;
  }

  /// "göğsüm ağrıyor" ve "nefesim daralıyor" gibi bitişik yazılmayan belirtiler.
  static bool _urgentSymptom(String folded) {
    final tokens = folded.split(' ').where((token) => token.isNotEmpty);
    bool starts(String stem) => tokens.any((token) => token.startsWith(stem));
    final chest = starts('gogus') || starts('gogs');
    if (chest && starts('agr')) return true;
    if (starts('nefes') && starts('dar')) return true;
    if (starts('bayil') || starts('baygin')) return true;
    if (starts('ani') && starts('gucsuz')) return true;
    if (starts('kanama') && (starts('durm') || starts('cok'))) return true;
    return false;
  }

  static bool _childFever(String folded) {
    final child =
        folded.contains('cocuk') ||
        folded.contains('bebek') ||
        folded.contains('cocug');
    if (!child) return false;
    return folded.contains('ates') || folded.contains('nobet');
  }
}

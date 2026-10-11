class GuideCopy {
  const GuideCopy({
    required this.direct,
    required this.points,
    required this.tips,
  });

  final String direct;
  final List<String> points;
  final List<String> tips;
}

class LocalizedGuide {
  const LocalizedGuide({required this.tr, required this.en});

  final GuideCopy tr;
  final GuideCopy en;

  GuideCopy forLanguage(String languageCode) =>
      languageCode == 'tr' ? tr : en;
}

LocalizedGuide guide(
  String directTr,
  List<String> pointsTr,
  List<String> tipsTr,
  String directEn,
  List<String> pointsEn,
  List<String> tipsEn,
) => LocalizedGuide(
  tr: GuideCopy(direct: directTr, points: pointsTr, tips: tipsTr),
  en: GuideCopy(direct: directEn, points: pointsEn, tips: tipsEn),
);

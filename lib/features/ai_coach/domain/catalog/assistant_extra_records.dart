import 'assistant_catalog.dart';

/// İnce kalan kategorilere eklenen yerel kayıtlar.
///
/// Doz, teşhis veya tedavi yoktur. Her kayıtın rehberi
/// `assistant_guides_topics.dart` içindedir.
const assistantExtraRecords = <String, List<AssistantQuestion>>{
  'balanced': [
    AssistantQuestion(
      id: 'fact.processed',
      tr: 'İşlenmiş gıda günlük dilde ne anlama gelir?',
      en: 'What does processed food mean in everyday language?',
    ),
  ],
  'weight_loss': [
    AssistantQuestion(
      id: 'weight.skip',
      tr: 'Öğün atlamak kilo vermenin güvenilir yolu mudur?',
      en: 'Is skipping meals a reliable way to lose weight?',
    ),
  ],
  'weight_maintain': [
    AssistantQuestion(
      id: 'maintain.social',
      tr: 'Davetlerde kilo korumak nasıl düşünülür?',
      en: 'How is weight maintenance thought about at gatherings?',
    ),
  ],
  'calories': [
    AssistantQuestion(
      id: 'cal.density',
      tr: 'Enerji yoğunluğu ne demektir?',
      en: 'What does energy density mean?',
    ),
  ],
  'protein': [
    AssistantQuestion(
      id: 'protein.timing',
      tr: 'Proteini tek öğüne yığmak gerekir mi?',
      en: 'Does protein have to be piled into one meal?',
    ),
  ],
  'carbs': [
    AssistantQuestion(
      id: 'carb.wholegrain',
      tr: 'Tam tahıllı ürün ne demektir?',
      en: 'What does a whole-grain food mean?',
    ),
  ],
  'fats': [
    AssistantQuestion(
      id: 'fat.olive',
      tr: 'Zeytinyağı doymamış yağ örneği midir?',
      en: 'Is olive oil an example of an unsaturated fat?',
    ),
  ],
  'fiber': [
    AssistantQuestion(
      id: 'fiber.slow',
      tr: 'Lif miktarı neden yavaş artırılır?',
      en: 'Why is fiber raised slowly?',
    ),
  ],
  'vitamins': [
    AssistantQuestion(
      id: 'vit.foodfirst',
      tr: 'Vitamin ihtiyacı neden önce besinle düşünülür?',
      en: 'Why is a vitamin need thought about from food first?',
    ),
  ],
  'portions': [
    AssistantQuestion(
      id: 'portion.eye',
      tr: 'Porsiyonu tabakta nasıl gözle tahmin ederim?',
      en: 'How can I estimate a portion by looking at the plate?',
    ),
  ],
  'breakfast': [
    AssistantQuestion(
      id: 'breakfast.skip',
      tr: 'Kahvaltı atlamak herkese uygun mudur?',
      en: 'Is skipping breakfast suitable for everyone?',
    ),
  ],
  'snacks': [
    AssistantQuestion(
      id: 'snack.choose',
      tr: 'Acıkınca atıştırmalık nasıl seçilir?',
      en: 'How do I choose a snack when I am hungry?',
    ),
  ],
  'shopping': [
    AssistantQuestion(
      id: 'shop.order',
      tr: 'İçindekiler listesinde sıra neden önemlidir?',
      en: 'Why does the order of an ingredient list matter?',
    ),
  ],
  'water': [
    AssistantQuestion(
      id: 'water.personal',
      tr: 'Günlük su miktarı neden kişiye göre değişir?',
      en: 'Why does a daily water amount differ by person?',
    ),
  ],
  'hunger': [
    AssistantQuestion(
      id: 'hunger.pace',
      tr: 'Yavaş çiğnemek tokluk hissini nasıl etkiler?',
      en: 'How can slower chewing affect fullness?',
    ),
  ],
  'sweets': [
    AssistantQuestion(
      id: 'sweet.fruit',
      tr: 'Meyve şekeri ile eklenen şeker aynı şey midir?',
      en: 'Is the sugar in fruit the same as added sugar?',
    ),
  ],
  'night_eating': [
    AssistantQuestion(
      id: 'night.kitchen',
      tr: 'Gece mutfağa gitme dürtüsü nasıl fark edilir?',
      en: 'How can a night-time kitchen habit be noticed?',
    ),
  ],
  'meal_pattern': [
    AssistantQuestion(
      id: 'meal.flex',
      tr: 'Öğün saatleri her gün aynı olmak zorunda mıdır?',
      en: 'Do meal times have to be identical every day?',
    ),
  ],
  'emotional': [
    AssistantQuestion(
      id: 'emo.notice',
      tr: 'Duygusal yemeyi fark etmek için nelere bakılır?',
      en: 'What can I notice when eating follows a feeling?',
    ),
  ],
  'sleep': [
    AssistantQuestion(
      id: 'sleep.caffeine',
      tr: 'Kafein akşam uykusuyla nasıl ilişkilidir?',
      en: 'How can caffeine relate to evening sleep?',
    ),
  ],
  'activity': [
    AssistantQuestion(
      id: 'activity.after',
      tr: 'Hareketten sonra öğün neden konuşulur?',
      en: 'Why is a meal discussed after activity?',
    ),
  ],
  'bloating': [
    AssistantQuestion(
      id: 'bloat.speed',
      tr: 'Hızlı yemek şişkinlik hissini artırabilir mi?',
      en: 'Can eating quickly add to a bloated feeling?',
    ),
  ],
  'microbiome': [
    AssistantQuestion(
      id: 'micro.ferment',
      tr: 'Fermente besinler genel olarak ne anlama gelir?',
      en: 'What do fermented foods mean in general?',
    ),
  ],
  'intolerance': [
    AssistantQuestion(
      id: 'intol.vs',
      tr: 'Süt alerjisi ile laktoz intoleransı aynı mıdır?',
      en: 'Are milk allergy and lactose intolerance the same?',
    ),
  ],
  'glucose': [
    AssistantQuestion(
      id: 'glu.order',
      tr: 'Öğünde sebze ve proteini öne almak neden anlatılır?',
      en: 'Why are vegetables and protein mentioned before the starch?',
    ),
  ],
  'supplements': [
    AssistantQuestion(
      id: 'supp.multi',
      tr: 'Multivitamin herkes için gerekli midir?',
      en: 'Does everyone need a multivitamin?',
    ),
  ],
};

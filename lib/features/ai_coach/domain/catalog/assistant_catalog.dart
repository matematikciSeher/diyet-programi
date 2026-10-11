import '../../../../shared/models/enums.dart';
import '../models/guide_snapshot.dart';
import '../services/assistant_text.dart';

enum AssistantSection { nutrition, wellness }

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
  });

  final String id;
  final String tr;
  final String en;
  final AssistantRoute route;
  final GuideDataKind data;
  final MealType? mealType;
}

class AssistantCategory {
  const AssistantCategory({
    required this.id,
    required this.section,
    required this.titleTr,
    required this.titleEn,
    required this.questions,
  });

  final String id;
  final AssistantSection section;
  final String titleTr;
  final String titleEn;
  final List<AssistantQuestion> questions;

  AssistantCategory copyWith({List<AssistantQuestion>? questions}) =>
      AssistantCategory(
        id: id,
        section: section,
        titleTr: titleTr,
        titleEn: titleEn,
        questions: questions ?? this.questions,
      );
}

/// Beslenme ve sağlıklı yaşam soru kataloğu.
///
/// Eşleşme tam metinle yapılır. Serbest yazıda da soru gövdesi tanınırsa
/// aynı cevap şablonu seçilir. Tanınmayan soru mevcut niyet motoruna düşer.
abstract final class AssistantCatalog {
  static const nutritionSectionTitleTr = 'Beslenme';
  static const nutritionSectionTitleEn = 'Nutrition';
  static const wellnessSectionTitleTr = 'Sağlıklı Yaşam ve Genel Sağlık';
  static const wellnessSectionTitleEn = 'Healthy living and general health';

  static const suggestedIds = [
    'daily.how',
    'cal.left',
    'water.today',
    'snack.ideas',
    'week.how',
    'fact.fiber',
  ];

  static final categories = <AssistantCategory>[
    _cat(
      'daily',
      AssistantSection.nutrition,
      'Günlük Beslenme Değerlendirmesi',
      'Daily nutrition check',
      [
        _q('daily.how', 'Bugün nasıl beslendim?', 'How did I eat today?', route: AssistantRoute.daily),
        _q('daily.balanced', 'Günlük beslenmem dengeli mi?', 'Is my eating balanced today?', data: GuideDataKind.daily),
        _q('daily.improve_meal', 'Hangi öğünümü iyileştirebilirim?', 'Which meal could I improve?', data: GuideDataKind.daily),
        _q('daily.groups', 'Bugün hangi besin gruplarını az tüketmiş olabilirim?', 'Which food groups might be light in today\'s log?', data: GuideDataKind.daily),
        _q('daily.rest', 'Günün geri kalanında nasıl beslenebilirim?', 'How can I eat for the rest of the day?', data: GuideDataKind.daily),
        _q('daily.improve', 'Bugünkü beslenmemde neleri geliştirebilirim?', 'What could I develop in today\'s eating?', data: GuideDataKind.daily),
      ],
    ),
    _cat(
      'calories',
      AssistantSection.nutrition,
      'Kalori ve Günlük Hedefler',
      'Calories and daily targets',
      [
        _q('cal.consumed', 'Bugün kaç kalori aldım?', 'How many calories have I had today?', data: GuideDataKind.calories),
        _q('cal.left', 'Günlük kalori hedefime ne kadar kaldı?', 'How much is left in my calorie target?', data: GuideDataKind.calories),
        _q('cal.eat', 'Kalan kalorime uygun ne yiyebilirim?', 'What can I eat with the calories I have left?', route: AssistantRoute.meal),
        _q('cal.track', 'Kalori hedefimi nasıl takip edebilirim?', 'How can I keep track of my calorie target?'),
        _q('cal.split', 'Öğünlerimi gün içine nasıl dağıtabilirim?', 'How can I spread meals through the day?', data: GuideDataKind.calories),
        _q('cal.tips', 'Kalori hesabında nelere dikkat etmeliyim?', 'What should I pay attention to when counting calories?'),
      ],
    ),
    _cat(
      'macros',
      AssistantSection.nutrition,
      'Protein, Karbonhidrat ve Yağ',
      'Protein, carbohydrate and fat',
      [
        _q('macro.protein_foods', 'Protein içeren besinler nelerdir?', 'Which foods contain protein?'),
        _q('macro.fats', 'Sağlıklı yağ kaynakları hangileridir?', 'What are sources of unsaturated fats?'),
        _q('macro.complex_carbs', 'Kompleks karbonhidratlar nelerdir?', 'What are complex carbohydrates?'),
        _q('macro.balance', 'Bir öğünü nasıl daha dengeli hâle getirebilirim?', 'How can I make a meal more balanced?', data: GuideDataKind.daily),
        _q('macro.plant_protein', 'Bitkisel protein kaynakları nelerdir?', 'What are plant protein sources?'),
        _q('macro.roles', 'Protein, karbonhidrat ve yağın vücuttaki görevleri nelerdir?', 'What do protein, carbohydrate and fat do in the body?'),
      ],
    ),
    _cat(
      'breakfast',
      AssistantSection.nutrition,
      'Kahvaltı Önerileri',
      'Breakfast ideas',
      [
        _q('breakfast.how', 'Sağlıklı bir kahvaltı nasıl hazırlanır?', 'How is a balanced breakfast put together?'),
        _q('breakfast.practical', 'Pratik kahvaltı önerileri verir misin?', 'Can you suggest practical breakfasts?', route: AssistantRoute.meal, meal: MealType.breakfast),
        _q('breakfast.protein', 'Protein içeren kahvaltılar nelerdir?', 'What are higher-protein breakfasts?', route: AssistantRoute.meal, meal: MealType.breakfast),
        _q('breakfast.sweet', 'Tatlı kahvaltı yerine ne yiyebilirim?', 'What can I eat instead of a sweet breakfast?'),
        _q('breakfast.prep', 'Kahvaltımı önceden nasıl hazırlayabilirim?', 'How can I prepare breakfast ahead?'),
        _q('breakfast.satiety', 'Kahvaltıda daha uzun süre tok tutabilecek seçenekler nelerdir?', 'Which breakfast choices tend to keep you full longer?'),
      ],
    ),
    _cat(
      'main_meals',
      AssistantSection.nutrition,
      'Öğle ve Akşam Yemekleri',
      'Lunch and dinner',
      [
        _q('main.lunch', 'Bugün öğle yemeğinde ne yiyebilirim?', 'What could I eat for lunch today?', route: AssistantRoute.meal, meal: MealType.lunch),
        _q('main.dinner', 'Hafif bir akşam yemeği önerir misin?', 'Can you suggest a lighter dinner?', route: AssistantRoute.meal, meal: MealType.dinner),
        _q('main.veg', 'Sebze ağırlıklı öğünler nelerdir?', 'What do vegetable-forward meals look like?'),
        _q('main.plate', 'Dengeli bir tabak nasıl hazırlanır?', 'How is a balanced plate put together?'),
        _q('main.pack', 'İşe veya okula götürebileceğim yemekler nelerdir?', 'What meals travel well to work or school?'),
        _q('main.pantry', 'Evdeki malzemelerle nasıl bir öğün hazırlayabilirim?', 'How can I make a meal from what I have?', data: GuideDataKind.recipes),
      ],
    ),
    _cat(
      'snacks',
      AssistantSection.nutrition,
      'Ara Öğünler ve Atıştırmalıklar',
      'Snacks',
      [
        _q('snack.ideas', 'Sağlıklı ara öğün önerileri nelerdir?', 'What are everyday snack ideas?'),
        _q('snack.sweet', 'Tatlı isteğim olduğunda ne yiyebilirim?', 'What can I eat when I want something sweet?'),
        _q('snack.practical', 'Pratik atıştırmalıklar nelerdir?', 'What are practical snacks?', route: AssistantRoute.meal, meal: MealType.snack),
        _q('snack.fruit', 'Meyvenin yanında ne tüketebilirim?', 'What can I have with fruit?'),
        _q('snack.night', 'Gece acıkırsam nasıl bir seçim yapabilirim?', 'What is a reasonable choice if I am hungry at night?'),
        _q('snack.packaged', 'Paketli atıştırmalık seçerken nelere dikkat etmeliyim?', 'What should I look at on a packaged snack?'),
      ],
    ),
    _cat(
      'recipes',
      AssistantSection.nutrition,
      'Tarifler ve Yemek Hazırlama',
      'Recipes and cooking',
      [
        _q('recipe.ingredients', 'Elimdeki malzemelerle tarif önerir misin?', 'Can you suggest a recipe from ingredients I have?', data: GuideDataKind.recipes),
        _q('recipe.practical', 'Pratik ve sağlıklı yemekler nelerdir?', 'What are practical meals in my recipe list?', data: GuideDataKind.recipes),
        _q('recipe.less_fat', 'Daha az yağ kullanarak nasıl yemek yapabilirim?', 'How can I cook with less added fat?'),
        _q('recipe.portion', 'Bir tarifin porsiyonunu nasıl ayarlayabilirim?', 'How do I adjust a recipe portion?'),
        _q('recipe.prep', 'Öğün hazırlığını önceden nasıl yapabilirim?', 'How can I prepare meals ahead?'),
        _q('recipe.match', 'Mevcut tariflerimden hedefime uygun olanları göster.', 'Show saved recipes that fit my target.', data: GuideDataKind.recipes),
      ],
    ),
    _cat(
      'swaps',
      AssistantSection.nutrition,
      'Besin Değişimleri ve Alternatifler',
      'Swaps and alternatives',
      [
        _q('swap.bread', 'Ekmek yerine hangi alternatifleri değerlendirebilirim?', 'What alternatives can I consider instead of bread?', data: GuideDataKind.preferences),
        _q('swap.sugar', 'Şekerli yiyecekler yerine ne tüketebilirim?', 'What can I have instead of sugary foods?'),
        _q('swap.fry', 'Kızartma yerine hangi pişirme yöntemlerini kullanabilirim?', 'Which cooking methods can I use instead of deep-frying?'),
        _q('swap.choose', 'Bir besine alternatif nasıl seçebilirim?', 'How can I choose an alternative food?', data: GuideDataKind.preferences),
        _q('swap.dairy', 'Süt ürünü tüketmiyorsam hangi seçenekleri değerlendirebilirim?', 'What options can I consider if I skip dairy?', data: GuideDataKind.preferences),
        _q('swap.allergy', 'Besin alerjim veya intoleransım varsa nelere dikkat etmeliyim?', 'What should I keep in mind with a food allergy or intolerance?', data: GuideDataKind.preferences),
      ],
    ),
    _cat(
      'water',
      AssistantSection.nutrition,
      'Su Tüketimi ve Günlük Alışkanlıklar',
      'Water and daily habits',
      [
        _q('water.today', 'Bugün ne kadar su içtim?', 'How much water have I logged today?', route: AssistantRoute.water),
        _q('water.left', 'Günlük su hedefime ne kadar kaldı?', 'How much is left in my water target?', data: GuideDataKind.water),
        _q('water.remind', 'Su içmeyi nasıl hatırlayabilirim?', 'How can I remember to drink water?', data: GuideDataKind.water),
        _q('water.routine', 'Günlük beslenme düzenimi nasıl geliştirebilirim?', 'How can I make my eating routine steadier?'),
        _q('water.regular', 'Daha düzenli öğünler için ne yapabilirim?', 'What can help meals stay more regular?'),
        _q('water.journal', 'Beslenme günlüğü tutmak ne işe yarar?', 'What is a food log useful for?'),
      ],
    ),
    _cat(
      'weight',
      AssistantSection.nutrition,
      'Kilo Yönetimi ve Hedefler',
      'Weight and goals',
      [
        _q('weight.progress', 'Beslenme hedeflerime nasıl daha düzenli ilerleyebilirim?', 'How can I move toward my eating goals more steadily?', data: GuideDataKind.weight),
        _q('weight.habits', 'Kilo yönetiminde hangi alışkanlıklar yardımcı olabilir?', 'Which habits can support weight management?', data: GuideDataKind.weight),
        _q('weight.portions', 'Porsiyon kontrolü nasıl yapılır?', 'How does portion awareness work?'),
        _q('weight.track', 'Kilo takibini nasıl değerlendirebilirim?', 'How can I look at weight tracking?', data: GuideDataKind.weight),
        _q('weight.metrics', 'İlerlememi hangi ölçütlerle takip edebilirim?', 'Which measures can I follow besides the scale?', data: GuideDataKind.weight),
        _q('weight.daily_change', 'Kilo değişimleri neden günlük olarak farklılık gösterebilir?', 'Why can weight differ from day to day?', data: GuideDataKind.weight),
      ],
    ),
    _cat(
      'planning',
      AssistantSection.nutrition,
      'Öğün Planlama ve Zaman Yönetimi',
      'Meal planning',
      [
        _q('plan.week', 'Haftalık öğünlerimi nasıl planlayabilirim?', 'How can I plan meals for the week?', data: GuideDataKind.plan),
        _q('plan.busy', 'Yoğun günler için pratik yemekler nelerdir?', 'What meals work on busy days?'),
        _q('plan.next', 'Bir sonraki öğünümü nasıl planlayabilirim?', 'How can I plan my next meal?', data: GuideDataKind.plan),
        _q('plan.prep', 'Öğün hazırlığını nasıl kolaylaştırabilirim?', 'How can I make meal prep easier?'),
        _q('plan.day', 'Günlük öğünlerimi nasıl düzenleyebilirim?', 'How can I organize the day\'s meals?', data: GuideDataKind.plan),
        _q('plan.review', 'Mevcut haftalık menümdeki öğünleri nasıl değerlendirebilirim?', 'How can I look at the meals already in my weekly menu?', data: GuideDataKind.plan),
      ],
    ),
    _cat(
      'shopping',
      AssistantSection.nutrition,
      'Alışveriş ve Malzeme Seçimi',
      'Shopping and ingredients',
      [
        _q('shop.list', 'Sağlıklı alışveriş listesi nasıl hazırlanır?', 'How is a practical shopping list built?', data: GuideDataKind.shopping),
        _q('shop.staples', 'Temel mutfak malzemeleri neler olabilir?', 'What are useful kitchen staples?'),
        _q('shop.labels', 'Etiket okurken nelere dikkat etmeliyim?', 'What should I notice on a food label?'),
        _q('shop.fiber', 'Lif içeren besinler hangileridir?', 'Which foods contain fiber?'),
        _q('shop.season', 'Mevsim sebze ve meyvelerini nasıl değerlendirebilirim?', 'How can I use fruit and vegetables that are in season?'),
        _q('shop.menu', 'Haftalık menüme göre alışveriş listemi nasıl düzenleyebilirim?', 'How can I organize my shopping list from the weekly menu?', data: GuideDataKind.shopping),
      ],
    ),
    _cat(
      'eating_out',
      AssistantSection.nutrition,
      'Dışarıda ve Sosyal Ortamlarda Beslenme',
      'Eating out and social meals',
      [
        _q('out.restaurant', 'Restoranda daha dengeli seçimler nasıl yapılır?', 'How can restaurant choices stay more balanced?'),
        _q('out.buffet', 'Açık büfede nelere dikkat edebilirim?', 'What can I pay attention to at a buffet?'),
        _q('out.travel', 'Yolculukta yanımda ne götürebilirim?', 'What can I bring on a trip?'),
        _q('out.guest', 'Misafirlikte porsiyonlarımı nasıl dengeleyebilirim?', 'How can I pace portions when I am a guest?'),
        _q('out.compare', 'Menüdeki seçenekleri nasıl karşılaştırabilirim?', 'How can I compare items on a menu?'),
        _q('out.variety', 'Dışarıda yemek yerken besin çeşitliliğini nasıl koruyabilirim?', 'How can I keep variety when eating out?'),
      ],
    ),
    _cat(
      'facts',
      AssistantSection.nutrition,
      'Beslenme Bilgisi ve Doğru Bilinen Yanlışlar',
      'Nutrition basics and common claims',
      [
        _q('fact.fiber', 'Lif neden önemlidir?', 'Why does fiber matter?'),
        _q('fact.protein', 'Protein ne işe yarar?', 'What is protein for?'),
        _q('fact.carbs', 'Basit ve kompleks karbonhidratlar arasındaki fark nedir?', 'What is the difference between simple and complex carbohydrates?'),
        _q('fact.portion', 'Porsiyon ve kalori arasındaki ilişki nedir?', 'How are portion and calories related?'),
        _q('fact.variety', 'Besin çeşitliliği neden önemlidir?', 'Why does food variety matter?'),
        _q('fact.claims', 'Popüler beslenme iddialarını nasıl değerlendirebilirim?', 'How can I weigh popular nutrition claims?'),
      ],
    ),
    _cat(
      'preferences',
      AssistantSection.nutrition,
      'Beslenme Tercihleri ve Beslenme Düzenleri',
      'Preferences and eating patterns',
      [
        _q('pref.vegetarian', 'Vejetaryen beslenmede nelere dikkat etmeliyim?', 'What is worth attention in a vegetarian pattern?', data: GuideDataKind.preferences),
        _q('pref.vegan', 'Vegan beslenmede besin çeşitliliğini nasıl sağlayabilirim?', 'How can a vegan pattern stay varied?', data: GuideDataKind.preferences),
        _q('pref.lactose', 'Laktozsuz alternatifler nelerdir?', 'What are lactose-free options?', data: GuideDataKind.preferences),
        _q('pref.gluten', 'Glutensiz ürün seçerken nelere dikkat etmeliyim?', 'What should I notice when choosing gluten-free products?', data: GuideDataKind.preferences),
        _q('pref.dislikes', 'Sevmediğim besinlerin yerine ne tüketebilirim?', 'What can stand in for foods I dislike?', data: GuideDataKind.preferences),
        _q('pref.choose', 'Alerjilerime ve tercihlerime uygun öğünleri nasıl seçebilirim?', 'How can I choose meals that fit my allergies and preferences?', data: GuideDataKind.preferences),
      ],
    ),
    _cat(
      'weekly',
      AssistantSection.nutrition,
      'Haftalık Beslenme Özeti',
      'Weekly nutrition summary',
      [
        _q('week.how', 'Bu hafta beslenmem nasıldı?', 'How did this week\'s eating look?', data: GuideDataKind.week),
        _q('week.days', 'Hangi günlerde öğün kaydı tuttum?', 'On which days did I log meals?', data: GuideDataKind.week),
        _q('week.calories', 'Kalori hedeflerime ne kadar yaklaştım?', 'How close did logged days come to my calorie target?', data: GuideDataKind.week),
        _q('week.water', 'Su tüketimim nasıl ilerledi?', 'How did my water logging go?', data: GuideDataKind.week),
        _q('week.habit', 'Haftaya hangi alışkanlığı geliştirmeye odaklanabilirim?', 'Which habit could I focus on next week?', data: GuideDataKind.week),
        _q('week.positive', 'Beslenme düzenimde hangi olumlu değişiklikler var?', 'What positive changes show up in my logs?', data: GuideDataKind.week),
      ],
    ),
    _cat(
      'well_living',
      AssistantSection.wellness,
      'Sağlıklı Yaşam ve Genel Sağlık',
      'Healthy living and general health',
      [
        _q('well.habits', 'Sağlıklı yaşam alışkanlıkları nelerdir?', 'What are general healthy-living habits?'),
        _q('well.routine', 'Günlük rutinimi nasıl geliştirebilirim?', 'How can I shape a daily routine?'),
        _q('well.movement', 'Hareketli bir yaşamın genel faydaları nelerdir?', 'What are general benefits of moving regularly?'),
        _q('well.sustain', 'Sağlıklı alışkanlıklar nasıl sürdürülebilir?', 'How can healthy habits stay sustainable?'),
        _q('well.care', 'Günlük yaşamda kendime nasıl daha iyi bakabilirim?', 'How can everyday self-care look?'),
      ],
    ),
    _cat(
      'vitamins',
      AssistantSection.wellness,
      'Vitaminler ve Mineraller',
      'Vitamins and minerals',
      [
        _q('vit.a', 'A vitamini içeren besinler nelerdir?', 'Which foods contain vitamin A?'),
        _q('vit.c', 'C vitamini hangi besinlerde bulunur?', 'Which foods contain vitamin C?'),
        _q('vit.iron', 'Demir içeren yiyecekler nelerdir?', 'Which foods contain iron?'),
        _q('vit.calcium', 'Kalsiyum kaynakları nelerdir?', 'What are calcium sources?'),
        _q('vit.b12', 'B12 vitamini hangi besinlerde bulunur?', 'Which foods contain vitamin B12?'),
        _q('vit.roles', 'Vitamin ve minerallerin vücuttaki genel görevleri nelerdir?', 'What do vitamins and minerals generally do?'),
      ],
    ),
    _cat(
      'digestion',
      AssistantSection.wellness,
      'Sindirim ve Bağırsak Sağlığı',
      'Digestion',
      [
        _q('dig.fiber', 'Lifli besinler neden önemlidir?', 'Why are higher-fiber foods useful?'),
        _q('dig.habits', 'Sindirim sistemini destekleyen genel alışkanlıklar nelerdir?', 'What general habits support digestion?'),
        _q('dig.fermented', 'Fermente gıdalar nelerdir?', 'What are fermented foods?'),
        _q('dig.probiotic', 'Probiyotik ve prebiyotik ne demektir?', 'What do probiotic and prebiotic mean?'),
        _q('dig.meals', 'Düzenli öğün alışkanlığı neden önemlidir?', 'Why can a regular meal pattern matter?'),
        _q('dig.variety', 'Sindirim sağlığı için besin çeşitliliği nasıl artırılabilir?', 'How can food variety support digestion in general?'),
      ],
    ),
    _cat(
      'sleep',
      AssistantSection.wellness,
      'Uyku ve Dinlenme',
      'Sleep and rest',
      [
        _q('sleep.why', 'Düzenli uyku neden önemlidir?', 'Why does regular sleep matter?'),
        _q('sleep.routine', 'Uyku rutinimi nasıl iyileştirebilirim?', 'How can I shape a sleep routine?'),
        _q('sleep.evening', 'Akşam alışkanlıklarım uyku düzenimi nasıl etkileyebilir?', 'How can evening habits relate to sleep?'),
        _q('sleep.energy', 'Uyku ve günlük enerji arasındaki ilişki nedir?', 'How are sleep and daytime energy related?'),
        _q('sleep.rest', 'Dinlenme alışkanlıklarımı nasıl düzenleyebilirim?', 'How can I make room for rest?'),
      ],
    ),
    _cat(
      'energy',
      AssistantSection.wellness,
      'Enerji ve Günlük Zindelik',
      'Energy through the day',
      [
        _q('energy.meals', 'Dengeli beslenme günlük enerjiyi nasıl destekler?', 'How can balanced meals support daytime energy?'),
        _q('energy.pattern', 'Öğün düzeni neden önemlidir?', 'Why does a meal pattern matter for energy?'),
        _q('energy.habits', 'Gün içinde enerjimi korumak için hangi alışkanlıkları geliştirebilirim?', 'Which habits can help energy feel steadier?'),
        _q('energy.water', 'Su tüketimi ile günlük zindelik arasındaki ilişki nedir?', 'How are fluids and daytime alertness related?'),
        _q('energy.balance', 'Dinlenme ve hareket arasında nasıl denge kurabilirim?', 'How can rest and movement share the day?'),
      ],
    ),
    _cat(
      'heart',
      AssistantSection.wellness,
      'Kalp ve Damar Sağlığını Destekleyen Beslenme',
      'Eating patterns and heart health',
      [
        _q('heart.fiber', 'Lif içeren besinler neden önemlidir?', 'Why is fiber part of heart-supporting eating patterns?'),
        _q('heart.fats', 'Doymuş ve doymamış yağlar arasındaki fark nedir?', 'What is the difference between saturated and unsaturated fats?'),
        _q('heart.salt', 'Tuz tüketimi konusunda genel olarak nelere dikkat edilmelidir?', 'What is generally worth noticing about salt?'),
        _q('heart.fish', 'Balık ve bitkisel yağ kaynakları hakkında neler bilmeliyim?', 'What is useful to know about fish and plant oils?'),
        _q('heart.pattern', 'Dengeli beslenme kalp sağlığını genel olarak nasıl destekler?', 'How can an overall eating pattern support heart health in general?'),
      ],
    ),
    _cat(
      'glucose',
      AssistantSection.wellness,
      'Kan Şekeri ve Karbonhidratlar',
      'Blood sugar and carbohydrates',
      [
        _q('glu.role', 'Karbonhidratlar vücutta ne işe yarar?', 'What do carbohydrates do in the body?'),
        _q('glu.fiber_carbs', 'Lifli karbonhidrat kaynakları nelerdir?', 'What are higher-fiber carbohydrate foods?'),
        _q('glu.labels', 'Besin etiketlerindeki şeker miktarı nasıl okunur?', 'How is sugar read on a food label?'),
        _q('glu.variety', 'Öğünlerde besin çeşitliliği neden önemlidir?', 'Why does variety at meals matter?'),
        _q('glu.general', 'Kan şekeriyle ilgili genel beslenme bilgileri nelerdir?', 'What is general nutrition information about blood sugar?'),
      ],
    ),
    _cat(
      'bone',
      AssistantSection.wellness,
      'Kemik ve Kas Sağlığı',
      'Bones and muscles',
      [
        _q('bone.calcium', 'Kalsiyum kaynakları nelerdir?', 'What are calcium sources?'),
        _q('bone.d', 'D vitamini hakkında genel olarak neler bilmeliyim?', 'What is general information about vitamin D?'),
        _q('bone.protein', 'Protein kasların hangi işlevlerinde rol oynar?', 'Where does protein fit in muscle function?'),
        _q('bone.habits', 'Kemik sağlığını destekleyen alışkanlıklar nelerdir?', 'Which general habits support bones?'),
        _q('bone.move', 'Hareket ve kas sağlığı arasındaki ilişki nedir?', 'How are movement and muscles related?'),
      ],
    ),
    _cat(
      'immunity',
      AssistantSection.wellness,
      'Bağışıklık ve Besin Çeşitliliği',
      'Immunity and food variety',
      [
        _q('imm.balance', 'Dengeli beslenme bağışıklık sistemini nasıl destekler?', 'How can overall eating support the immune system?'),
        _q('imm.color', 'Renkli sebze ve meyveler neden tüketilir?', 'Why are colorful vegetables and fruit part of meals?'),
        _q('imm.nutrients', 'Protein, vitamin ve minerallerin genel görevleri nelerdir?', 'What are the general roles of protein, vitamins and minerals?'),
        _q('imm.variety', 'Günlük beslenmemde çeşitliliği nasıl artırabilirim?', 'How can I add variety to the day\'s meals?'),
        _q('imm.habits', 'Bağışıklık için hangi genel yaşam alışkanlıkları önemlidir?', 'Which general habits matter alongside food variety?'),
      ],
    ),
    _cat(
      'emotional',
      AssistantSection.wellness,
      'Stres, Duygusal Yeme ve Beslenme Alışkanlıkları',
      'Stress, emotional eating and habits',
      [
        _q('emo.what', 'Duygusal yeme ne demektir?', 'What does emotional eating mean?'),
        _q('emo.hunger', 'Açlık ve can çekmesi arasındaki fark nasıl anlaşılabilir?', 'How can hunger and a craving feel different?'),
        _q('emo.stress', 'Stresli günlerde öğün düzenimi nasıl koruyabilirim?', 'How can meal rhythm stay in place on stressful days?'),
        _q('emo.observe', 'Yeme alışkanlıklarımı nasıl gözlemleyebilirim?', 'How can I observe eating habits?'),
        _q('emo.kind', 'Kendime karşı daha dengeli bir yaklaşımı nasıl geliştirebilirim?', 'How can I take a steadier approach toward myself?'),
      ],
    ),
    _cat(
      'metabolism',
      AssistantSection.wellness,
      'Metabolizma ve Kilo Hakkında Genel Bilgiler',
      'Metabolism and weight, in general',
      [
        _q('met.what', 'Metabolizma ne demektir?', 'What does metabolism mean?'),
        _q('met.bmr', 'Bazal metabolizma hızı nedir?', 'What is basal metabolic rate?'),
        _q('met.need', 'Günlük enerji ihtiyacı hangi faktörlere bağlıdır?', 'What factors relate to daily energy needs?'),
        _q('met.change', 'Kilo neden zaman içinde değişebilir?', 'Why can weight change over time?'),
        _q('met.muscle', 'Kas kütlesi ve enerji ihtiyacı arasındaki ilişki nedir?', 'How are muscle and energy needs related?'),
        _q('met.habits', 'Kilo yönetiminde sürdürülebilir alışkanlıklar neden önemlidir?', 'Why do sustainable habits matter in weight management?'),
      ],
    ),
    _cat(
      'womens',
      AssistantSection.wellness,
      'Kadın Sağlığı ve Beslenme Hakkında Genel Bilgiler',
      'Women\'s health and nutrition, in general',
      [
        _q('wom.life', 'Kadınların beslenme ihtiyaçları yaşam dönemlerine göre değişebilir mi?', 'Can nutrition needs change across life stages?'),
        _q('wom.cycle', 'Adet döneminde beslenme konusunda hangi genel bilgiler önemlidir?', 'What general nutrition points are discussed around menstruation?'),
        _q('wom.iron', 'Demir içeren besinler nelerdir?', 'Which foods contain iron?'),
        _q('wom.pregnancy', 'Gebelik döneminde beslenme neden profesyonel takip gerektirir?', 'Why does pregnancy nutrition need professional care?'),
        _q('wom.lactation', 'Emzirme döneminde beslenmeyle ilgili genel bilgiler nelerdir?', 'What is general information about eating while breastfeeding?'),
        _q('wom.menopause', 'Menopoz döneminde kemik sağlığı neden önemlidir?', 'Why is bone health discussed around menopause?'),
      ],
    ),
  ];

  static List<AssistantCategory> get nutrition => [
    for (final category in categories)
      if (category.section == AssistantSection.nutrition) category,
  ];

  static List<AssistantCategory> get wellness => [
    for (final category in categories)
      if (category.section == AssistantSection.wellness) category,
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
      final title = '${_stem(category.titleTr)} ${_stem(category.titleEn)}';
      if (title.contains(query)) {
        found.add(category);
        continue;
      }
      final matched = [
        for (final question in category.questions)
          if (_stem(question.tr).contains(query) ||
              _stem(question.en).contains(query))
            question,
      ];
      if (matched.isNotEmpty) {
        found.add(category.copyWith(questions: matched));
      }
    }
    return found;
  }

  /// Tam soru ya da yeterince ayırt edici bir parça.
  static AssistantQuestion? match(String raw) {
    final normalized = _stem(raw);
    if (normalized.isEmpty) return null;
    AssistantQuestion? best;
    var bestScore = 0;
    var bestStemLength = 1 << 30;
    for (final question in questions) {
      for (final prompt in [question.tr, question.en]) {
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
        final closer = score == bestScore && score > 0 && stem.length < bestStemLength;
        if (score > bestScore || closer) {
          best = question;
          bestScore = score;
          bestStemLength = stem.length;
        }
      }
    }
    return bestScore == 0 ? null : best;
  }

  static String _stem(String value) => AssistantText.normalize(
    value,
  ).replaceAll('?', '').replaceAll('!', '').trim();
}

AssistantCategory _cat(
  String id,
  AssistantSection section,
  String titleTr,
  String titleEn,
  List<AssistantQuestion> questions,
) => AssistantCategory(
  id: id,
  section: section,
  titleTr: titleTr,
  titleEn: titleEn,
  questions: questions,
);

AssistantQuestion _q(
  String id,
  String tr,
  String en, {
  AssistantRoute route = AssistantRoute.guide,
  GuideDataKind data = GuideDataKind.none,
  MealType? meal,
}) => AssistantQuestion(
  id: id,
  tr: tr,
  en: en,
  route: route,
  data: data,
  mealType: meal,
);

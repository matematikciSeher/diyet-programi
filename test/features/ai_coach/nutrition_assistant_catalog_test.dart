import 'package:diyet_programi/features/ai_coach/data/assistant_chat_store.dart';
import 'package:diyet_programi/features/ai_coach/data/assistant_reply_codec.dart';
import 'package:diyet_programi/features/ai_coach/domain/catalog/assistant_catalog.dart';
import 'package:diyet_programi/features/ai_coach/domain/content/assistant_guide_library.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_context.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_reply.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_guide_engine.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/mock_nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/premium_nutrition_assistant.dart';
import 'package:diyet_programi/features/meal_plans/data/datasources/meal_template_catalog.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generator.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/nutrition_targets.dart';
import 'package:diyet_programi/shared/models/water_log.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  const targets = NutritionTargets(
    calories: 1850,
    proteinG: 120,
    carbsG: 200,
    fatG: 60,
    waterMl: 2500,
  );
  final wednesday = DateTime(2026, 10, 7, 12);
  late MockNutritionAssistantService assistant;

  setUp(() {
    assistant = MockNutritionAssistantService(
      MealPlanGenerator(MealTemplateCatalog.all),
    );
  });

  AssistantContext loggedDay() => AssistantContext(
    now: wednesday,
    profile: testProfile(allergies: const ['milk'], dislikedFoods: const ['brokoli']),
    targets: targets,
    todayMeals: [
      MealEntry(
        id: 'lunch',
        dayKey: '2026-10-07',
        mealType: MealType.lunch,
        name: 'Izgara tavuk',
        quantityGrams: 200,
        nutrition: const NutritionFacts(calories: 520, proteinG: 45, carbsG: 10, fatG: 18),
        loggedAt: wednesday,
        tags: const {FoodTag.vegetable},
      ),
    ],
    todayWaterMl: 750,
    todayWaterLogCount: 2,
    weekMeals: [
      MealEntry(
        id: 'mon',
        dayKey: '2026-10-05',
        mealType: MealType.dinner,
        name: 'Çorba',
        quantityGrams: 300,
        nutrition: const NutritionFacts(calories: 400),
        loggedAt: DateTime(2026, 10, 5),
      ),
      MealEntry(
        id: 'wed',
        dayKey: '2026-10-07',
        mealType: MealType.lunch,
        name: 'Izgara tavuk',
        quantityGrams: 200,
        nutrition: const NutritionFacts(calories: 520),
        loggedAt: wednesday,
      ),
      MealEntry(
        id: 'old',
        dayKey: '2026-09-28',
        mealType: MealType.breakfast,
        name: 'Eski kayıt',
        quantityGrams: 100,
        nutrition: const NutritionFacts(calories: 900),
        loggedAt: DateTime(2026, 9, 28),
      ),
      MealEntry(
        id: 'future',
        dayKey: '2026-10-09',
        mealType: MealType.dinner,
        name: 'Gelecek',
        quantityGrams: 100,
        nutrition: const NutritionFacts(calories: 700),
        loggedAt: DateTime(2026, 10, 9),
      ),
    ],
    weekWaterLogs: [
      WaterLog(
        id: 'w1',
        dayKey: '2026-10-05',
        amountMl: 500,
        loggedAt: DateTime(2026, 10, 5),
      ),
    ],
    weekPlan: [
      const PlannedMeal(
        id: 'plan-1',
        dayKey: '2026-10-07',
        mealType: MealType.dinner,
        title: 'Mercimek',
        nutrition: NutritionFacts(calories: 450),
      ),
    ],
    knownRecipes: const [
      AssistantKnownRecipe(
        id: 'ok',
        title: 'Nohut yemeği',
        calories: 380,
        proteinG: 18,
      ),
      AssistantKnownRecipe(
        id: 'blocked',
        title: 'Sütlaç',
        calories: 220,
        proteinG: 6,
        suitable: false,
      ),
    ],
    shoppingLines: const [
      AssistantShoppingLine(name: 'Limon', manual: true),
      AssistantShoppingLine(name: 'Pirinç', manual: false),
    ],
  );

  AssistantContext emptyDay() => AssistantContext(
    now: wednesday,
    targets: NutritionTargets.fallback,
  );

  test('elli kategori benzersiz kimlikle ve bilgi kaydıyla durur', () {
    expect(AssistantCatalog.categories, hasLength(50));
    expect(
      AssistantCatalog.categories.map((c) => c.id).toSet(),
      hasLength(50),
    );
    expect(
      AssistantCatalog.inSection(AssistantSection.diet).map((c) => c.titleTr),
      [
        'Sağlıklı ve Dengeli Beslenme',
        'Kilo Verme ve Kilo Yönetimi',
        'Kilo Koruma',
        'Kalori ve Enerji İhtiyacı',
        'Protein Kaynakları',
        'Karbonhidratlar',
        'Sağlıklı Yağlar',
        'Lif ve Bağırsak Sağlığı',
        'Vitaminler ve Mineraller',
        'Porsiyon Kontrolü',
      ],
    );
    expect(
      AssistantCatalog.inSection(AssistantSection.special).map((c) => c.titleTr),
      [
        'Kan Şekeri ve Beslenme',
        'Kolesterol ve Beslenme',
        'Tansiyon ve Beslenme',
        'Kansızlık ve Beslenme',
        'Kadın Sağlığı ve Beslenme',
        'Menopoz Döneminde Beslenme',
        'Gebelikte Beslenme',
        'Çocuklarda Dengeli Beslenme',
        'İleri Yaşta Beslenme',
        'Takviyeler ve Vitamin Kullanımı',
      ],
    );
    expect(AssistantCatalog.questions.length, greaterThanOrEqualTo(160));
    expect(AssistantCatalog.questionById('fact.fiber'), isNotNull);
    expect(AssistantCatalog.questionById('met.what'), isNotNull);
    expect(AssistantCatalog.questionById('wom.pregnancy'), isNotNull);
    expect(AssistantCatalog.questionById('cal.consumed'), isNotNull);
    for (final category in AssistantCatalog.categories) {
      expect(category.questions, isNotEmpty);
      for (final question in category.questions) {
        expect(question.tr.trim(), isNotEmpty);
        expect(question.en.trim(), isNotEmpty);
        if (question.route == AssistantRoute.guide) {
          final copy = AssistantGuideLibrary.of(question.id);
          expect(copy, isNotNull, reason: question.id);
          expect(copy!.tr.direct, isNotEmpty);
          expect(copy.en.direct, isNotEmpty);
          expect(copy.tr.points, isNotEmpty);
          expect(copy.en.tips, isNotEmpty);
        }
      }
    }
  });

  test('arama kategori ve soruyu süzer, boş sonuç döner', () {
    expect(AssistantCatalog.search('   '), AssistantCatalog.categories);
    final breakfast = AssistantCatalog.search('kahvaltı');
    expect(breakfast.map((c) => c.id), contains('breakfast'));
    expect(AssistantCatalog.search('zzzz-no-match'), isEmpty);
    expect(
      AssistantCatalog.match('Bugün kaç kalori aldım?')?.id,
      'cal.consumed',
    );
  });

  test('her katalog sorusu cevap motoruna ulaşır', () async {
    final context = loggedDay();
    for (final question in AssistantCatalog.questions) {
      final reply = await assistant.reply(question.tr, context);
      expect(reply, isNot(isA<HelpReply>()), reason: question.id);
      expect(reply, isNot(isA<UnavailableAssistantReply>()), reason: question.id);
      if (reply is GuideReply) {
        expect(reply.questionId, isNotEmpty);
        expect(AssistantGuideLibrary.of(reply.questionId), isNotNull);
      }
      if (question.route == AssistantRoute.guide) {
        expect(
          const AssistantGuideEngine().reply(question, context).questionId,
          question.id,
        );
      }
    }
  });

  test('günlük kalori gerçek kayda dayanır, kayıt yoksa sayı uydurmaz', () async {
    final logged = await assistant.reply('Bugün kaç kalori aldım?', loggedDay());
    expect(logged, isA<GuideReply>());
    final guide = logged as GuideReply;
    expect(guide.snapshot.consumedCalories, 520);
    expect(guide.snapshot.targetCalories, 1850);
    expect(guide.snapshot.recordsMissing, isFalse);

    final missing = await assistant.reply('Günlük kalori hedefime ne kadar kaldı?', emptyDay());
    expect(missing, isA<GuideReply>());
    final empty = missing as GuideReply;
    expect(empty.snapshot.recordsMissing, isTrue);
    expect(empty.snapshot.consumedCalories, isNull);
    expect(empty.snapshot.targetCalories, isNull);
  });

  test('haftalık özet yalnızca bu haftanın kayıtlı günlerini kullanır', () async {
    final reply = await assistant.reply('Bu hafta beslenmem nasıldı?', loggedDay());
    final guide = reply as GuideReply;
    expect(guide.snapshot.elapsedDays, DateTime.wednesday);
    expect(guide.snapshot.mealDays.map((day) => day.dayKey), ['2026-10-05', '2026-10-07']);
    expect(guide.snapshot.mealDays.map((day) => day.amount), isNot(contains(900)));
    expect(guide.snapshot.mealDays.map((day) => day.amount), isNot(contains(700)));
    expect(guide.snapshot.waterDays.single.dayKey, '2026-10-05');
    expect(guide.snapshot.waterDays.single.amount, 500);
  });

  test('tarif cevabı kayıtlı ve uygun tariflerle sınırlıdır', () async {
    final reply = await assistant.reply(
      'Mevcut tariflerimden hedefime uygun olanları göster.',
      loggedDay(),
    );
    final guide = reply as GuideReply;
    expect(guide.recipes.map((recipe) => recipe.title), ['Nohut yemeği']);
    expect(guide.snapshot.recipeCatalogCount, 2);
    expect(guide.snapshot.recipeMatchCount, 1);
    expect(guide.recipes.map((recipe) => recipe.title), isNot(contains('Sütlaç')));
  });

  test('su ve tercihler kayıtlı veriyi kullanır', () async {
    final water = await assistant.reply('Günlük su hedefime ne kadar kaldı?', loggedDay());
    expect(
      water,
      isA<GuideReply>().having(
        (reply) => reply.snapshot.waterMl,
        'water',
        750,
      ),
    );
    final noWater = await assistant.reply('Günlük su hedefime ne kadar kaldı?', emptyDay());
    expect((noWater as GuideReply).snapshot.recordsMissing, isTrue);
    expect((noWater).snapshot.waterMl, isNull);

    final prefs = await assistant.reply(
      'Alerjilerime ve tercihlerime uygun öğünleri nasıl seçebilirim?',
      loggedDay(),
    );
    final guide = prefs as GuideReply;
    expect(guide.snapshot.allergies, ['milk']);
    expect(guide.snapshot.dislikes, ['brokoli']);
    expect(guide.snapshot.preferencesKnown, isTrue);

    final unknown = await assistant.reply(
      'Alerjilerime ve tercihlerime uygun öğünleri nasıl seçebilirim?',
      emptyDay(),
    );
    expect((unknown as GuideReply).snapshot.preferencesKnown, isFalse);
  });

  test('plan ve alışveriş listesi okunur, değiştirilmez', () async {
    final plan = await assistant.reply(
      'Mevcut haftalık menümdeki öğünleri nasıl değerlendirebilirim?',
      loggedDay(),
    );
    expect((plan as GuideReply).snapshot.planLines.single, contains('Mercimek'));
    final shopping = await assistant.reply(
      'Haftalık menüme göre alışveriş listemi nasıl düzenleyebilirim?',
      loggedDay(),
    );
    final shop = shopping as GuideReply;
    expect(shop.snapshot.shoppingManualNames, ['Limon']);
    expect(shop.snapshot.shoppingFromPlan, 1);
    expect(shop.actions, contains(AssistantAction.openShopping));
  });

  test('sağlık cevapları doz, teşhis veya tedavi talimatı içermez', () {
    final forbidden = RegExp(
      r'\d+\s*mg|hastalığı önler\b|hastalığı tedavi eder|metabolizmayı hızlandır(?!ma)|haftada 5 kilo|ilaç dozunu artır|günde 800',
      caseSensitive: false,
    );
    for (final copy in AssistantGuideLibrary.all.values) {
      final text = [
        copy.tr.direct,
        ...copy.tr.points,
        ...copy.tr.tips,
        copy.en.direct,
        ...copy.en.points,
        ...copy.en.tips,
      ].join('\n');
      expect(text, isNot(matches(forbidden)));
    }
    for (final section in [AssistantSection.digestion, AssistantSection.special]) {
      for (final category in AssistantCatalog.inSection(section)) {
        for (final question in category.questions) {
          expect(question.route, AssistantRoute.guide, reason: question.id);
        }
      }
    }
  });

  test('acil belirti ve aşırı kısıtlama güvenli yanıta gider', () async {
    final context = emptyDay();
    expect(
      await assistant.reply('Şiddetli göğüs ağrım var', context),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('Nefes darlığı yaşıyorum', context),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('Bayılıyorum', context),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('Ani güçsüzlük başladı', context),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('Demir kaç mg almalıyım', context),
      const SafetyReply(SafetyConcern.medical),
    );
    expect(
      await assistant.reply(
        'Kalsiyum kaynakları nelerdir? Göğüs ağrım var',
        context,
      ),
      const SafetyReply(SafetyConcern.emergency),
    );
  });

  test('sohbet kaydı rehber cevabını yeniden yükler ve çevrimdışı çalışır', () async {
    final reply = await assistant.reply('Lif neden önemlidir?', emptyDay());
    final encoded = AssistantReplyCodec.encode(reply);
    final decoded = AssistantReplyCodec.decode(encoded);
    expect(decoded, reply);

    final store = AssistantChatStore(InMemoryDocumentDatabase());
    await store.replaceAll([
      const AssistantTranscript.user('Lif neden önemlidir?'),
      AssistantTranscript.assistant(reply),
    ]);
    final loaded = await store.load();
    expect(loaded, hasLength(2));
    expect((loaded.last.reply as GuideReply).questionId, 'fact.fiber');

    final offline = await assistant.reply('Metabolizma ne demektir?', emptyDay());
    expect(offline, isA<GuideReply>());
    expect((offline as GuideReply).disclaimer, isTrue);
  });

  test('premium olmayan çağrı asistanı çalıştırmaz', () async {
    var calls = 0;
    final gated = PremiumAwareNutritionAssistant(
      inner: _CountingAssistant(() => calls++),
      allowed: () => false,
    );
    final reply = await gated.reply('Lif neden önemlidir?', emptyDay());
    expect(calls, 0);
    expect(
      reply,
      isA<UnavailableAssistantReply>().having(
        (item) => item.code,
        'code',
        AssistantErrorCodes.premiumRequired,
      ),
    );

    final open = PremiumAwareNutritionAssistant(
      inner: assistant,
      allowed: () => true,
    );
    expect(await open.reply('Lif neden önemlidir?', emptyDay()), isA<GuideReply>());
  });
}

class _CountingAssistant implements NutritionAssistantService {
  _CountingAssistant(this.onCall);

  final void Function() onCall;

  @override
  Future<AssistantReply> reply(String question, AssistantContext context) async {
    onCall();
    return const HelpReply();
  }
}

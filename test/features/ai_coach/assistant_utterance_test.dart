import 'package:diyet_programi/core/routing/app_routes.dart';
import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/features/ai_coach/data/assistant_reply_codec.dart';
import 'package:diyet_programi/features/ai_coach/data/repositories/assistant_context_repository_impl.dart';
import 'package:diyet_programi/features/ai_coach/domain/catalog/assistant_catalog.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_context.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_reply.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_phrasing.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_utterance_matcher.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/mock_nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/premium_nutrition_assistant.dart';
import 'package:diyet_programi/features/ai_coach/presentation/assistant_destinations.dart';
import 'package:diyet_programi/features/ai_coach/presentation/pages/ai_coach_page.dart';
import 'package:diyet_programi/features/ai_coach/presentation/providers/assistant_providers.dart';
import 'package:diyet_programi/features/meal_plans/data/datasources/meal_template_catalog.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generator.dart';
import 'package:diyet_programi/features/subscription/domain/models/app_feature.dart';
import 'package:diyet_programi/features/subscription/presentation/widgets/premium_gate.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/nutrition_targets.dart';
import 'package:diyet_programi/shared/repositories/user_profile_repository.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/subscription_overrides.dart';
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
    profile: testProfile(
      allergies: const ['milk'],
      dislikedFoods: const ['brokoli'],
    ),
    targets: targets,
    todayMeals: [
      MealEntry(
        id: 'lunch',
        dayKey: '2026-10-07',
        mealType: MealType.lunch,
        name: 'Izgara tavuk',
        quantityGrams: 200,
        nutrition: const NutritionFacts(
          calories: 520,
          proteinG: 45,
          carbsG: 10,
          fatG: 18,
        ),
        loggedAt: wednesday,
      ),
    ],
    todayWaterMl: 750,
    todayWaterLogCount: 2,
    weekPlan: const [
      PlannedMeal(
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

  test('serbest sorular ilgili konuya eşleşir', () async {
    final context = loggedDay();
    expect(
      await assistant.reply('Bugün çok fazla yedim, ne yapmalıyım?', context),
      isA<OverTargetReply>(),
    );
    expect(
      await assistant.reply('Akşam makarna yedim, şimdi ne yapayım?', context),
      isA<OverTargetReply>(),
    );
    final calories = await assistant.reply('Bugün kaç kalori almışım?', context);
    expect(calories, isA<GuideReply>());
    expect((calories as GuideReply).questionId, 'cal.consumed');
    expect((calories).snapshot.consumedCalories, 520);
    expect(
      await assistant.reply('Kahvaltıda ne yesem?', context),
      isA<MealSuggestionReply>().having(
        (reply) => reply.mealType,
        'meal',
        MealType.breakfast,
      ),
    );
    expect(
      (await assistant.reply('Evde hızlıca ne hazırlayabilirim?', context)
              as GuideReply)
          .questionId,
      'recipe.practical',
    );
    expect(
      (await assistant.reply('Su içmeyi sürekli unutuyorum.', context)
              as GuideReply)
          .questionId,
      'water.remind',
    );
    expect(
      (await assistant.reply('Protein almak için ne yiyebilirim?', context)
              as GuideReply)
          .questionId,
      'macro.protein_foods',
    );
    expect(
      (await assistant.reply('Demir hangi yiyeceklerde var?', context)
              as GuideReply)
          .questionId,
      'vit.iron',
    );
    expect(
      (await assistant.reply('Uyumakta zorlanıyorum.', context) as GuideReply)
          .questionId,
      'sleep.routine',
    );
    expect(
      await assistant.reply('Haftalık menümde bugün ne var?', context),
      isA<PlanStatusReply>().having(
        (reply) => reply.meals.single.title,
        'title',
        'Mercimek',
      ),
    );
    final shopping = await assistant.reply(
      'Alışveriş listemde neler bulunuyor?',
      context,
    );
    expect((shopping as GuideReply).questionId, 'shop.list');
    expect(shopping.snapshot.shoppingManualNames, ['Limon']);
    expect(
      await assistant.reply('Bugünkü beslenmem nasıl?', context),
      isA<DailyNutritionReply>().having(
        (reply) => reply.consumedCalories,
        'calories',
        520,
      ),
    );
    expect(
      (await assistant.reply(
                'Tatlı yemek istiyorum, alternatif önerir misin?',
                context,
              )
              as GuideReply)
          .questionId,
      'snack.sweet',
    );
  });

  test('Türkçe karakter ve günlük konuşma aynı konuya iner', () {
    expect(
      AssistantPhrasing.prepared('BUGÜN KAÇ KALORİ ALMIŞIM?'),
      'bugun kac kalori almisim',
    );
    expect(
      AssistantUtteranceMatcher.resolve('BUGÜN KAÇ KALORİ ALMIŞIM?'),
      isA<UtteranceQuestion>().having((item) => item.id, 'id', 'cal.consumed'),
    );
    expect(
      AssistantUtteranceMatcher.resolve('bugun kac kalori almisim'),
      isA<UtteranceQuestion>().having((item) => item.id, 'id', 'cal.consumed'),
    );
    expect(
      AssistantUtteranceMatcher.resolve('Kahvaltida ne yesem?'),
      isA<UtteranceIntent>().having(
        (item) => item.intent,
        'intent',
        AssistantIntent.mealSuggestion,
      ),
    );
    expect(
      AssistantUtteranceMatcher.resolve('su icmeyi surekli unutuyorum'),
      isA<UtteranceQuestion>().having((item) => item.id, 'id', 'water.remind'),
    );
  });

  test('benzer kelimeler ilgisiz soruyu yanlış konuya götürmez', () async {
    final context = emptyDay();
    for (final question in [
      'Kalorifer çalışmıyor',
      'Yağmur yağıyor, şemsiye lazım',
      'Susam ezmesi aldım',
      'Bugün kaç kilometre yürüdüm?',
    ]) {
      expect(
        await assistant.reply(question, context),
        isA<HelpReply>(),
        reason: question,
      );
    }
  });

  test('birden fazla uygun konuda seçenek sunulur ve bağlam daraltır', () async {
    final context = emptyDay();
    final calcium = await assistant.reply('Kalsiyum kaynakları nelerdir?', context);
    expect(calcium, isA<ClarificationReply>());
    expect(
      (calcium as ClarificationReply).choices.map((choice) => choice.questionId),
      containsAll(['vit.calcium', 'bone.calcium']),
    );

    final tired = await assistant.reply('Son zamanlarda sürekli yorgunum.', context);
    expect(
      (tired as ClarificationReply).choices.map((choice) => choice.questionId),
      containsAll(['energy.habits', 'sleep.energy', 'well.care']),
    );

    final weight = await assistant.reply('Kilo vermek istiyorum', context);
    expect(
      (weight as ClarificationReply).choices.map((choice) => choice.questionId),
      containsAll(['weight.habits', 'cal.track']),
    );
    expect(weight.choices.length, lessThanOrEqualTo(3));
    for (final choice in weight.choices) {
      final category = AssistantCatalog.categoryOf(choice.questionId!);
      expect(category, isNotNull);
      expect(choice.labelTr, category!.titleTr);
      expect(choice.promptTr, isNotEmpty);
    }

    final narrowed = await assistant.reply(
      'Yorgunum',
      context.withDialogue(priorUserQuestion: 'Uyumakta zorlanıyorum.'),
    );
    expect((narrowed as GuideReply).questionId, 'sleep.energy');

    final fromCalories = await assistant.reply(
      'Kilo vermek istiyorum',
      context.withDialogue(priorUserQuestion: 'Bugün kaç kalori almışım?'),
    );
    expect((fromCalories as GuideReply).questionId, 'cal.track');

    final pinned = await assistant.reply(
      'Kalsiyum kaynakları nelerdir?',
      context.withDialogue(pinnedQuestionId: 'bone.calcium'),
    );
    expect((pinned as GuideReply).questionId, 'bone.calcium');
    expect(
      AssistantCatalog.categoryOf(pinned.questionId)?.id,
      'bone',
    );
  });

  test('konu değişince önceki niyet taşınmaz', () async {
    final context = emptyDay();
    final breakfast = await assistant.reply(
      'Kahvaltıda ne yesem?',
      context.withDialogue(priorUserQuestion: 'Uyumakta zorlanıyorum.'),
    );
    expect(breakfast, isA<MealSuggestionReply>());
    expect((breakfast as MealSuggestionReply).mealType, MealType.breakfast);

    final water = await assistant.reply(
      'Su içmeyi sürekli unutuyorum.',
      context.withDialogue(priorUserQuestion: 'Bugün kaç kalori almışım?'),
    );
    expect((water as GuideReply).questionId, 'water.remind');

    final stillTired = await assistant.reply(
      'Yorgunum',
      context.withDialogue(priorUserQuestion: 'Su içmeyi sürekli unutuyorum.'),
    );
    expect(stillTired, isA<ClarificationReply>());
    expect(
      (stillTired as ClarificationReply).choices.map((choice) => choice.questionId),
      containsAll(['energy.habits', 'sleep.energy', 'well.care']),
    );
  });

  test('noktalama ve yazım farkı uydurma cevaba düşmez', () async {
    final context = emptyDay();
    expect(
      (await assistant.reply('Bugün, kaç kalori almışım!!!', context) as GuideReply)
          .questionId,
      'cal.consumed',
    );
    expect(
      (await assistant.reply('bugun kac kalori almisim', context) as GuideReply)
          .questionId,
      'cal.consumed',
    );
    expect(await assistant.reply('protien aldim', context), isA<HelpReply>());
    expect(
      await assistant.reply('kahvalti da ne yeseem', context),
      isA<HelpReply>(),
    );
    expect(await assistant.reply('asdfqwer', context), isA<HelpReply>());
  });

  test('belirsiz soru açıklama ister, uydurma cevap vermez', () async {
    expect(
      await assistant.reply('ne yapayım', emptyDay()),
      isA<DetailRequestReply>(),
    );
    expect(
      await assistant.reply('merhaba', emptyDay()),
      isA<DetailRequestReply>(),
    );
  });

  test('kalori cevabı gerçek kaydı kullanır, eksikte sayı uydurmaz', () async {
    final logged = await assistant.reply('Bugün kaç kalori almışım?', loggedDay());
    final guide = logged as GuideReply;
    expect(guide.snapshot.consumedCalories, 520);
    expect(guide.snapshot.targetCalories, 1850);
    expect(guide.snapshot.recordsMissing, isFalse);

    final missing = await assistant.reply('Bugün kaç kalori almışım?', emptyDay());
    final empty = missing as GuideReply;
    expect(empty.snapshot.recordsMissing, isTrue);
    expect(empty.snapshot.consumedCalories, isNull);
    expect(empty.snapshot.targetCalories, isNull);

    final noTarget = await assistant.reply(
      'Bugün kaç kalori almışım?',
      AssistantContext(
        now: wednesday,
        targets: NutritionTargets.fallback,
        todayMeals: [
          MealEntry(
            id: 'snack',
            dayKey: '2026-10-07',
            mealType: MealType.snack,
            name: 'Elma',
            quantityGrams: 100,
            nutrition: const NutritionFacts(calories: 80),
            loggedAt: wednesday,
          ),
        ],
      ),
    );
    final partial = noTarget as GuideReply;
    expect(partial.snapshot.consumedCalories, 80);
    expect(partial.snapshot.personalTarget, isFalse);
    expect(partial.snapshot.targetCalories, isNull);
  });

  test('alerji ve sevilmeyen yiyecek serbest soruda da korunur', () async {
    final context = loggedDay();
    final prefs = await assistant.reply(
      'Alerjilerime uygun ne yiyebilirim?',
      context,
    );
    final guide = prefs as GuideReply;
    expect(guide.questionId, 'pref.choose');
    expect(guide.snapshot.allergies, ['milk']);
    expect(guide.snapshot.dislikes, ['brokoli']);

    final recipes = await assistant.reply(
      'Evde hızlıca ne hazırlayabilirim?',
      context,
    );
    expect(
      (recipes as GuideReply).recipes.map((recipe) => recipe.title),
      ['Nohut yemeği'],
    );

    final breakfast = await assistant.reply('Kahvaltıda ne yesem?', context);
    final suggestion = breakfast as MealSuggestionReply;
    for (final meal in suggestion.suggestions) {
      final title = meal.title.toLowerCase();
      expect(title, isNot(contains('süt')));
      expect(title, isNot(contains('brokoli')));
    }
  });

  test('sağlık güvenliği serbest metinde eşleştirmeden önce çalışır', () async {
    final context = emptyDay();
    expect(
      await assistant.reply('Kahvaltıda ne yesem? Göğüs ağrım var', context),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('Demir hangi yiyeceklerde var? Kaç mg almalıyım', context),
      const SafetyReply(SafetyConcern.medical),
    );
    expect(
      await assistant.reply('Nefes darlığı yaşıyorum, tatlı öner', context),
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
  });

  test('yönlendirme yalnızca kayıtlı ekranlara gider', () {
    expect(AssistantDestinations.knownRoute('/olmayan-sayfa'), isNull);
    expect(AssistantDestinations.visible(const []), isEmpty);
    for (final action in AssistantAction.values) {
      final route = AssistantDestinations.routeOf(action);
      expect(route, isNotNull);
      expect(AssistantDestinations.realPaths, contains(route));
      expect(route, isNot('/olmayan-sayfa'));
    }
    expect(AssistantDestinations.routeOf(AssistantAction.openDiary), AppRoutes.diary);
    expect(AssistantDestinations.routeOf(AssistantAction.openWater), AppRoutes.water);
    expect(
      AssistantDestinations.routeOf(AssistantAction.openPlan),
      AppRoutes.nutritionPlan,
    );
    expect(
      AssistantDestinations.routeOf(AssistantAction.openRecipes),
      AppRoutes.recipes,
    );
    expect(
      AssistantDestinations.routeOf(AssistantAction.openShopping),
      AppRoutes.shoppingList,
    );
  });

  test('seçenek ve eksik kayıt cevapları sohbet kaydında durur', () async {
    final reply = await assistant.reply('Kalsiyum kaynakları nelerdir?', emptyDay());
    final restored = AssistantReplyCodec.decode(AssistantReplyCodec.encode(reply));
    expect(restored, reply);
    final detail = const DetailRequestReply();
    expect(AssistantReplyCodec.decode(AssistantReplyCodec.encode(detail)), detail);
  });

  test('premium kapalıyken motor çalışmaz, test üyeliğinde cevap gelir', () async {
    var calls = 0;
    final gated = PremiumAwareNutritionAssistant(
      inner: _CountingAssistant(() => calls++),
      allowed: () => false,
    );
    final blocked = await gated.reply('Bugün kaç kalori almışım?', emptyDay());
    expect(calls, 0);
    expect(
      blocked,
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
    expect(
      await open.reply('Lif neden önemlidir?', emptyDay()),
      isA<GuideReply>(),
    );
  });

  test('cevap motoru çevrimdışı yerel katalogla çalışır', () async {
    final reply = await assistant.reply('Metabolizma ne demektir?', emptyDay());
    expect(reply, isA<GuideReply>());
    expect((reply as GuideReply).questionId, 'met.what');
    expect(
      await assistant.reply('bugun kac kalori almisim', emptyDay()),
      isA<GuideReply>(),
    );
  });

  test('katalogdaki 160 soru cevaplanmaya devam eder', () async {
    expect(AssistantCatalog.questions.length, greaterThanOrEqualTo(160));
    final context = loggedDay();
    for (final question in AssistantCatalog.questions) {
      final reply = await assistant.reply(question.tr, context);
      expect(reply, isNot(isA<HelpReply>()), reason: question.id);
      expect(reply, isNot(isA<DetailRequestReply>()), reason: question.id);
      expect(reply, isNot(isA<UnavailableAssistantReply>()), reason: question.id);
      expect(reply, isNot(isA<SafetyReply>()), reason: question.id);
      if (reply is GuideReply) {
        expect(reply.questionId, question.id, reason: question.id);
        expect(
          AssistantCatalog.categoryOf(reply.questionId)?.id,
          AssistantCatalog.categoryOf(question.id)?.id,
          reason: question.id,
        );
      }
    }
  });

  test('önceki mesaj ve sohbet, yönlendirme sonrası durur', () async {
    final db = InMemoryDocumentDatabase();
    final recorder = _RecordingAssistant();
    final container = ProviderContainer(
      overrides: [
        premiumOverride,
        localDocumentDatabaseProvider.overrideWithValue(db),
        nutritionAssistantServiceProvider.overrideWithValue(recorder),
        assistantContextRepositoryProvider.overrideWithValue(_EmptyContext()),
      ],
    );
    addTearDown(() {
      container.dispose();
      db.dispose();
    });
    container.listen(subscriptionStatusProvider, (_, _) {});
    await container.read(subscriptionStatusProvider.future);
    final notifier = container.read(assistantChatProvider.notifier);
    await notifier.ready;
    await notifier.send('Uyumakta zorlanıyorum.');
    await notifier.send('Yorgunum');
    expect(recorder.calls, 2);
    expect(recorder.lastPrior, 'Uyumakta zorlanıyorum.');
    expect(container.read(assistantChatProvider).messages, hasLength(4));
  });

  testWidgets('su eylemi su ekranına gider ve sohbet durur', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: AppRoutes.aiCoach,
      routes: [
        GoRoute(
          path: AppRoutes.aiCoach,
          builder: (_, _) => const PremiumGate(
            feature: AppFeature.aiCoach,
            child: AiCoachPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.water,
          builder: (_, _) => Scaffold(
            appBar: AppBar(title: const Text('water-screen')),
            body: const Text('water-body'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumOverride,
          keyValueStorageProvider.overrideWithValue(InMemoryKeyValueStorage()),
          localDocumentDatabaseProvider.overrideWithValue(
            InMemoryDocumentDatabase(),
          ),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          assistantContextRepositoryProvider.overrideWithValue(_EmptyContext()),
          nutritionAssistantServiceProvider.overrideWithValue(
            MockNutritionAssistantService(
              MealPlanGenerator(MealTemplateCatalog.all),
            ),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('assistant-search')), 'Su Tüketimi');
    await tester.pump();
    expect(find.byKey(const ValueKey('assistant-category-water')), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-question-water.today')), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-question-cal.consumed')), findsNothing);

    final water = find.byKey(const ValueKey('assistant-question-water.today'));
    await tester.ensureVisible(water);
    await tester.tap(water);
    await tester.pumpAndSettle();
    expect(find.text('Bugün ne kadar su içtim?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assistant-action-openWater')));
    await tester.pumpAndSettle();
    expect(find.text('water-screen'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Bugün ne kadar su içtim?'), findsOneWidget);
    expect(find.text('water-screen'), findsNothing);
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

class _RecordingAssistant implements NutritionAssistantService {
  int calls = 0;
  String? lastPrior;

  @override
  Future<AssistantReply> reply(String question, AssistantContext context) async {
    calls++;
    lastPrior = context.priorUserQuestion;
    return const HelpReply();
  }
}

class _EmptyContext implements AssistantContextRepository {
  @override
  Future<AssistantContext> snapshot() async => AssistantContext(
    now: testNow,
    targets: NutritionTargets.fallback,
  );
}

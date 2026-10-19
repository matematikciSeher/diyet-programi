import 'dart:async';

import 'package:diyet_programi/features/ai_coach/data/assistant_category_store.dart';
import 'package:diyet_programi/features/ai_coach/domain/catalog/assistant_catalog.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_context.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_reply.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_phrasing.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_safety.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/mock_nutrition_assistant_service.dart';
import 'package:diyet_programi/features/meal_plans/data/datasources/meal_template_catalog.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generator.dart';
import 'package:diyet_programi/features/subscription/domain/models/app_feature.dart';
import 'package:diyet_programi/features/subscription/domain/premium_access.dart';
import 'package:diyet_programi/features/subscription/presentation/providers/premium_providers.dart';
import 'package:diyet_programi/shared/models/nutrition_targets.dart';
import 'package:diyet_programi/shared/models/subscription_status.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/subscription_overrides.dart';

void main() {
  late MockNutritionAssistantService assistant;

  setUp(() {
    assistant = MockNutritionAssistantService(
      MealPlanGenerator(MealTemplateCatalog.all),
    );
  });

  AssistantContext context({String? categoryId, String? prior}) => AssistantContext(
    now: DateTime(2026, 10, 7),
    targets: NutritionTargets.fallback,
    categoryId: categoryId,
    priorUserQuestion: prior,
  );

  test('ek soru cümleleri ve yeni kayıtlar aynı yerel motora bağlanır', () async {
    expect(AssistantCatalog.categories, hasLength(50));
    expect(AssistantCatalog.questions.length, greaterThanOrEqualTo(220));
    final phrases = [
      for (final question in AssistantCatalog.questions) ...question.phrases,
    ];
    expect(phrases.length, greaterThanOrEqualTo(40));

    final processed = await assistant.reply(
      'İşlenmiş gıdalar neden tek grup değildir?',
      context(),
    );
    expect((processed as GuideReply).questionId, 'fact.processed');

    final grain = await assistant.reply('Tam tahıllı ekmek ne demek?', context());
    expect((grain as GuideReply).questionId, 'carb.wholegrain');

    final plate = await assistant.reply(
      'Tabağımı sebze protein ve tahılla nasıl kurarım?',
      context(),
    );
    expect((plate as GuideReply).questionId, 'main.plate');

    final multi = await assistant.reply(
      'Multivitamin almak zorunda mıyım?',
      context(),
    );
    expect((multi as GuideReply).questionId, 'supp.multi');
  });

  test('hazır soru kendi cümlesiyle yazılınca o kaydın cevabı gelir', () async {
    final fiber = await assistant.reply('Lif niye bu kadar önemli?', context());
    expect((fiber as GuideReply).questionId, 'fact.fiber');

    final plate = await assistant.reply('Dengeli tabak nasıl kurulur?', context());
    expect((plate as GuideReply).questionId, 'main.plate');

    final typed = await assistant.reply(
      'İşlenmiş gıda günlük dilde ne anlama gelir?',
      context(),
    );
    expect((typed as GuideReply).questionId, 'fact.processed');

    expect(await assistant.reply('Kalorifer çalışmıyor', context()), isA<HelpReply>());
    expect(
      await assistant.reply('Bugün kaç kilometre yürüdüm?', context()),
      isA<HelpReply>(),
    );
  });

  test('kategori araması Türkçe karakteri ve kısa sorguyu ayırır', () {
    expect(
      AssistantCatalog.search('kahvalti').map((c) => c.id),
      contains('breakfast'),
    );
    expect(AssistantCatalog.search('su').map((c) => c.id), contains('water'));
    expect(
      AssistantCatalog.search('su').map((c) => c.id),
      isNot(contains('sustainable')),
    );
    expect(AssistantPhrasing.prepared('Şişkinlik'), 'siskinlik');
  });

  test('farklı tatlı cümleleri aynı konuya, bilinmeyen soru kapsama düşer', () async {
    final evening = await assistant.reply('Akşamları neden tatlı istiyorum?', context());
    final night = await assistant.reply(
      'Gece kendimi tatlı yemekten alamıyorum.',
      context(),
    );
    final sugar = await assistant.reply('Şeker isteğimi nasıl azaltabilirim?', context());
    expect(evening, isA<GuideReply>());
    expect((evening as GuideReply).questionId, 'sweet.evening');
    expect(night, isA<GuideReply>());
    expect((night as GuideReply).questionId, 'sweet.evening');
    expect((sugar as GuideReply).questionId, 'sweet.reduce');

    final unknown = await assistant.reply('Mars kolonisinde menü nasıl olur?', context());
    expect(unknown, isA<HelpReply>());
  });

  test('takip sorusu önceki lif konusunu kahvaltıya bağlar, belirsizde sorar', () async {
    final first = await assistant.reply('Lifli besinler nelerdir?', context());
    expect((first as GuideReply).questionId, 'shop.fiber');

    final follow = await assistant.reply(
      'Peki kahvaltıda hangilerini tüketebilirim?',
      context(prior: 'Lifli besinler nelerdir?', categoryId: 'fiber'),
    );
    expect((follow as GuideReply).questionId, 'fiber.breakfast');

    final vague = await assistant.reply('Peki?', context(prior: 'Lifli besinler nelerdir?'));
    expect(vague, isA<DetailRequestReply>());
  });

  test('seçili kategori zayıf kalsiyum eşleşmesini kendi kaydına çeker', () async {
    final inVitamins = await assistant.reply(
      'Kalsiyum kaynakları nelerdir?',
      context(categoryId: 'vitamins'),
    );
    expect((inVitamins as GuideReply).questionId, 'vit.calcium');

    final inBone = await assistant.reply(
      'Kalsiyum kaynakları nelerdir?',
      context(categoryId: 'bone'),
    );
    expect((inBone as GuideReply).questionId, 'bone.calcium');

    final elsewhere = await assistant.reply(
      'Kabızlık için lif ve su ne işe yarar?',
      context(categoryId: 'sweets'),
    );
    expect((elsewhere as GuideReply).questionId, 'constip.habits');
  });

  test('güvenlik filtresi doz, acil, gebelik ve çocuk sorularını ayırır', () async {
    final base = context();
    expect(
      await assistant.reply('Demir ilacimin dozunu artir', base),
      const SafetyReply(SafetyConcern.medical),
    );
    expect(
      await assistant.reply('Bu mucize diyet kanseri yener mi?', base),
      const SafetyReply(SafetyConcern.medical),
    );
    expect(
      await assistant.reply('Anafilaksi geciriyorum', base),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('Cocugum ateslendi ne yapayim', base),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('kan sekerim yuksek, ne yiyeyim', base),
      const SafetyReply(SafetyConcern.medical),
    );

    final pregnancy = await assistant.reply(
      'Gebelikte nelere dikkat etmeliyim?',
      base,
    );
    expect((pregnancy as GuideReply).questionId, 'wom.pregnancy');

    final child = await assistant.reply(
      'Cocuklarda dengeli beslenme nasil olur?',
      base,
    );
    expect((child as GuideReply).questionId, 'child.balance');

    final supplement = await assistant.reply(
      'Takviye herkes icin gerekli mi?',
      base,
    );
    expect((supplement as GuideReply).questionId, 'supp.general');
    expect(
      AssistantSafety.check(AssistantPhrasing.prepared('Gebelikte nelere dikkat etmeliyim?')),
      isNull,
    );
  });

  test('kategori kimlikleri yeniden yazılınca çoğalmaz ve çevrimdışı cevap durur', () async {
    final db = InMemoryDocumentDatabase();
    addTearDown(db.dispose);
    final store = AssistantCategoryStore(db);
    expect(await store.ensureSeeded(), 50);
    expect(await store.ensureSeeded(), 50);
    final docs = await db.getCollection(AssistantCategoryStore.collection);
    expect(docs.map((doc) => doc.id).toSet(), hasLength(50));

    final offline = await assistant.reply('Metabolizma ne demektir?', context());
    expect(offline, isA<GuideReply>());
    expect((offline as GuideReply).questionId, 'met.what');
  });

  test('yüklenirken son üyelik durur, premium reklamı kapatır', () async {
    final updates = StreamController<SubscriptionStatus>();
    addTearDown(updates.close);
    final container = ProviderContainer(
      overrides: [
        subscriptionStatusProvider.overrideWith((ref) => updates.stream),
      ],
    );
    addTearDown(container.dispose);
    container.listen(subscriptionStatusProvider, (_, _) {});
    updates.add(premiumStatus);
    await container.read(subscriptionStatusProvider.future);

    expect(container.read(subscriptionStatusProvider).isLoading, isFalse);
    expect(container.read(featureAccessProvider(AppFeature.aiCoach)), isTrue);
    expect(container.read(showAdsProvider), isFalse);
    expect(
      canAccessFeature(
        container.read(subscriptionStatusProvider).value,
        AppFeature.adFree,
      ),
      isTrue,
    );

    updates.add(premiumStatus);
    await pumpEventQueue();
    expect(container.read(featureAccessProvider(AppFeature.aiCoach)), isTrue);
    expect(container.read(showAdsProvider), isFalse);
    expect(canAccessFeature(null, AppFeature.aiCoach), isFalse);
  });
}

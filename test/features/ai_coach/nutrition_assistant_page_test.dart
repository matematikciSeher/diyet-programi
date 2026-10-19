import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/features/ai_coach/data/repositories/assistant_context_repository_impl.dart';
import 'package:diyet_programi/features/ai_coach/domain/catalog/assistant_catalog.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_context.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/mock_nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/presentation/pages/ai_coach_page.dart';
import 'package:diyet_programi/features/ai_coach/presentation/providers/assistant_providers.dart';
import 'package:diyet_programi/features/meal_plans/data/datasources/meal_template_catalog.dart';
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

import '../../helpers/subscription_overrides.dart';
import '../../helpers/test_profile.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  Future<void> scrollCatalogTo(WidgetTester tester, Finder target) async {
    final list = find.byKey(const ValueKey('assistant-catalog'));
    for (var attempt = 0; attempt < 50 && target.evaluate().isEmpty; attempt++) {
      await tester.drag(list, const Offset(0, -700));
      await tester.pump();
    }
    expect(target, findsWidgets);
  }

  Future<void> scrollCatalogToTop(WidgetTester tester) async {
    final list = tester.widget<ListView>(find.byKey(const ValueKey('assistant-catalog')));
    list.controller!.jumpTo(0);
    await tester.pump();
  }

  Widget app({required bool premium, Widget? home, Locale locale = const Locale('tr')}) {
    return ProviderScope(
      overrides: [
        if (premium) premiumOverride,
        keyValueStorageProvider.overrideWithValue(InMemoryKeyValueStorage()),
        localDocumentDatabaseProvider.overrideWithValue(InMemoryDocumentDatabase()),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        assistantContextRepositoryProvider.overrideWithValue(_Context()),
        nutritionAssistantServiceProvider.overrideWithValue(
          MockNutritionAssistantService(MealPlanGenerator(MealTemplateCatalog.all)),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: home ??
            const PremiumGate(
              feature: AppFeature.aiCoach,
              child: AiCoachPage(),
            ),
      ),
    );
  }

  testWidgets('premium kapalıyken asistan içeriği açılmaz', (tester) async {
    await tester.pumpWidget(app(premium: false));
    await tester.pumpAndSettle();

    expect(find.byType(PremiumLockedPage), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-welcome')), findsNothing);
    expect(find.text(l10n.assistantWelcome), findsNothing);
  });

  testWidgets('test üyeliği kategorileri, aramayı ve kalori cevabını açar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 6400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(premium: true));
    await tester.pumpAndSettle();

    expect(find.text(l10n.assistantWelcome), findsOneWidget);
    expect(find.text(l10n.assistantSectionDiet), findsOneWidget);
    expect(find.text(l10n.assistantSuggestedTitle), findsNothing);
    expect(find.byKey(const ValueKey('assistant-input')), findsOneWidget);
    expect(find.text(l10n.assistantSend), findsOneWidget);

    var sawSpecial = false;
    for (final category in AssistantCatalog.categories) {
      expect(category.questions, isNotEmpty);
      final title = find.byKey(ValueKey('assistant-category-${category.id}'));
      final question = find.byKey(
        ValueKey('assistant-question-${category.questions.first.id}'),
      );
      await scrollCatalogTo(tester, question);
      expect(title, findsOneWidget);
      expect(question, findsOneWidget);
      if (category.section == AssistantSection.special) sawSpecial = true;
    }
    expect(sawSpecial, isTrue);

    await scrollCatalogToTop(tester);
    await tester.enterText(find.byKey(const ValueKey('assistant-search')), 'zzzz');
    await tester.pump();
    expect(find.byKey(const ValueKey('assistant-search-empty')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('assistant-search')), 'kahvalti');
    await tester.pump();
    await scrollCatalogTo(
      tester,
      find.byKey(const ValueKey('assistant-category-breakfast')),
    );

    await tester.enterText(find.byKey(const ValueKey('assistant-search')), '');
    await tester.pump();

    final calories = find.byKey(const ValueKey('assistant-question-cal.consumed'));
    await scrollCatalogTo(tester, calories);
    await tester.tap(calories);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('assistant-chat-category')), findsOneWidget);
    expect(find.text('Kalori ve Enerji İhtiyacı'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-input')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('assistant-input')),
      'Bugün kaç kalori aldım?',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();
    expect(find.text('Bugün kaç kalori aldım?'), findsWidgets);
    expect(find.textContaining('520'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dar ekranda premium kapısı taşmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(premium: false));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumLockedPage), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-welcome')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dar ekranda kategori sohbeti ve seçenekler taşmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(premium: true));
    await tester.pumpAndSettle();
    expect(find.text(l10n.assistantSuggestedTitle), findsNothing);
    expect(find.bySemanticsLabel(l10n.assistantSearchHint), findsWidgets);
    expect(tester.takeException(), isNull);

    final calcium = find.byKey(const ValueKey('assistant-question-vit.calcium'));
    await scrollCatalogTo(tester, calcium);
    await tester.tap(calcium);
    await tester.pumpAndSettle();
    expect(find.text('Kalsiyum kaynakları nelerdir?'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-choice-bone.calcium')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('İngilizce karşılama ve boş arama görünür', (tester) async {
    final english = lookupAppLocalizations(const Locale('en'));
    tester.view.physicalSize = const Size(360, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(premium: true, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text(english.assistantWelcome), findsOneWidget);
    expect(find.text(english.assistantSectionDiet), findsWidgets);
    await scrollCatalogTo(tester, find.text(english.assistantSectionFoods));
    expect(find.text(english.assistantSectionFoods), findsWidgets);
    expect(find.byType(PremiumLockedPage), findsNothing);

    await scrollCatalogToTop(tester);
    await tester.enterText(find.byKey(const ValueKey('assistant-search')), 'zzzz');
    await tester.pump();
    expect(find.text(english.assistantSearchEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Context implements AssistantContextRepository {
  @override
  Future<AssistantContext> snapshot() async => AssistantContext(
    now: testNow,
    profile: testProfile(),
    targets: const NutritionTargets(
      calories: 1850,
      proteinG: 120,
      carbsG: 200,
      fatG: 60,
      waterMl: 2500,
    ),
    todayMeals: [
      MealEntry(
        id: 'lunch',
        dayKey: '2026-09-28',
        mealType: MealType.lunch,
        name: 'Izgara tavuk',
        quantityGrams: 200,
        nutrition: const NutritionFacts(calories: 520, proteinG: 40),
        loggedAt: testNow,
      ),
    ],
  );
}

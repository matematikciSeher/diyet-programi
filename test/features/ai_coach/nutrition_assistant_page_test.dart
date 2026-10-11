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

  Widget app({required bool premium, Widget? home}) {
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
        locale: const Locale('tr'),
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
    expect(find.text(l10n.assistantNutritionSection), findsOneWidget);
    expect(find.text(l10n.assistantWellnessSection), findsOneWidget);

    for (final category in AssistantCatalog.categories) {
      expect(find.text(category.titleTr), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('assistant-category-${category.id}')));
      await tester.pump();
      for (final question in category.questions) {
        expect(
          find.byKey(ValueKey('assistant-question-${question.id}')),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(ValueKey('assistant-category-${category.id}')));
      await tester.pump();
    }

    await tester.enterText(find.byKey(const ValueKey('assistant-search')), 'zzzz');
    await tester.pump();
    expect(find.byKey(const ValueKey('assistant-search-empty')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('assistant-search')), '');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('assistant-category-calories')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assistant-question-cal.consumed')));
    await tester.pumpAndSettle();

    expect(find.textContaining('520'), findsWidgets);
    expect(find.text('Bugün kaç kalori aldım?'), findsOneWidget);
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

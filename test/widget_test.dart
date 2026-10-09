import 'dart:convert';

import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/authentication/presentation/pages/sign_in_page.dart';
import 'package:diyet_programi/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:diyet_programi/features/dashboard/presentation/widgets/calorie_summary_card.dart';
import 'package:diyet_programi/features/onboarding/domain/models/onboarding_draft.dart';
import 'package:diyet_programi/features/onboarding/domain/models/onboarding_step.dart';
import 'package:diyet_programi/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:diyet_programi/features/onboarding/presentation/widgets/summary_step.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

Widget _app(InMemoryKeyValueStorage storage) => ProviderScope(
  overrides: [
    keyValueStorageProvider.overrideWithValue(storage),
    splashMinDurationProvider.overrideWithValue(Duration.zero),
    clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 9)),
  ],
  child: const App(),
);

void _setSurface(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _primary = find.byKey(const ValueKey('onboarding-primary'));

Future<void> _next(WidgetTester tester) async {
  await tester.tap(_primary);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  await _next(tester);
}

Future<void> _type(WidgetTester tester, String value) async {
  await tester.enterText(find.byType(TextField), value);
  await tester.pump();
  await _next(tester);
}

void main() {
  testWidgets('onboarding akışı tamamlanınca dashboard açılır', (tester) async {
    _setSurface(tester, const Size(390, 844));
    final storage = InMemoryKeyValueStorage();
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);

    await _next(tester);
    expect(find.text(l10n.onboardingBenefitPlanTitle), findsOneWidget);
    await _next(tester);
    await _next(tester);
    await _next(tester);

    // İsim (isteğe bağlı)
    expect(find.text(l10n.qNameTitle), findsOneWidget);
    await _type(tester, 'Ayşe');

    await _choose(tester, l10n.goalLoseWeight);
    await _choose(tester, l10n.genderFemale);

    // Yaş: boş ve aralık dışı değerler engellenir.
    expect(find.text(l10n.qAgeTitle), findsOneWidget);
    await _next(tester);
    expect(find.text(l10n.errorValueRequired), findsOneWidget);
    await tester.enterText(find.byType(TextField), '10');
    await tester.pump();
    expect(find.text(l10n.errorOutOfRange('16', '100')), findsOneWidget);
    await _type(tester, '30');

    await _type(tester, '165');
    await _type(tester, '70');

    // Hedef kilo: mevcut kilodan yüksek olamaz.
    expect(find.text(l10n.qTargetWeightTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), '75');
    await _next(tester);
    expect(find.text(l10n.errorTargetBelowCurrent), findsOneWidget);
    await _type(tester, '62');

    await _choose(tester, l10n.activityModerate);
    await _choose(tester, l10n.exerciseThreeToFour);
    await _choose(tester, l10n.dietOmnivore);

    // Çoklu alerji seçimi
    await tester.tap(find.text(l10n.allergenGluten));
    await tester.pump();
    await tester.tap(find.text(l10n.allergenLactose));
    await tester.pump();
    await _next(tester);

    expect(find.text(l10n.qDislikedTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Okra');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await _next(tester);

    await _choose(tester, l10n.mealsCount(3));
    await _choose(tester, l10n.breakfastAlways);

    expect(find.text(l10n.qWaterTitle), findsOneWidget);
    await _next(tester);

    await _choose(tester, l10n.fastingNone);

    expect(find.text(l10n.qTargetDateTitle), findsOneWidget);
    await _next(tester);

    // Sonuç ekranı
    expect(find.byType(SummaryStep), findsOneWidget);
    expect(find.text(l10n.summaryTitleNamed('Ayşe')), findsOneWidget);
    expect(find.text('1,650'), findsOneWidget);
    expect(find.text(l10n.summaryMaintenance('2,200')), findsOneWidget);
    expect(find.text(l10n.summaryWeeks(16)), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.disclaimerTitle),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(l10n.disclaimerTitle), findsOneWidget);

    await _next(tester);

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(
      find.text(l10n.dashboardGreetingNamed('morning', 'Ayşe')),
      findsOneWidget,
    );
    expect(find.byType(CalorieSummaryCard), findsOneWidget);
    expect(find.text(l10n.dashboardKcalOfTarget('1,245', '1,650')), findsOne);

    final saved =
        jsonDecode(storage.getString(StorageKeys.userProfile)!)
            as Map<String, dynamic>;
    expect(saved['dailyCalories'], 1650);
    expect(saved['allergies'], ['gluten', 'lactose']);
    expect(saved['dislikedFoods'], ['Okra']);
    expect(saved['mealsPerDay'], 3);
    expect(storage.getBool(StorageKeys.onboardingCompleted), isTrue);
    expect(storage.getString(StorageKeys.onboardingDraft), isNull);
  });

  testWidgets('yarıda kalan onboarding kaldığı adımdan devam eder', (
    tester,
  ) async {
    _setSurface(tester, const Size(390, 844));
    final storage = InMemoryKeyValueStorage({
      StorageKeys.onboardingDraft: jsonEncode(
        const OnboardingDraft(
          currentStep: OnboardingStep.weight,
          goal: GoalType.loseWeight,
          gender: Gender.male,
          age: 40,
          height: 180,
        ).toJson(),
      ),
    });
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(find.text(l10n.qWeightTitle), findsOneWidget);
    await tester.tap(find.text(l10n.onboardingBack));
    await tester.pumpAndSettle();
    expect(find.text(l10n.qHeightTitle), findsOneWidget);
    expect(find.widgetWithText(TextField, '180'), findsOneWidget);
  });

  const keyboardDrafts = {
    'hedef kilo': OnboardingDraft(
      currentStep: OnboardingStep.targetWeight,
      goal: GoalType.loseWeight,
      gender: Gender.female,
      age: 30,
      height: 165,
      weight: 70,
    ),
    'sevmediği yiyecekler': OnboardingDraft(
      currentStep: OnboardingStep.dislikedFoods,
      goal: GoalType.loseWeight,
    ),
  };
  for (final MapEntry(key: name, value: draft) in keyboardDrafts.entries) {
    testWidgets('klavye açıkken küçük ekranda taşma olmaz ($name)', (
      tester,
    ) async {
      _setSurface(tester, const Size(320, 568));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      final storage = InMemoryKeyValueStorage({
        StorageKeys.onboardingDraft: jsonEncode(draft.toJson()),
      });
      await tester.pumpWidget(_app(storage));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(_primary, findsOneWidget);
      await _next(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('onboarding tamamlandıysa doğrudan giriş ekranı açılır', (
    tester,
  ) async {
    final storage = InMemoryKeyValueStorage({
      StorageKeys.onboardingCompleted: true,
    });
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets('tablet genişliğinde NavigationRail kullanılır', (tester) async {
    _setSurface(tester, const Size(1024, 768));
    final storage = InMemoryKeyValueStorage({
      StorageKeys.onboardingCompleted: true,
    });
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();
    await tapContinueAsGuest(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}

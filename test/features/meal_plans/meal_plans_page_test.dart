import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/meal_plans/presentation/pages/meal_plans_page.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sign_in_guest.dart';
import '../../helpers/subscription_overrides.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

Future<void> _openPlans(
  WidgetTester tester, {
  Size size = const Size(390, 900),
  bool dark = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStorageProvider.overrideWithValue(
          InMemoryKeyValueStorage({
            StorageKeys.onboardingCompleted: true,
            if (dark) StorageKeys.themeMode: ThemeMode.dark.name,
          }),
        ),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 14, 30)),
        premiumOverride,
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tapContinueAsGuest(tester);
  await tester.tap(find.text(l10n.navPlans));
  await tester.pumpAndSettle();
  expect(find.byType(MealPlansPage), findsOneWidget);
  expect(find.text(l10n.weeklyPlanTitle), findsOneWidget);
}

void main() {
  testWidgets('7 günlük tarif planı gün ve öğünlerle gösterilir', (
    tester,
  ) async {
    await _openPlans(tester);
    expect(find.byKey(const ValueKey('plan-day-2026-09-28')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-day-2026-10-04')), findsOneWidget);
    expect(find.text(l10n.planChangeRecipe), findsWidgets);
    expect(find.text(l10n.nutritionPlanLogToday), findsWidgets);
  });

  testWidgets('porsiyon değişince öğün kalorisi güncellenir', (tester) async {
    await _openPlans(tester);
    final before = find.textContaining('kcal').evaluate().length;
    expect(before, greaterThan(0));

    final two = find.descendant(
      of: find.byType(SegmentedButton<int>).first,
      matching: find.text('2'),
    );
    await tester.ensureVisible(two);
    await tester.pumpAndSettle();
    await tester.tap(two);
    await tester.pumpAndSettle();

    expect(find.textContaining('2 servings'), findsWidgets);
  });

  testWidgets('küçük telefonda taşma olmaz', (tester) async {
    await _openPlans(tester, size: const Size(320, 568));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('koyu temada plan ekranı taşmaz', (tester) async {
    await _openPlans(tester, dark: true);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan yenileme iptal edilirse aynı kalır, onayda yenilenir', (
    tester,
  ) async {
    await _openPlans(tester);
    final before = _recipeTitles(tester);
    expect(before, isNotEmpty);

    await tester.tap(find.byTooltip(l10n.planRegenerate));
    await tester.pumpAndSettle();
    expect(find.text(l10n.confirmRegenerateWeekTitle), findsOneWidget);
    await tester.tap(find.text(l10n.actionCancel));
    await tester.pumpAndSettle();
    expect(_recipeTitles(tester), before);
    expect(find.text(l10n.planReplyRegenerated), findsNothing);

    await tester.tap(find.byTooltip(l10n.planRegenerate));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionContinue));
    await tester.pumpAndSettle();
    expect(find.text(l10n.planReplyRegenerated), findsOneWidget);
    expect(_recipeTitles(tester), isNot(before));
  });
}

List<String> _recipeTitles(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    if (text.style?.decoration == TextDecoration.underline && text.data != null)
      text.data!,
];

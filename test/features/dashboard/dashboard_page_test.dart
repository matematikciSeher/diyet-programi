import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:diyet_programi/features/dashboard/presentation/widgets/calorie_summary_card.dart';
import 'package:diyet_programi/features/dashboard/presentation/widgets/nutrition_score_card.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

/// Onboarding tamamlanmış, misafir olarak giriş yapılmış dashboard.
Future<void> _openDashboard(
  WidgetTester tester, {
  required Size size,
  String? themeMode,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final storage = InMemoryKeyValueStorage({
    StorageKeys.onboardingCompleted: true,
    StorageKeys.themeMode: ?themeMode,
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStorageProvider.overrideWithValue(storage),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 14, 30)),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tapContinueAsGuest(tester);
  expect(find.byType(DashboardPage), findsOneWidget);
}

void main() {
  testWidgets('demo verisiyle günün özeti gösterilir', (tester) async {
    await _openDashboard(tester, size: const Size(390, 844));

    expect(find.text(l10n.dashboardGreeting('afternoon')), findsOneWidget);
    expect(find.text(l10n.dashboardKcalOfTarget('1,245', '2,000')), findsOne);
    expect(find.text(l10n.gramsOfTarget('84', '100')), findsOneWidget);
    expect(find.text(l10n.quickAddPhoto), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NutritionScoreCard), findsOneWidget);
  });

  testWidgets('+250 ml su ekler ve geri alınabilir', (tester) async {
    await _openDashboard(tester, size: const Size(390, 844));
    expect(find.text(l10n.waterGlassesProgress(5, 10)), findsOneWidget);

    final add = find.text(l10n.waterAddAmount(250));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text(l10n.waterGlassesProgress(6, 10)), findsOneWidget);
    expect(find.text(l10n.waterAdded(250)), findsOneWidget);

    await tester.tap(find.text(l10n.actionUndo));
    await tester.pumpAndSettle();
    expect(find.text(l10n.waterGlassesProgress(5, 10)), findsOneWidget);
  });

  testWidgets('skor detayında tıbbi teşhis olmadığı belirtilir', (
    tester,
  ) async {
    await _openDashboard(tester, size: const Size(390, 844));
    final card = find.byType(NutritionScoreCard);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text(l10n.scoreDisclaimerLong), findsOneWidget);
    expect(find.text(l10n.scoreFactorProcessed), findsOneWidget);
  });

  const layouts = {
    'küçük telefon': Size(320, 568),
    'geniş ekran': Size(1440, 900),
  };
  for (final MapEntry(key: name, value: size) in layouts.entries) {
    for (final theme in ['light', 'dark']) {
      testWidgets('$name / $theme temada taşma olmaz', (tester) async {
        await _openDashboard(tester, size: size, themeMode: theme);
        expect(find.byType(CalorieSummaryCard), findsOneWidget);

        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

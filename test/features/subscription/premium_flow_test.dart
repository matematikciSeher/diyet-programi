import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/meal_plans/presentation/pages/meal_plans_page.dart';
import 'package:diyet_programi/features/subscription/presentation/pages/paywall_page.dart';
import 'package:diyet_programi/features/subscription/presentation/widgets/premium_gate.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:diyet_programi/shared/services/subscription/fake_subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

Future<void> _openApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final storage = InMemoryKeyValueStorage({
    StorageKeys.onboardingCompleted: true,
  });
  DateTime clock() => DateTime(2026, 9, 28, 14, 30);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStorageProvider.overrideWithValue(storage),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        clockProvider.overrideWithValue(clock),
        subscriptionServiceProvider.overrideWith((ref) {
          final service = FakeSubscriptionService(storage, clock: clock);
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tapContinueAsGuest(tester);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ücretsiz kullanıcı planı açamaz; test üyeliği planı açar', (
    tester,
  ) async {
    await _openApp(tester);

    expect(find.byType(PremiumLockedCard), findsOneWidget);

    await tester.tap(find.text(l10n.navPlans));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumLockedPage), findsOneWidget);
    expect(find.byType(MealPlansPage), findsNothing);

    await tester.tap(find.text(l10n.premiumUnlockAction));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);
    expect(
      find.text(l10n.premiumLockedTitle(l10n.appFeaturePersonalMealPlan)),
      findsOneWidget,
    );
    expect(find.text(l10n.appFeatureAiCoach), findsOneWidget);
    expect(find.text(l10n.appFeatureAdFree), findsOneWidget);
    expect(find.text(l10n.paywallSubscribe), findsNothing);
    expect(find.text(l10n.paywallStartTrial(7)), findsNothing);

    await _tapVisible(tester, find.text(l10n.testPremiumStart));
    await tester.tap(find.text(l10n.testPremiumConfirmAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.testPremiumActiveTitle), findsOneWidget);
    expect(find.text(l10n.paywallPurchaseSuccess), findsNothing);

    await tester.tap(find.text(l10n.actionContinue));
    await tester.pumpAndSettle();
    expect(find.byType(MealPlansPage), findsOneWidget);
    expect(find.byType(PremiumLockedPage), findsNothing);
  });

  testWidgets('premium sayfasında fiyat ve abonelik taahhüdü yoktur', (
    tester,
  ) async {
    await _openApp(tester);
    await tester.tap(find.text(l10n.navPlans));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.premiumUnlockAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.paywallPeriodMonthly), findsNothing);
    expect(find.text(l10n.paywallSubscribe), findsNothing);
    expect(find.text(l10n.paywallLegal), findsNothing);
    expect(find.text(l10n.paywallRestore), findsNothing);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('paywall küçük telefonda taşmaz', (tester) async {
    await _openApp(tester, size: const Size(320, 568));
    await tester.tap(find.text(l10n.navPlans));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.premiumUnlockAction));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

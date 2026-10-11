import 'package:diyet_programi/features/ai_coach/presentation/pages/ai_coach_page.dart';
import 'package:diyet_programi/features/fasting/data/repositories/fasting_repository_impl.dart';
import 'package:diyet_programi/features/fasting/domain/models/fasting_schedule.dart';
import 'package:diyet_programi/features/fasting/domain/repositories/fasting_repository.dart';
import 'package:diyet_programi/features/fasting/presentation/pages/fasting_page.dart';
import 'package:diyet_programi/features/fasting/presentation/providers/fasting_providers.dart';
import 'package:diyet_programi/features/subscription/domain/models/app_feature.dart';
import 'package:diyet_programi/features/subscription/presentation/pages/paywall_page.dart';
import 'package:diyet_programi/features/subscription/presentation/providers/premium_providers.dart';
import 'package:diyet_programi/features/subscription/presentation/widgets/premium_gate.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/auth_user.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/fasting_session.dart';
import 'package:diyet_programi/shared/models/subscription_status.dart';
import 'package:diyet_programi/shared/services/auth/fake_auth_service.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:diyet_programi/shared/services/subscription/fake_subscription_service.dart';
import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/errors/result.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sign_in_guest.dart';
import '../../helpers/subscription_overrides.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

const _schedule = FastingSchedule(
  protocol: FastingPreference.sixteenEight,
  eatingStartMinutes: 12 * 60,
);

void main() {
  test('test üyeliği asistanı açar, oruç üyeliğe bağlı değildir', () async {
    final storage = InMemoryKeyValueStorage();
    final service = FakeSubscriptionService(storage, exposeOfferings: false);
    final container = ProviderContainer(
      overrides: [
        keyValueStorageProvider.overrideWithValue(storage),
        subscriptionServiceProvider.overrideWith((ref) {
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(subscriptionStatusProvider, (_, _) {});
    await container.read(subscriptionStatusProvider.future);

    expect(container.read(featureAccessProvider(AppFeature.aiCoach)), isFalse);
    expect(container.read(featureAccessProvider(AppFeature.fasting)), isTrue);
    expect(await service.getCurrentOffering(), isNull);

    await service.activateTestMembership();
    await pumpEventQueue();
    final status = container.read(subscriptionStatusProvider).value!;
    expect(status.isTestGrant, isTrue);
    expect(status.productId, isNull);
    expect(status.willRenew, isFalse);
    expect(container.read(featureAccessProvider(AppFeature.aiCoach)), isTrue);
    expect(container.read(featureAccessProvider(AppFeature.fasting)), isTrue);

    await service.resetTestMembership();
    await pumpEventQueue();
    expect(
      container.read(subscriptionStatusProvider).value,
      SubscriptionStatus.free,
    );
    expect(container.read(featureAccessProvider(AppFeature.aiCoach)), isFalse);
    expect(container.read(featureAccessProvider(AppFeature.fasting)), isTrue);
  });

  test('üyelik olmadan oruç başlatılabilir', () async {
    final repo = _RecordingFasting();
    final container = ProviderContainer(
      overrides: [
        keyValueStorageProvider.overrideWithValue(InMemoryKeyValueStorage()),
        fastingRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 10, 12)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(subscriptionStatusProvider, (_, _) {});
    await container.read(subscriptionStatusProvider.future);

    final result = await container
        .read(fastingControllerProvider)
        .start(_schedule);

    expect(result.isSuccess, isTrue);
    expect(repo.saves, 1);
  });

  test('premium kullanıcı oruç başlatabilir', () async {
    final container = ProviderContainer(
      overrides: [
        keyValueStorageProvider.overrideWithValue(InMemoryKeyValueStorage()),
        premiumOverride,
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 10, 12)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(authStateProvider, (_, _) {});
    container.listen(subscriptionStatusProvider, (_, _) {});
    await container.read(authServiceProvider).signInAnonymously();
    await container.read(authStateProvider.future);
    await container.read(subscriptionStatusProvider.future);

    final result = await container
        .read(fastingControllerProvider)
        .start(_schedule);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.protocol, FastingPreference.sixteenEight);
  });

  testWidgets('test üyeliği onayı kapalı özellikleri açar ve sıfırlanır', (
    tester,
  ) async {
    await _openApp(tester);

    final profile = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(l10n.navProfile),
    );
    await _tapVisible(tester, profile);
    final fastingTile = find.ancestor(
      of: find.text(l10n.featureFasting),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: fastingTile, matching: find.byType(PremiumBadge)),
      findsNothing,
    );
    await _tapVisible(tester, _listTileTitle(l10n.featureFasting));
    expect(find.byType(FastingPage), findsOneWidget);
    expect(find.byType(PremiumLockedPage), findsNothing);
    expect(find.byType(PremiumBadge), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openProfileFeature(tester, l10n.featureAiCoach);
    expect(find.byType(PremiumLockedPage), findsOneWidget);
    expect(find.byType(AiCoachPage), findsNothing);

    await tester.tap(find.text(l10n.premiumUnlockAction));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallPage), findsOneWidget);

    await _tapVisible(tester, find.text(l10n.testPremiumStart));
    expect(find.text(l10n.testPremiumConfirmTitle), findsOneWidget);
    expect(find.text(l10n.testPremiumConfirmMessage), findsOneWidget);
    await tester.tap(find.text(l10n.actionCancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.testPremiumActiveTitle), findsNothing);
    expect(find.text(l10n.paywallPurchaseSuccess), findsNothing);

    await _tapVisible(tester, find.text(l10n.testPremiumStart));
    await tester.tap(find.text(l10n.testPremiumConfirmAction));
    await tester.pumpAndSettle();
    expect(_onPaywall(l10n.testPremiumActiveTitle), findsOneWidget);
    expect(_onPaywall(l10n.testPremiumActiveMessage), findsOneWidget);
    expect(find.text(l10n.paywallPurchaseSuccess), findsNothing);
    expect(find.text(l10n.paywallRenewsOn('x')), findsNothing);
    expect(find.text(l10n.testPremiumStarted), findsOneWidget);

    await tester.tap(find.text(l10n.actionContinue));
    await tester.pumpAndSettle();
    expect(find.byType(AiCoachPage), findsOneWidget);
    expect(find.byType(PremiumLockedPage), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openProfileFeature(tester, l10n.featurePremium);
    expect(_onPaywall(l10n.testPremiumActiveTitle), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(l10n.testPremiumReset));
    await tester.pumpAndSettle();
    expect(find.text(l10n.testPremiumResetDone), findsOneWidget);
    expect(find.text(l10n.testPremiumStart), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await _openProfileFeature(tester, l10n.featureFasting);
    expect(find.byType(FastingPage), findsOneWidget);
    expect(find.byType(PremiumLockedPage), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openProfileFeature(tester, l10n.featureAiCoach);
    expect(find.byType(PremiumLockedPage), findsOneWidget);
    expect(find.byType(AiCoachPage), findsNothing);
  });

  testWidgets('uygulama yeniden açılınca test üyeliği durur', (tester) async {
    final storage = InMemoryKeyValueStorage({
      StorageKeys.onboardingCompleted: true,
    });
    const user = AuthUser(uid: 'user-1', displayName: 'Test');

    await _openApp(tester, storage: storage, user: user);
    await _openProfileFeature(tester, l10n.featurePremium);
    await _tapVisible(tester, find.text(l10n.testPremiumStart));
    await tester.tap(find.text(l10n.testPremiumConfirmAction));
    await tester.pumpAndSettle();
    expect(_onPaywall(l10n.testPremiumActiveTitle), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _openApp(tester, storage: storage, user: user);
    await _openProfileFeature(tester, l10n.featurePremium);
    expect(_onPaywall(l10n.testPremiumActiveTitle), findsOneWidget);
    expect(_onPaywall(l10n.testPremiumActiveMessage), findsOneWidget);
    expect(find.text(l10n.testPremiumStart), findsNothing);
    expect(find.text(l10n.paywallPurchaseSuccess), findsNothing);
  });
}

Future<void> _openApp(
  WidgetTester tester, {
  InMemoryKeyValueStorage? storage,
  AuthUser? user,
}) async {
  tester.view
    ..physicalSize = const Size(390, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final localStorage =
      storage ??
      InMemoryKeyValueStorage({StorageKeys.onboardingCompleted: true});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStorageProvider.overrideWithValue(localStorage),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        if (user != null)
          authServiceProvider.overrideWith((ref) {
            final service = FakeAuthService(initialUser: user);
            ref.onDispose(service.dispose);
            return service;
          }),
        fastingTickerProvider.overrideWith((ref) async* {
          yield DateTime(2026, 10, 10, 12);
        }),
        localDocumentDatabaseProvider.overrideWith((ref) {
          final db = InMemoryDocumentDatabase();
          ref.onDispose(db.dispose);
          return db;
        }),
        subscriptionServiceProvider.overrideWith((ref) {
          final service = FakeSubscriptionService(
            localStorage,
            exposeOfferings: false,
          );
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  if (user == null) await tapContinueAsGuest(tester);
}

Finder _onPaywall(String text) =>
    find.descendant(of: find.byType(PaywallPage), matching: find.text(text));

Future<void> _openProfileFeature(WidgetTester tester, String label) async {
  final profile = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(l10n.navProfile),
  );
  if (profile.evaluate().isNotEmpty) {
    await _tapVisible(tester, profile);
  }
  await _tapVisible(tester, _listTileTitle(label));
}

Finder _listTileTitle(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is ListTile &&
      widget.title is Text &&
      (widget.title! as Text).data == label,
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  final target = finder.evaluate().length > 1 ? finder.last : finder;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class _RecordingFasting implements FastingRepository {
  int saves = 0;

  @override
  Stream<List<FastingSession>> watchSessions() => Stream.value(const []);

  @override
  Future<Result<FastingSession>> saveSession(FastingSession session) async {
    saves++;
    return Result.success(session);
  }

  @override
  Future<Result<void>> deleteSession(String id) async =>
      const Result.success(null);
}

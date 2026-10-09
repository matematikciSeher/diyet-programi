import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/features/activity/domain/models/daily_activity.dart';
import 'package:diyet_programi/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:diyet_programi/features/activity/domain/repositories/activity_repository.dart';
import 'package:diyet_programi/features/activity/presentation/widgets/health_data_section.dart';
import 'package:diyet_programi/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:diyet_programi/features/dashboard/presentation/widgets/activity_card.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/health/fake_health_data_service.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

class _FixedActivity implements ActivityRepository {
  const _FixedActivity(this.activity);

  final DailyActivity activity;

  @override
  Stream<DailyActivity> watchDay(DateTime day) => Stream.value(activity);
}

const _healthDay = DailyActivity(
  steps: 8000,
  activeCalories: 420,
  distanceMeters: 2500,
  source: ActivitySource.health,
  stepsKnown: true,
  caloriesKnown: true,
  distanceKnown: true,
);

Future<void> _pumpCard(WidgetTester tester, DailyActivity activity) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ActivityCard(activity: activity, stepGoal: 10000),
      ),
    ),
  );
}

void main() {
  testWidgets('health data shows steps, distance and active calories', (
    tester,
  ) async {
    await _pumpCard(tester, _healthDay);

    expect(find.text('8,000'), findsOneWidget);
    expect(find.text('420'), findsOneWidget);
    expect(find.text(l10n.activityDistanceKm('2.5')), findsOneWidget);
    expect(find.text(l10n.activityDistance), findsOneWidget);
    expect(find.text(l10n.activityExercise), findsNothing);
  });

  testWidgets('unknown health values stay blank', (tester) async {
    await _pumpCard(
      tester,
      const DailyActivity(
        source: ActivitySource.health,
        stepsKnown: false,
        caloriesKnown: false,
        distanceKnown: false,
      ),
    );

    expect(find.text(l10n.healthValueUnavailable), findsNWidgets(3));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('without health data the existing activity card stays', (
    tester,
  ) async {
    await _pumpCard(tester, DemoActivityRepository.today);

    expect(find.text('6,842'), findsOneWidget);
    expect(find.text('312'), findsOneWidget);
    expect(find.text(l10n.activityExercise), findsOneWidget);
    expect(find.text(l10n.activityDistance), findsNothing);
  });

  testWidgets('dashboard keeps the calorie target when health data is shown', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = InMemoryKeyValueStorage({
      StorageKeys.onboardingCompleted: true,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStorageProvider.overrideWithValue(storage),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 14, 30)),
          activityRepositoryProvider.overrideWithValue(
            const _FixedActivity(_healthDay),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    await tapContinueAsGuest(tester);
    expect(find.byType(DashboardPage), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('8,000'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('8,000'), findsOneWidget);
    expect(
      find.text(l10n.dashboardKcalOfTarget('1,245', '2,000')),
      findsOneWidget,
    );
  });

  testWidgets('unsupported platform explains that health data is unavailable', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStorageProvider.overrideWithValue(
              InMemoryKeyValueStorage(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HealthDataSection()),
          ),
        ),
      );

      expect(find.text(l10n.healthUnavailableBody), findsOneWidget);
      expect(find.text(l10n.healthConnectName), findsNothing);
      expect(find.text(l10n.healthAppleName), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('denied permission keeps the section usable', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final health = FakeHealthDataService(
      permission: FakeHealthPermission.denied,
    );
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStorageProvider.overrideWithValue(
              InMemoryKeyValueStorage(),
            ),
            healthDataServiceProvider.overrideWithValue(health),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: HealthDataSection()),
          ),
        ),
      );

      expect(find.text(l10n.healthStatusNotLinked), findsOneWidget);
      await tester.tap(find.text(l10n.healthConnectAction));
      await tester.pumpAndSettle();

      expect(find.text(l10n.healthPermissionDenied), findsOneWidget);
      expect(find.text(l10n.healthStatusNotLinked), findsOneWidget);
      expect(health.stepsReads, 0);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

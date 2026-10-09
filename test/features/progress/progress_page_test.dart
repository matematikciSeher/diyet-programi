import 'dart:typed_data';

import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:diyet_programi/features/progress/presentation/pages/progress_page.dart';
import 'package:diyet_programi/features/progress/presentation/widgets/adherence_card.dart';
import 'package:diyet_programi/features/progress/presentation/widgets/progress_photos_card.dart';
import 'package:diyet_programi/features/progress/presentation/widgets/score_history_card.dart';
import 'package:diyet_programi/features/progress/presentation/widgets/weekly_average_card.dart';
import 'package:diyet_programi/features/progress/presentation/widgets/weight_chart.dart';
import 'package:diyet_programi/features/subscription/presentation/widgets/premium_gate.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/media/photo_picker_service.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/subscription_overrides.dart';
import '../../helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

class _FakePhotoPicker implements PhotoPickerService {
  int picks = 0;

  @override
  bool supports(PhotoSource source) => source == PhotoSource.gallery;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    picks++;
    return PickedPhoto(bytes: Uint8List.fromList(const [1, 2, 3]));
  }
}

Future<void> _openProgress(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String? themeMode,
  PhotoPickerService? picker,
  bool premium = true,
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
        photoPickerServiceProvider.overrideWithValue(
          picker ?? _FakePhotoPicker(),
        ),
        if (premium) premiumOverride,
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tapContinueAsGuest(tester);
  expect(find.byType(DashboardPage), findsOneWidget);

  await tester.tap(find.text(l10n.navProgress).last);
  await tester.pumpAndSettle();
  expect(find.byType(ProgressPage), findsOneWidget);
}

void main() {
  testWidgets('tüm ilerleme bölümleri demo verisiyle gösterilir', (
    tester,
  ) async {
    await _openProgress(tester);

    for (final title in [
      l10n.progressGoalTitle,
      l10n.progressChartTitle,
      l10n.progressWeeklyTitle,
      l10n.progressMeasurementsTitle,
      l10n.progressWaistTitle,
      l10n.progressAdherenceTitle,
      l10n.progressAdherenceCalories,
      l10n.progressAdherenceProtein,
      l10n.progressAdherenceWater,
      l10n.progressScoreTitle,
      l10n.progressPhotosTitle,
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text(l10n.progressStartWeight), findsOneWidget);
    expect(find.text(l10n.progressCurrentWeight), findsOneWidget);
    expect(find.text(l10n.progressTargetWeight), findsOneWidget);
    expect(find.text(l10n.progressLostWeight), findsOneWidget);
    expect(find.text(l10n.progressRemainingWeight), findsOneWidget);
    expect(find.byType(WeightChart), findsOneWidget);
    expect(find.text(l10n.progressKg('78')), findsWidgets);
  });

  testWidgets('ücretsiz kullanıcı temel ilerlemeyi görür, gelişmiş kartlar '
      'kilitlidir', (tester) async {
    await _openProgress(tester, premium: false);

    expect(find.byType(WeightChart), findsOneWidget);
    expect(find.text(l10n.progressGoalTitle), findsOneWidget);
    expect(find.text(l10n.progressMeasurementsTitle), findsOneWidget);
    expect(find.text(l10n.progressPhotosTitle), findsOneWidget);
    expect(find.byType(WeeklyAverageCard), findsNothing);
    expect(find.byType(AdherenceCard), findsNothing);
    expect(find.byType(ScoreHistoryCard), findsNothing);
    expect(find.byType(PremiumLockedCard), findsNWidgets(3));
  });

  testWidgets('dönem değişince skor geçmişi yeniden hesaplanır', (
    tester,
  ) async {
    await _openProgress(tester);
    ScoreHistoryCard card() =>
        tester.widget<ScoreHistoryCard>(find.byType(ScoreHistoryCard));
    expect(card().days, hasLength(30));

    await tester.tap(find.text(l10n.progressRange('week')));
    await tester.pumpAndSettle();
    expect(card().days, hasLength(7));
  });

  testWidgets('kilo eklenir ve güncel kilo güncellenir', (tester) async {
    await _openProgress(tester);

    await tester.tap(find.text(l10n.progressAddWeight).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '76.4');
    await tester.tap(find.text(l10n.actionSave));
    await tester.pumpAndSettle();

    expect(find.text(l10n.progressWeightSaved('76.4')), findsOneWidget);
    expect(find.text(l10n.progressKg('76.4')), findsWidgets);
  });

  testWidgets('geçersiz kilo kaydedilmez', (tester) async {
    await _openProgress(tester);

    await tester.tap(find.text(l10n.progressAddWeight).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '5');
    await tester.tap(find.text(l10n.actionSave));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errorOutOfRange('25', '350')), findsOneWidget);
  });

  testWidgets('ilerleme fotoğrafı eklenir', (tester) async {
    final picker = _FakePhotoPicker();
    await _openProgress(tester, picker: picker);
    expect(find.text(l10n.progressPhotosEmpty), findsOneWidget);

    final add = find.text(l10n.progressAddPhoto);
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();

    expect(picker.picks, 1);
    expect(find.text(l10n.progressPhotoAdded), findsOneWidget);
    expect(find.byType(ProgressPhotoImage), findsOneWidget);
    expect(find.text(l10n.progressPhotosEmpty), findsNothing);
  });

  const layouts = {
    'küçük telefon': Size(320, 568),
    'geniş ekran': Size(1440, 900),
  };
  for (final MapEntry(key: name, value: size) in layouts.entries) {
    for (final theme in ['light', 'dark']) {
      testWidgets('$name / $theme temada taşma olmaz', (tester) async {
        await _openProgress(tester, size: size, themeMode: theme);

        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -4000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

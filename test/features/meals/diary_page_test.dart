import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/food/presentation/pages/food_detail_page.dart';
import 'package:diyet_programi/features/food/presentation/pages/food_search_page.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/meals/presentation/pages/diary_page.dart';
import 'package:diyet_programi/features/meals/presentation/widgets/diary_score_card.dart';
import 'package:diyet_programi/features/meals/presentation/widgets/meal_section_card.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diary_test_utils.dart';
import '../../helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

/// Başlıktaki "Bugün" butonu (tarih etiketi de "Bugün" yazabilir).
final _todayButton = find.widgetWithText(TextButton, l10n.diaryToday);

/// Misafir girişiyle açılan uygulamada alt menüden Günlük sekmesine geçer.
Future<void> _openDiary(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String? themeMode,
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
            StorageKeys.themeMode: ?themeMode,
          }),
        ),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        clockProvider.overrideWithValue(() => testNow),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tapContinueAsGuest(tester);

  final nav = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(l10n.navDiary),
  );
  if (nav.evaluate().isNotEmpty) {
    await tester.tap(nav);
  } else {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(l10n.navDiary),
      ),
    );
  }
  await tester.pumpAndSettle();
  expect(find.byType(DiaryPage), findsOneWidget);
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(DiaryPage)));

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find
        .descendant(
          of: find.byType(DiaryPage),
          matching: find.byType(Scrollable),
        )
        .last,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bugünün demo günlüğü gösterilir', (tester) async {
    await _openDiary(tester);

    expect(find.text(l10n.diaryCaloriesLeft('755')), findsOneWidget);
    expect(_todayButton, findsNothing);
    expect(find.byType(MealSectionCard), findsWidgets);
    expect(find.text(l10n.mealBreakfast), findsWidgets);

    await _scrollTo(tester, find.byType(DiaryScoreCard));
    expect(find.text(l10n.diaryScoreTitle('today')), findsOneWidget);
    await _scrollTo(tester, find.text(l10n.diaryScoreDisclaimer));
    expect(find.text(l10n.diaryScoreDisclaimer), findsOneWidget);
  });

  testWidgets('hedef aşılınca negatif kalan yerine aşım gösterilir', (
    tester,
  ) async {
    await _openDiary(tester);
    await _container(tester)
        .read(mealLogRepositoryProvider)
        .addEntry(entry(MealType.dinner, kcal: 875));
    await tester.pumpAndSettle();

    expect(find.text(l10n.diaryCaloriesOver('120')), findsOneWidget);
    expect(find.textContaining('-'), findsNothing);
  });

  testWidgets('ileri gün boş günlük gösterir, Bugün ile geri dönülür', (
    tester,
  ) async {
    await _openDiary(tester);
    await tester.tap(find.byTooltip(l10n.diaryNextDay));
    await tester.pumpAndSettle();

    expect(find.text(l10n.diaryEmptyDayTitle('future')), findsOneWidget);
    expect(find.text(l10n.diaryCaloriesLeft('2,000')), findsOneWidget);
    expect(find.text(l10n.diaryFutureDayNote), findsOneWidget);

    await tester.tap(_todayButton);
    await tester.pumpAndSettle();
    expect(_todayButton, findsNothing);
    expect(find.text(l10n.diaryCaloriesLeft('755')), findsOneWidget);
  });

  testWidgets('seçili gün sekme değişince korunur', (tester) async {
    await _openDiary(tester);
    await tester.tap(find.byTooltip(l10n.diaryPreviousDay));
    await tester.pumpAndSettle();
    expect(_todayButton, findsOneWidget);
    expect(find.text(l10n.diaryYesterday), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navHome),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navDiary),
      ),
    );
    await tester.pumpAndSettle();
    expect(_todayButton, findsOneWidget);
    expect(find.text(l10n.diaryYesterday), findsWidgets);
  });

  testWidgets('yiyecek onayla silinir ve toplam güncellenir', (tester) async {
    await _openDiary(tester);
    final container = _container(tester);
    await container
        .read(mealLogRepositoryProvider)
        .addEntry(entry(MealType.breakfast, name: 'Test elma', kcal: 55));
    await tester.pumpAndSettle();
    expect(find.text(l10n.diaryCaloriesLeft('700')), findsOneWidget);

    final tile = find.ancestor(
      of: find.text('Test elma'),
      matching: find.byType(FoodEntryTile),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: tile, matching: find.byTooltip(l10n.diaryEntryMenu)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionDelete).last);
    await tester.pumpAndSettle();

    expect(find.text(l10n.diaryDeleteMessage), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.actionDelete),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test elma'), findsNothing);
    expect(find.text(l10n.diaryEntryDeleted('Test elma')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.diaryCaloriesLeft('755')),
      -300,
      scrollable: find
          .descendant(
            of: find.byType(DiaryPage),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    expect(find.text(l10n.diaryCaloriesLeft('755')), findsOneWidget);
  });

  testWidgets('su kartından su eklenir ve azaltılır', (tester) async {
    await _openDiary(tester);
    final add = find.text(l10n.waterAddAmount(250));
    await _scrollTo(tester, add);
    expect(find.text(l10n.diaryWaterOfGoal('1,250', '2,500')), findsOneWidget);

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text(l10n.diaryWaterOfGoal('1,500', '2,500')), findsOneWidget);
    expect(find.text(l10n.waterAdded(250)), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.diaryWaterRemove(250)));
    await tester.pumpAndSettle();
    expect(find.text(l10n.diaryWaterOfGoal('1,250', '2,500')), findsOneWidget);
  });

  testWidgets('FAB hızlı ekleme menüsünü açar', (tester) async {
    await _openDiary(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.diaryQuickAddTitle), findsOneWidget);
    expect(find.text(l10n.diaryAddWater), findsOneWidget);
    expect(find.text(l10n.diaryAddWeight), findsOneWidget);
    expect(find.text(l10n.diaryAddActivity), findsOneWidget);
  });

  testWidgets('günlükten yiyecek aranıp kahvaltıya eklenir', (tester) async {
    await _openDiary(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.quickAddFood).last);
    await tester.pumpAndSettle();
    expect(find.byType(FoodSearchPage), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, l10n.mealBreakfast));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'süt');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Süt (tam yağlı)'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);

    await tester.tap(find.text(l10n.foodAddToMeal(l10n.mealBreakfast)));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.foodAddedTo('Süt (tam yağlı)', l10n.mealBreakfast)),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(DiaryPage), findsOneWidget);
    expect(find.text(l10n.diaryCaloriesLeft('606')), findsOneWidget);
  });

  const layouts = {
    'küçük telefon': Size(320, 568),
    'geniş ekran': Size(1440, 900),
  };
  for (final MapEntry(key: name, value: size) in layouts.entries) {
    for (final theme in ['light', 'dark']) {
      testWidgets('$name / $theme temada taşma olmaz', (tester) async {
        await _openDiary(tester, size: size, themeMode: theme);
        await _scrollTo(tester, find.byType(DiaryScoreCard));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

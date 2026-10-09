import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/food/presentation/pages/food_detail_page.dart';
import 'package:diyet_programi/features/food/presentation/pages/food_search_page.dart';
import 'package:diyet_programi/features/food/presentation/widgets/food_list_tile.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

Future<void> _openFoodSearch(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStorageProvider.overrideWithValue(
          InMemoryKeyValueStorage({StorageKeys.onboardingCompleted: true}),
        ),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 8, 30)),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  await tapContinueAsGuest(tester);

  final quickAdd = find.ancestor(
    of: find.text(l10n.quickAddFood),
    matching: find.byType(Column),
  );
  final button = find.descendant(
    of: quickAdd.first,
    matching: find.byType(InkWell),
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.byType(FoodSearchPage), findsOneWidget);
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('arama 400 ms debounce kullanır', (tester) async {
    await _openFoodSearch(tester);
    await tester.enterText(find.byType(TextField).first, 'yumurta');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1 piece (50 g) · 72 kcal'), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('1 piece (50 g) · 72 kcal'), findsOneWidget);
  });

  testWidgets('aramada isim, porsiyon, kalori ve makrolar görünür', (
    tester,
  ) async {
    await _openFoodSearch(tester);
    expect(find.text(l10n.foodSearchHint), findsOneWidget);
    expect(find.text(l10n.foodTabRecent), findsOneWidget);

    await _search(tester, 'yumurta');
    expect(find.byType(FoodListTile), findsWidgets);
    expect(find.text('1 piece (50 g) · 72 kcal'), findsOneWidget);
    expect(find.textContaining('6.3 g'), findsNWidgets(2));
  });

  testWidgets('detayda miktar değişince değerler güncellenir ve eklenir', (
    tester,
  ) async {
    await _openFoodSearch(tester);
    await _search(tester, 'haşlanmış yumurta');
    await tester.tap(find.byType(FoodListTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
    expect(find.text('78'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '2'));
    await tester.pumpAndSettle();
    expect(find.text('155'), findsOneWidget);

    final add = find.text(l10n.foodAddToMeal(l10n.mealBreakfast));
    expect(add, findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();

    expect(find.byType(FoodSearchPage), findsOneWidget);
    expect(
      find.text(l10n.foodAddedTo('Haşlanmış yumurta', l10n.mealBreakfast)),
      findsOneWidget,
    );

    await _search(tester, '');
    expect(find.text('Haşlanmış yumurta'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.dashboardKcalOfTarget('1,400', '2,000')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('küçük ekranda detay ve özel yiyecek formu taşmaz', (
    tester,
  ) async {
    await _openFoodSearch(tester, size: const Size(320, 568));
    await _search(tester, 'süt');
    await tester.tap(find.byType(FoodListTile).first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _search(tester, '');
    await tester.ensureVisible(find.text(l10n.foodTabMine));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.foodTabMine));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.foodCreateCustom));
    await tester.pumpAndSettle();
    expect(find.text(l10n.customFoodTitle), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

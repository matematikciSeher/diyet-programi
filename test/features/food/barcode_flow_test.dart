import 'package:diyet_programi/app.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/routing/app_startup.dart';
import 'package:diyet_programi/features/barcode/presentation/pages/barcode_scanner_page.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_catalog.dart';
import 'package:diyet_programi/features/food/presentation/pages/custom_food_page.dart';
import 'package:diyet_programi/features/food/presentation/pages/food_detail_page.dart';
import 'package:diyet_programi/features/food/presentation/pages/food_search_page.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sign_in_guest.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

Future<void> _openBarcode(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 844)
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

  await tester.tap(find.text(l10n.quickAddBarcode));
  await tester.pumpAndSettle();
  expect(find.byType(BarcodeScannerPage), findsOneWidget);
}

void main() {
  testWidgets('demo barkod ürün detayına gider', (tester) async {
    await _openBarcode(tester);
    await tester.enterText(
      find.byType(TextField),
      SampleFoodCatalog.demoBarcodes.first,
    );
    await tester.tap(find.text(l10n.barcodeSearch));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
  });

  testWidgets('bilinmeyen barkod özel yiyecek oluşturmayı sunar', (tester) async {
    await _openBarcode(tester);
    await tester.enterText(find.byType(TextField), '0000000000000');
    await tester.tap(find.text(l10n.barcodeSearch));
    await tester.pumpAndSettle();
    expect(find.text(l10n.barcodeNotFound), findsOneWidget);
    await tester.tap(find.text(l10n.foodCreateCustom));
    await tester.pumpAndSettle();
    expect(find.byType(CustomFoodPage), findsOneWidget);
  });

  testWidgets('bulunan barkod öğüne eklenir', (tester) async {
    await _openBarcode(tester);
    await tester.enterText(
      find.byType(TextField),
      SampleFoodCatalog.demoBarcodes.first,
    );
    await tester.tap(find.text(l10n.barcodeSearch));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);

    await tester.tap(find.text(l10n.foodAddToMeal(l10n.mealBreakfast)));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSearchPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.dashboardKcalOfTarget('1,394', '2,000')),
      findsOneWidget,
    );
  });
}

import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/routing/app_routes.dart';
import 'package:diyet_programi/features/barcode/presentation/barcode_camera_permission.dart';
import 'package:diyet_programi/features/barcode/presentation/pages/barcode_scanner_page.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_catalog.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/features/food/domain/repositories/food_repository.dart';
import 'package:diyet_programi/features/food/presentation/pages/custom_food_page.dart';
import 'package:diyet_programi/features/food/presentation/pages/food_detail_page.dart';
import 'package:diyet_programi/core/theme/app_theme.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/services/barcode/barcode_lookup_service.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/food_database/food_database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

class _CountingLookup implements FoodDatabaseService, BarcodeLookupService {
  _CountingLookup({this.food});

  final Food? food;
  var lookups = 0;
  String? lastBarcode;

  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async => const [];

  @override
  Future<Food?> getById(String id) async => food;

  @override
  Future<Food?> lookup(String barcode) async {
    lookups++;
    lastBarcode = barcode;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return food;
  }
}

class _IncompleteLookup implements FoodDatabaseService, BarcodeLookupService {
  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async => const [];

  @override
  Future<Food?> getById(String id) async => null;

  @override
  Future<Food?> lookup(String barcode) async =>
      throw IncompleteCatalogFoodException(
        'incomplete_catalog_food',
        barcode: barcode,
        code: 'incomplete_catalog_food',
      );
}

class _FailingLookup implements FoodDatabaseService, BarcodeLookupService {
  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async =>
      throw const NetworkException('no_connection', code: 'no_connection');

  @override
  Future<Food?> getById(String id) async =>
      throw const NetworkException('no_connection', code: 'no_connection');

  @override
  Future<Food?> lookup(String barcode) async =>
      throw const NetworkException('no_connection', code: 'no_connection');
}

class _ScriptedCamera extends StatefulWidget {
  const _ScriptedCamera({required this.onDetect, required this.codes});

  final void Function(String) onDetect;
  final List<String> codes;

  @override
  State<_ScriptedCamera> createState() => _ScriptedCameraState();
}

class _ScriptedCameraState extends State<_ScriptedCamera> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final code in widget.codes) {
        widget.onDetect(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

Widget _app({
  required Widget Function() scanner,
  FoodRepository? repository,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.barcodeScanner,
    routes: [
      GoRoute(
        path: AppRoutes.barcodeScanner,
        builder: (_, _) => scanner(),
      ),
      GoRoute(
        path: AppRoutes.foodDetail,
        builder: (context, state) => FoodDetailPage(
          foodId: state.pathParameters['id'] ?? '',
          initialFood: state.extra is Food ? state.extra! as Food : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.customFood,
        builder: (context, state) => CustomFoodPage(
          barcode: state.uri.queryParameters[AppRoutes.barcodeQueryParam],
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      if (repository != null)
        foodRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  late InMemoryDocumentDatabase db;

  setUp(() => db = InMemoryDocumentDatabase());
  tearDown(() => db.dispose());

  testWidgets('elle barkod girişi ürün detayına gider', (tester) async {
    final sample = SampleFoodCatalog.foods.firstWhere(
      (f) => f.barcode == SampleFoodCatalog.demoBarcodes.first,
    );
    final lookup = _CountingLookup(food: sample);
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: lookup,
      barcodeLookup: lookup,
    );
    await tester.pumpWidget(
      _app(
        repository: repo,
        scanner: () => const BarcodeScannerPage(enableLiveCamera: false),
      ),
    );
    await tester.enterText(
      find.byType(TextField),
      SampleFoodCatalog.demoBarcodes.first,
    );
    await tester.tap(find.text(l10n.barcodeSearch));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
  });

  testWidgets('ürün bulunamazsa özel yiyecek ve tekrar tara sunulur', (
    tester,
  ) async {
    final lookup = _CountingLookup();
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: lookup,
      barcodeLookup: lookup,
    );
    await tester.pumpWidget(
      _app(
        repository: repo,
        scanner: () => const BarcodeScannerPage(enableLiveCamera: false),
      ),
    );
    await tester.enterText(find.byType(TextField), '0000000000000');
    await tester.tap(find.text(l10n.barcodeSearch));
    await tester.pumpAndSettle();
    expect(find.text(l10n.barcodeNotFound), findsOneWidget);
    expect(find.text(l10n.foodCreateCustom), findsOneWidget);
    expect(find.text(l10n.barcodeScanAgain), findsOneWidget);

    await tester.tap(find.text(l10n.foodCreateCustom));
    await tester.pumpAndSettle();
    expect(find.byType(CustomFoodPage), findsOneWidget);
    expect(find.text('0000000000000'), findsOneWidget);
  });

  testWidgets('eksik OFF kaydı bulunamadı gibi değil özel mesaj gösterir', (
    tester,
  ) async {
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: _IncompleteLookup(),
      barcodeLookup: _IncompleteLookup(),
    );
    await tester.pumpWidget(
      _app(
        repository: repo,
        scanner: () => const BarcodeScannerPage(enableLiveCamera: false),
      ),
    );
    await tester.enterText(find.byType(TextField), '8691422701433');
    await tester.tap(find.text(l10n.barcodeSearch));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.barcodeIncompleteCatalog('8691422701433')),
      findsOneWidget,
    );
    expect(find.text(l10n.barcodeNotFound), findsNothing);
    expect(find.text(l10n.foodCreateCustom), findsOneWidget);
    expect(find.text(l10n.barcodeScanAgain), findsOneWidget);
  });

  testWidgets('kamera izni reddedilince uygulama çökmez', (tester) async {
    var openedSettings = false;
    await tester.pumpWidget(
      _app(
        scanner: () => BarcodeScannerPage(
          enableLiveCamera: true,
          initialPermission: BarcodeCameraPermission.denied,
          onOpenSettings: () async => openedSettings = true,
        ),
      ),
    );
    expect(find.text(l10n.barcodeCameraPermissionTitle), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text(l10n.barcodeOpenSettings));
    await tester.pumpAndSettle();
    expect(openedSettings, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aynı barkod callback iki kez lookup yapmaz', (tester) async {
    final lookup = _CountingLookup();
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: lookup,
      barcodeLookup: lookup,
    );
    const code = '2000000000015';
    await tester.pumpWidget(
      _app(
        repository: repo,
        scanner: () => BarcodeScannerPage(
          enableLiveCamera: true,
          cameraBuilder:
              ({
                required onDetect,
                required paused,
                required onPermissionChanged,
              }) => _ScriptedCamera(onDetect: onDetect, codes: const [code, code]),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(lookup.lookups, 1);
    await tester.pumpAndSettle();
    expect(find.text(l10n.barcodeNotFound), findsOneWidget);
  });

  testWidgets('kameradan leading zero repositoryye aynı gider', (tester) async {
    final lookup = _CountingLookup();
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: lookup,
      barcodeLookup: lookup,
    );
    await tester.pumpWidget(
      _app(
        repository: repo,
        scanner: () => BarcodeScannerPage(
          enableLiveCamera: true,
          cameraBuilder:
              ({
                required onDetect,
                required paused,
                required onPermissionChanged,
              }) => _ScriptedCamera(
                onDetect: onDetect,
                codes: const [' 0123456789012 '],
              ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(lookup.lastBarcode, '0123456789012');
    expect(lookup.lastBarcode, isNot('123456789012'));
    await tester.pumpAndSettle();
  });

  testWidgets('kameradan bulunan ürün detaya gider', (tester) async {
    final food = SampleFoodCatalog.foods.firstWhere(
      (f) => f.barcode == SampleFoodCatalog.demoBarcodes.first,
    );
    final lookup = _CountingLookup(food: food);
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: lookup,
      barcodeLookup: lookup,
    );
    await tester.pumpWidget(
      _app(
        repository: repo,
        scanner: () => BarcodeScannerPage(
          enableLiveCamera: true,
          cameraBuilder:
              ({
                required onDetect,
                required paused,
                required onPermissionChanged,
              }) => _ScriptedCamera(
                onDetect: onDetect,
                codes: [SampleFoodCatalog.demoBarcodes.first],
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailPage), findsOneWidget);
  });

  testWidgets('çevrimdışı ve önbelleksiz üründe kullanıcı dostu hata', (
    tester,
  ) async {
    final repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: _FailingLookup(),
      barcodeLookup: _FailingLookup(),
    );
    await tester.pumpWidget(
      _app(
        repository: repo,
        scanner: () => const BarcodeScannerPage(enableLiveCamera: false),
      ),
    );
    await tester.enterText(find.byType(TextField), '3017620422003');
    await tester.tap(find.text(l10n.barcodeSearch));
    await tester.pumpAndSettle();
    expect(find.text(l10n.foodDatabaseUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

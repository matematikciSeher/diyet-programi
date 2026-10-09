import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_catalog.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_database_service.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/features/food/domain/models/portion_selection.dart';
import 'package:diyet_programi/features/food/domain/services/food_calculation_service.dart';
import 'package:diyet_programi/features/food/domain/usecases/log_food.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/barcode/barcode_lookup_service.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/food_database/food_database_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late FoodRepositoryImpl repo;
  final now = DateTime(2026, 9, 28, 8, 30);

  setUp(() {
    db = InMemoryDocumentDatabase();
    final sample = SampleFoodDatabaseService();
    repo = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: sample,
      barcodeLookup: sample,
      clock: () => now,
    );
  });
  tearDown(() => db.dispose());

  test('arama kullanıcı yiyeceklerini ve veritabanını birleştirir', () async {
    await repo.saveCustomFood(
      const Food(
        id: '',
        name: 'Yumurtalı ekmek',
        nutritionPer100: NutritionFacts(calories: 250),
      ),
    );
    final results = (await repo.search('yumurta')).valueOrNull!;
    final names = results.map((f) => f.name).toList();
    expect(names, contains('Yumurtalı ekmek'));
    expect(names.first, 'Yumurta (çiğ)');
  });

  test('demo barkod örnek ürünü bulur, bilinmeyen barkod null döner', () async {
    final found = await repo.findByBarcode(SampleFoodCatalog.demoBarcodes[0]);
    expect(found.valueOrNull?.isSample, isTrue);
    expect((await repo.findByBarcode('123')).valueOrNull, isNull);
  });

  test('uzak API düşünce özel yiyecekler aramada kalır', () async {
    await repo.saveCustomFood(
      const Food(
        id: '',
        name: 'Ev yoğurdu',
        nutritionPer100: NutritionFacts(calories: 70),
      ),
    );
    final offline = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: _DownFoodDatabase(),
      barcodeLookup: _DownFoodDatabase(),
      clock: () => now,
    );
    final results = (await offline.search('ev')).valueOrNull!;
    expect(results.single.name, 'Ev yoğurdu');
  });

  test('sayfalama ikinci sayfada önceki kayıtları tekrarlamaz', () async {
    final sample = SampleFoodDatabaseService();
    final page1 = await sample.search('yumurta', page: 1, pageSize: 1);
    final page2 = await sample.search('yumurta', page: 2, pageSize: 1);
    expect(page1, isNotEmpty);
    if (page2.isNotEmpty) {
      expect(page1.map((f) => f.id).toSet().intersection(page2.map((f) => f.id).toSet()), isEmpty);
    }
  });

  test('öneriler yalnızca yerel kayıtlardan gelir', () async {
    await repo.saveCustomFood(
      const Food(
        id: 'c1',
        name: 'Ev omleti',
        nutritionPer100: NutritionFacts(calories: 150),
      ),
    );
    final suggestions = (await repo.suggestions('omlet')).valueOrNull!;
    expect(suggestions.single.name, 'Ev omleti');
  });

  test('favoriye eklenir ve çıkarılır', () async {
    final egg = SampleFoodCatalog.foods.first;
    await repo.setFavorite(egg, favorite: true);
    expect((await repo.watchFavorites().first).single.id, egg.id);
    await repo.setFavorite(egg, favorite: false);
    expect(await repo.watchFavorites().first, isEmpty);
  });

  test('yemek eklenince günlüğe ve son kullanılanlara yazılır', () async {
    final meals = MealLogRepositoryImpl(db, 'user-1');
    const calc = FoodCalculationService();
    final logFood = LogFood(
      meals: meals,
      foods: repo,
      calculator: calc,
      clock: () => now,
    );
    final bread = SampleFoodCatalog.foods.firstWhere(
      (f) => f.id == 'sample-whole-wheat-bread',
    );
    final twoSlices = PortionSelection(
      portion: bread.portions.single,
      quantity: 2,
    );

    final result = await logFood(
      food: bread,
      selection: twoSlices,
      mealType: MealType.breakfast,
      servingLabel: '2 dilim (64 g)',
    );
    final entry = result.valueOrNull!;
    expect(entry.quantityGrams, 64);
    expect(entry.nutrition.calories, closeTo(252 * 0.64, 1e-9));
    expect(entry.tags, {FoodTag.wholeGrain});
    expect(await meals.watchDay(now).first, hasLength(1));

    final recents = await repo.watchRecents().first;
    expect(recents.single.food.id, bread.id);
    expect(recents.single.lastSelection, twoSlices);

    await logFood.undo(entry.id);
    expect(await meals.watchDay(now).first, isEmpty);
  });

  test('saate göre öğün önerilir', () {
    expect(LogFood.suggestedMeal(DateTime(2026, 1, 1, 8)), MealType.breakfast);
    expect(LogFood.suggestedMeal(DateTime(2026, 1, 1, 13)), MealType.lunch);
    expect(LogFood.suggestedMeal(DateTime(2026, 1, 1, 16)), MealType.snack);
    expect(LogFood.suggestedMeal(DateTime(2026, 1, 1, 20)), MealType.dinner);
  });

  test('özel yiyecek kaydedilir ve silinir', () async {
    final saved = (await repo.saveCustomFood(
      const Food(
        id: '',
        name: 'Ev granola',
        brand: 'Ev',
        nutritionPer100: NutritionFacts(calories: 450, proteinG: 10),
      ),
    )).valueOrNull!;
    expect(saved.id, isNotEmpty);
    expect(saved.source, FoodSource.custom);
    expect((await repo.watchCustomFoods().first).single.name, 'Ev granola');

    await repo.deleteCustomFood(saved.id);
    expect(await repo.watchCustomFoods().first, isEmpty);
  });

  test('aynı yiyecek tekrar eklenince son kullanılanlarda tek kayıt kalır', () async {
    const calc = FoodCalculationService();
    final egg = SampleFoodCatalog.foods.first;
    final one = calc.defaultSelection(egg);
    final two = PortionSelection(portion: egg.portions.first, quantity: 2);
    await repo.recordRecent(egg, one, at: now);
    await repo.recordRecent(egg, two, at: now.add(const Duration(minutes: 5)));
    final recents = await repo.watchRecents().first;
    expect(recents, hasLength(1));
    expect(recents.single.lastSelection.quantity, 2);
  });

  test('uzak API düşünce ve yerel eşleşme yoksa hata döner', () async {
    final offline = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: _DownFoodDatabase(),
      barcodeLookup: _DownFoodDatabase(),
      clock: () => now,
    );
    expect((await offline.search('xyzzy')).isFailure, isTrue);
  });
}

class _DownFoodDatabase implements FoodDatabaseService, BarcodeLookupService {
  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = 25,
    String? locale,
  }) async => throw const NetworkException('no_connection', code: 'no_connection');

  @override
  Future<Food?> getById(String id) async =>
      throw const NetworkException('no_connection', code: 'no_connection');

  @override
  Future<Food?> lookup(String barcode) async =>
      throw const NetworkException('no_connection', code: 'no_connection');
}

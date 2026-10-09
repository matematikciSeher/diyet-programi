import 'package:diyet_programi/features/food/data/datasources/sample_food_catalog.dart';
import 'package:diyet_programi/features/food/domain/services/food_search_service.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:flutter_test/flutter_test.dart';

Food _food(String id, String name, {List<String> keywords = const []}) => Food(
  id: id,
  name: name,
  nutritionPer100: NutritionFacts.zero,
  keywords: keywords,
);

void main() {
  const search = FoodSearchService();

  test('Türkçe karakter ve büyük/küçük harf farkı yok sayılır', () {
    expect(FoodSearchService.normalize('ÇORBA'), 'corba');
    expect(FoodSearchService.normalize('Işık  İnci'), 'isik inci');
    expect(FoodSearchService.normalize('yoğurt'), 'yogurt');
  });

  test('tam eşleşme, başlangıç eşleşmesinden önce gelir', () {
    final foods = [
      _food('1', 'Haşlanmış yumurta', keywords: ['yumurta']),
      _food('2', 'Yumurta akı'),
      _food('3', 'Yumurta'),
    ];
    final ranked = search.rank(foods, 'yumurta').map((f) => f.id);
    expect(ranked, ['3', '2', '1']);
  });

  test('tüm kelimeler eşleşmeli; anahtar kelimeler de aranır', () {
    final foods = [
      _food('1', 'Tavuk göğsü', keywords: ['chicken']),
      _food('2', 'Tavuk but'),
    ];
    expect(search.rank(foods, 'tavuk gog').map((f) => f.id), ['1']);
    expect(search.rank(foods, 'chicken').map((f) => f.id), ['1']);
    expect(search.rank(foods, 'balik'), isEmpty);
  });

  test('aynı id tekrar edilmez', () {
    final foods = [_food('1', 'Elma'), _food('1', 'Elma (kopya)')];
    expect(search.rank(foods, 'elma'), hasLength(1));
  });

  test('uzak sonuçlar yerel eşleşme olmasa da korunur', () {
    final local = [_food('1', 'Elma')];
    final remote = [
      const Food(
        id: 'off-1',
        name: 'Granny Smith Apple',
        nutritionPer100: NutritionFacts.zero,
      ),
    ];
    final combined = search.combine(
      local: local,
      remote: remote,
      query: 'elma',
    );
    expect(combined.map((f) => f.id), ['1', 'off-1']);
  });

  test('örnek katalogdaki tüm kayıtlar örnek veri ve kaynaklı', () {
    for (final food in SampleFoodCatalog.foods) {
      expect(food.isSample, isTrue, reason: food.name);
      expect(food.dataReference, isNotNull, reason: food.name);
    }
    final ids = SampleFoodCatalog.foods.map((f) => f.id).toSet();
    expect(ids, hasLength(SampleFoodCatalog.foods.length));
  });
}

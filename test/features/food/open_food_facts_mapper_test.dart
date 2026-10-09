import 'package:diyet_programi/features/food/data/datasources/food_api_config.dart';
import 'package:diyet_programi/features/food/data/datasources/open_food_facts_mapper.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('100 g nutriment değerlerini Food.nutritionPer100 olarak okur', () {
    final food = OpenFoodFactsMapper.fromProduct({
      'code': '3017620422003',
      'product_name': 'Nutella',
      'brands': 'Ferrero, Other',
      'image_front_small_url': 'https://example.com/n.jpg',
      'serving_quantity': 15,
      'serving_size': '15 g',
      'nutriments': {
        'energy-kcal_100g': 539,
        'proteins_100g': 6.3,
        'carbohydrates_100g': 57.5,
        'fat_100g': 30.9,
        'fiber_100g': 0,
        'sugars_100g': 56.3,
        'saturated-fat_100g': 10.6,
        'sodium_100g': 0.107,
      },
    });
    expect(food, isNotNull);
    expect(food!.id, FoodApiConfig.productId('3017620422003'));
    expect(food.name, 'Nutella');
    expect(food.brand, 'Ferrero');
    expect(food.barcode, '3017620422003');
    expect(food.nutritionPer100.calories, 539);
    expect(food.nutritionPer100.proteinG, 6.3);
    expect(food.nutritionPer100.sodiumMg, closeTo(107, 1e-9));
    expect(food.portions.single.baseAmount, 15);
    expect(food.dataReference, FoodApiConfig.dataReference);
    expect(food.source, FoodSource.database);
  });

  test('kalori yoksa ürün elenir', () {
    expect(
      OpenFoodFactsMapper.fromProduct({
        'code': '1',
        'product_name': 'Su',
        'nutriments': {'proteins_100g': 0},
      }),
      isNull,
    );
  });

  test('sayısal JSON code string barkoda çevrilir', () {
    final food = OpenFoodFactsMapper.fromProduct({
      'code': 3017620422003,
      'product_name': 'Nutella',
      'nutriments': {'energy-kcal_100g': 539},
    });
    expect(food!.barcode, '3017620422003');
  });

  test('code yoksa fallback barkod kullanılır', () {
    final food = OpenFoodFactsMapper.fromProduct({
      'product_name': 'Nutella',
      'nutriments': {'energy-kcal_100g': 539},
    }, fallbackBarcode: '3017620422003');
    expect(food!.barcode, '3017620422003');
  });

  test('gerçek OFF v2 product alanlarını okur', () {
    final food = OpenFoodFactsMapper.fromProduct({
      'code': '3017620422003',
      'product_name': 'Nutella',
      'product_name_tr': 'Nutella',
      'generic_name': 'Pâte à tartiner',
      'brands': 'Nutella, Ferrero',
      'image_front_small_url': 'https://images.openfoodfacts.org/n.jpg',
      'image_small_url': 'https://images.openfoodfacts.org/n2.jpg',
      'nutriments': {
        'energy-kcal_100g': 539,
        'proteins_100g': 6.3,
        'carbohydrates_100g': 57.5,
        'fat_100g': 30.9,
      },
    }, source: FoodSource.barcode);
    expect(food, isNotNull);
    expect(food!.barcode, '3017620422003');
    expect(food.name, 'Nutella');
    expect(food.brand, 'Nutella');
    expect(food.nutritionPer100.calories, 539);
  });

  test('barkod kaynağı product lookup için işaretlenir', () {
    final food = OpenFoodFactsMapper.fromProduct({
      'code': '2000000000015',
      'product_name_tr': 'Yoğurt',
      'nutriments': {'energy-kcal_100g': 61},
    }, source: FoodSource.barcode);
    expect(food!.source, FoodSource.barcode);
    expect(food.name, 'Yoğurt');
  });
}

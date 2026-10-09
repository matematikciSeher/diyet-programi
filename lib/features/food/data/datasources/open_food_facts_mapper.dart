import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/nutrition_facts.dart';
import 'food_api_config.dart';

/// Open Food Facts ürün JSON'unu [Food] modeline çevirir.
///
/// Besin değerleri her zaman 100 g veya 100 ml bazındadır; porsiyon
/// ölçeklemesi [FoodCalculationService] tarafındadır.
abstract final class OpenFoodFactsMapper {
  static Food? fromProduct(
    Map<String, dynamic> product, {
    FoodSource source = FoodSource.database,
    String? fallbackBarcode,
  }) {
    final code = _barcode(product, fallbackBarcode);
    final name = _name(product);
    if (code == null || name == null) return null;

    final nutriments = JsonUtils.readMap(product['nutriments']);
    final nutrition = _nutrition(nutriments);
    if (nutrition == null) return null;

    final basis = _basis(product);
    final serving = _servingPortion(product, basis);
    final brand = JsonUtils.readStringOrNull(product['brands'])?.split(',')
        .first
        .trim();

    return Food(
      id: FoodApiConfig.productId(code),
      name: name,
      brand: brand == null || brand.isEmpty ? null : brand,
      barcode: code,
      imageUrl: JsonUtils.readStringOrNull(
        product['image_front_small_url'] ?? product['image_small_url'],
      ),
      nutritionPer100: nutrition,
      basis: basis,
      portions: [?serving],
      source: source,
      dataReference: FoodApiConfig.dataReference,
    );
  }

  static String? _barcode(
    Map<String, dynamic> product,
    String? fallbackBarcode,
  ) {
    return _digits(product['code']) ??
        _digits(product['_id']) ??
        _digits(fallbackBarcode);
  }

  /// JSON `code` string veya sayı olabilir. Tarama barkodu asla int parse edilmez;
  /// sayı geldiyse JSON zaten leading zero kaybetmiştir, kalan rakamlar string kalır.
  static String? _digits(Object? value) {
    if (value is String) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      return digits.isEmpty ? null : digits;
    }
    if (value is int) return value.toString();
    if (value is num && value.isFinite && value.roundToDouble() == value) {
      return value.round().toString();
    }
    return null;
  }

  static String? peekName(Map<String, dynamic> product) => _name(product);

  static String? _name(Map<String, dynamic> product) {
    for (final key in [
      'product_name_tr',
      'product_name',
      'product_name_en',
      'generic_name_tr',
      'generic_name',
      'generic_name_en',
    ]) {
      final value = JsonUtils.readStringOrNull(product[key]);
      if (value != null) return value;
    }
    return null;
  }

  static NutritionBasis _basis(Map<String, dynamic> product) {
    final per = JsonUtils.readString(product['nutrition_data_per']).toLowerCase();
    if (per.contains('100ml') || per.contains('100 ml')) {
      return NutritionBasis.milliliter;
    }
    return NutritionBasis.gram;
  }

  static FoodPortion? _servingPortion(
    Map<String, dynamic> product,
    NutritionBasis basis,
  ) {
    final quantity = JsonUtils.readDoubleOrNull(product['serving_quantity']);
    if (quantity == null || quantity <= 0) return null;
    final label = JsonUtils.readStringOrNull(product['serving_size']);
    return FoodPortion(
      unit: PortionUnit.serving,
      baseAmount: quantity,
      description: label,
    );
  }

  static NutritionFacts? _nutrition(Map<String, dynamic> nutriments) {
    final calories = _calories(nutriments);
    if (calories == null || calories < 0) return null;
    final sodiumG = _firstNum(nutriments, const [
      'sodium_100g',
      'sodium',
    ]);
    final saltG = _firstNum(nutriments, const ['salt_100g', 'salt']);
    final sodiumMg = sodiumG != null
        ? sodiumG * 1000
        : saltG != null
        ? saltG / 2.5 * 1000
        : null;
    return NutritionFacts(
      calories: calories,
      proteinG: _firstNum(nutriments, const ['proteins_100g', 'proteins']) ?? 0,
      carbsG:
          _firstNum(nutriments, const [
            'carbohydrates_100g',
            'carbohydrates',
          ]) ??
          0,
      fatG: _firstNum(nutriments, const ['fat_100g', 'fat']) ?? 0,
      fiberG: _firstNum(nutriments, const ['fiber_100g', 'fiber']),
      sugarG: _firstNum(nutriments, const ['sugars_100g', 'sugars']),
      saturatedFatG: _firstNum(nutriments, const [
        'saturated-fat_100g',
        'saturated_fat_100g',
        'saturated-fat',
      ]),
      sodiumMg: sodiumMg,
    );
  }

  static double? _calories(Map<String, dynamic> nutriments) {
    final kcal = _firstNum(nutriments, const [
      'energy-kcal_100g',
      'energy-kcal',
      'energy_kcal_100g',
      'energy-kcal_value',
      'energy_kcal',
    ]);
    if (kcal != null) return kcal;
    final kj = _firstNum(nutriments, const ['energy-kj_100g', 'energy_100g']);
    if (kj == null) return null;
    return kj / 4.184;
  }

  static double? _firstNum(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = JsonUtils.readDoubleOrNull(map[key]);
      if (value != null) return value;
    }
    return null;
  }
}

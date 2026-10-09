import 'dart:convert';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/services/barcode/barcode_digits.dart';
import '../../../../shared/services/local_storage/key_value_storage.dart';
import 'food_api_config.dart';

class _SearchEntry {
  const _SearchEntry(this.foods, this.cachedAt);

  final List<Food> foods;
  final DateTime cachedAt;
}

class _ProductEntry {
  const _ProductEntry(this.food, this.cachedAt);

  final Food food;
  final DateTime cachedAt;
}

/// Arama sonuçları bellek içi TTL; ürün/barkod kayıtları kalıcı önbellek.
/// Firebase'e yazılmaz; yalnızca cihazda tutulur.
class FoodLookupCache {
  FoodLookupCache(
    this._storage, {
    DateTime Function() clock = DateTime.now,
    this.searchTtl = FoodApiConfig.searchCacheTtl,
    this.productTtl = FoodApiConfig.productCacheTtl,
    this.maxProducts = FoodApiConfig.maxCachedProducts,
  }) : _clock = clock {
    _loadProducts();
  }

  final KeyValueStorage _storage;
  final DateTime Function() _clock;
  final Duration searchTtl;
  final Duration productTtl;
  final int maxProducts;

  final _searches = <String, _SearchEntry>{};
  final _products = <String, _ProductEntry>{};

  static String searchKey({
    required String query,
    required int page,
    required int pageSize,
    String? locale,
  }) =>
      '${FoodApiConfig.normalizeQuery(query)}|$page|$pageSize|${locale ?? ''}';

  List<Food>? search(
    String key, {
    bool allowExpired = false,
  }) {
    final entry = _searches[key];
    if (entry == null) return null;
    if (!allowExpired && _clock().difference(entry.cachedAt) > searchTtl) {
      return null;
    }
    return List<Food>.from(entry.foods);
  }

  Future<void> putSearch(String key, List<Food> foods) async {
    _searches[key] = _SearchEntry(List<Food>.from(foods), _clock());
    for (final food in foods) {
      await putProduct(food, persist: false);
    }
    await _trimAndSave();
  }

  Food? product(String idOrBarcode, {bool allowExpired = false}) {
    final entry =
        _products[idOrBarcode] ??
        _products[FoodApiConfig.productId(idOrBarcode)];
    if (entry == null) return null;
    if (!allowExpired && _clock().difference(entry.cachedAt) > productTtl) {
      return null;
    }
    return entry.food;
  }

  Food? byBarcode(String barcode, {bool allowExpired = false}) {
    final code = BarcodeDigits.normalize(barcode);
    if (code.isEmpty) return null;
    for (final entry in _products.values) {
      if (entry.food.barcode == code) {
        if (!allowExpired && _clock().difference(entry.cachedAt) > productTtl) {
          continue;
        }
        return entry.food;
      }
    }
    return product(FoodApiConfig.productId(code), allowExpired: allowExpired);
  }

  /// Süresi dolmamış benzersiz önbellek ürünleri (öneriler için).
  List<Food> cachedFoods({bool allowExpired = false}) {
    final unique = <String, Food>{};
    for (final entry in _products.values) {
      if (!allowExpired && _clock().difference(entry.cachedAt) > productTtl) {
        continue;
      }
      unique[entry.food.id] = entry.food;
    }
    return unique.values.toList();
  }

  Future<void> putProduct(Food food, {bool persist = true}) async {
    final now = _clock();
    _products[food.id] = _ProductEntry(food, now);
    final barcode = food.barcode;
    if (barcode != null && barcode.isNotEmpty) {
      _products[barcode] = _ProductEntry(food, now);
    }
    if (persist) await _trimAndSave();
  }

  void _loadProducts() {
    final raw = _storage.getString(StorageKeys.foodLookupCache);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final items = decoded['items'];
      if (items is! Map) return;
      for (final entry in items.entries) {
        if (entry.value is! Map) continue;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final foodMap = JsonUtils.readMap(map['food']);
        if (foodMap.isEmpty) continue;
        final food = Food.fromJson(foodMap);
        final cachedAt =
            JsonUtils.readDate(map['cachedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        _products[food.id] = _ProductEntry(food, cachedAt);
        final barcode = food.barcode;
        if (barcode != null) {
          _products[barcode] = _ProductEntry(food, cachedAt);
        }
      }
    } on Object catch (error) {
      AppLogger.warning('Yiyecek önbelleği okunamadı', error: error);
    }
  }

  Future<void> _trimAndSave() async {
    if (_products.length > maxProducts * 2) {
      final unique = <String, _ProductEntry>{};
      for (final entry in _products.values) {
        unique[entry.food.id] = entry;
      }
      final sorted = unique.values.toList()
        ..sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
      _products.clear();
      for (final entry in sorted.take(maxProducts)) {
        _products[entry.food.id] = entry;
        final barcode = entry.food.barcode;
        if (barcode != null) _products[barcode] = entry;
      }
    }
    final unique = <String, _ProductEntry>{};
    for (final entry in _products.values) {
      unique[entry.food.id] = entry;
    }
    final payload = {
      'items': {
        for (final entry in unique.values)
          entry.food.id: {
            'cachedAt': entry.cachedAt.toIso8601String(),
            'food': entry.food.toJson(),
          },
      },
    };
    await _storage.setString(StorageKeys.foodLookupCache, jsonEncode(payload));
  }
}

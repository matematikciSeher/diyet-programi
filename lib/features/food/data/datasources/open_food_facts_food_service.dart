import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/services/barcode/barcode_digits.dart';
import '../../../../shared/services/barcode/barcode_lookup_service.dart';
import '../../../../shared/services/food_database/food_database_service.dart';
import 'barcode_lookup_log.dart';
import 'food_api_config.dart';
import 'open_food_facts_mapper.dart';

/// Open Food Facts arama ve barkod bakımı. UI ve repository bu sınıfa
/// doğrudan bağlanmaz.
class OpenFoodFactsFoodService
    implements FoodDatabaseService, BarcodeLookupService {
  OpenFoodFactsFoodService(this._client);

  final ApiClient _client;

  static const _fields =
      'code,product_name,product_name_en,product_name_tr,'
      'generic_name,generic_name_en,generic_name_tr,brands,'
      'image_front_small_url,image_small_url,nutriments,serving_quantity,'
      'serving_size,nutrition_data_per';

  @override
  Future<List<Food>> search(
    String query, {
    int page = 1,
    int pageSize = FoodApiConfig.searchPageSize,
    String? locale,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    if (!FoodApiConfig.isRemoteSearchQuery(trimmed)) return const [];
    try {
      final payload = await _client.get<Map<String, dynamic>>(
        '/cgi/search.pl',
        queryParameters: {
          'search_terms': trimmed,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page': page < 1 ? 1 : page,
          'page_size': pageSize,
          'fields': _fields,
          if (locale != null && locale.isNotEmpty) 'lc': locale,
        },
        decoder: _asMap,
      );
      final products = payload['products'];
      if (products is! List) return const [];
      return [
        for (final item in products)
          if (item is Map)
            ?OpenFoodFactsMapper.fromProduct(
              Map<String, dynamic>.from(item),
            ),
      ];
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw NetworkException(
        'malformed_response',
        code: 'malformed_response',
        cause: error,
      );
    }
  }

  @override
  Future<Food?> getById(String id) async {
    final barcode = FoodApiConfig.barcodeFromId(id) ?? id.trim();
    if (barcode.isEmpty) return null;
    return lookup(barcode);
  }

  @override
  Future<Food?> lookup(String barcode) async {
    final code = BarcodeDigits.normalize(barcode);
    if (code.isEmpty) return null;
    final path = FoodApiConfig.productPath(code);
    final url = FoodApiConfig.productUrl(code);
    try {
      final payload = await _client.get<Map<String, dynamic>>(
        path,
        queryParameters: {'fields': _fields},
        decoder: _requireMap,
      );
      return _mapLookupPayload(
        barcode: code,
        url: url,
        httpStatus: 200,
        payload: payload,
      );
    } on IncompleteCatalogFoodException {
      rethrow;
    } on NotFoundException {
      BarcodeLookupLog.write(
        barcode: code,
        source: 'remote',
        url: url,
        httpStatus: 404,
        productFound: false,
      );
      return null;
    } on AppException catch (error) {
      BarcodeLookupLog.write(
        barcode: code,
        source: 'remote',
        url: url,
        httpStatus: _httpStatusOf(error),
        productFound: false,
      );
      rethrow;
    } on Object catch (error) {
      BarcodeLookupLog.write(
        barcode: code,
        source: 'remote',
        url: url,
        httpStatus: 'malformed',
        productFound: false,
      );
      throw NetworkException(
        'malformed_response',
        code: 'malformed_response',
        cause: error,
      );
    }
  }

  Food? _mapLookupPayload({
    required String barcode,
    required String url,
    required int httpStatus,
    required Map<String, dynamic> payload,
  }) {
    final offStatus = JsonUtils.readIntOrNull(payload['status']);
    final productRaw = payload['product'];
    final hasProduct = productRaw is Map;
    if (offStatus == 0 || !hasProduct) {
      BarcodeLookupLog.write(
        barcode: barcode,
        source: 'remote',
        url: url,
        httpStatus: httpStatus,
        offStatus: offStatus,
        productFound: false,
        code: JsonUtils.readStringOrNull(payload['code']) ?? barcode,
      );
      return null;
    }
    final product = Map<String, dynamic>.from(productRaw);
    final food = OpenFoodFactsMapper.fromProduct(
      product,
      source: FoodSource.barcode,
      fallbackBarcode: barcode,
    );
    BarcodeLookupLog.write(
      barcode: barcode,
      source: 'remote',
      url: url,
      httpStatus: httpStatus,
      offStatus: offStatus,
      productFound: true,
      mapped: food != null,
      productName: food?.name ?? OpenFoodFactsMapper.peekName(product),
      code:
          food?.barcode ??
          JsonUtils.readStringOrNull(product['code']) ??
          JsonUtils.readStringOrNull(payload['code']) ??
          barcode,
    );
    if (food == null) {
      throw IncompleteCatalogFoodException(
        'incomplete_catalog_food',
        barcode: barcode,
        code: 'incomplete_catalog_food',
      );
    }
    return food;
  }

  static Object _httpStatusOf(AppException error) {
    return switch (error) {
      IncompleteCatalogFoodException() => 200,
      NotFoundException() => 404,
      NetworkException(:final code) when code == 'rate_limited' => 429,
      NetworkException(:final code) when code == 'timeout' => 'timeout',
      NetworkException(:final code) when code == 'no_connection' =>
        'network_error',
      NetworkException(:final code)
          when code == '500' || code == '502' || code == '503' =>
        int.tryParse(code ?? '') ?? code ?? 'unavailable',
      ServerException(:final statusCode) => statusCode ?? 'server_error',
      _ => error.code ?? error.message,
    };
  }

  static Map<String, dynamic> _asMap(Object? json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return const {};
  }

  static Map<String, dynamic> _requireMap(Object? json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    throw const NetworkException(
      'malformed_response',
      code: 'malformed_response',
    );
  }
}

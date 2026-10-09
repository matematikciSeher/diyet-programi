import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/barcode/barcode_digits.dart';
import '../../../../shared/services/barcode/barcode_lookup_service.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/food_database/food_database_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/models/portion_selection.dart';
import '../../domain/models/recent_food.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/services/food_search_service.dart';
import '../datasources/caching_food_database_service.dart';
import '../datasources/food_api_config.dart';
import '../datasources/food_lookup_cache.dart';
import '../datasources/open_food_facts_food_service.dart';
import '../datasources/sample_food_database_service.dart';

final class FoodRepositoryImpl extends UserScopedRepository
    implements FoodRepository {
  const FoodRepositoryImpl(
    super.db,
    super.uid, {
    required FoodDatabaseService foodDatabase,
    required BarcodeLookupService barcodeLookup,
    FoodSearchService search = const FoodSearchService(),
    DateTime Function() clock = DateTime.now,
    AnalyticsService? analytics,
    FoodLookupCache? lookupCache,
  }) : _foodDatabase = foodDatabase,
       _barcodeLookup = barcodeLookup,
       _search = search,
       _clock = clock,
       _analytics = analytics,
       _lookupCache = lookupCache;

  static const maxRecents = 30;

  final FoodDatabaseService _foodDatabase;
  final BarcodeLookupService _barcodeLookup;
  final FoodSearchService _search;
  final DateTime Function() _clock;
  final AnalyticsService? _analytics;
  final FoodLookupCache? _lookupCache;

  Future<List<Food>> _customFoods() async {
    final id = uid;
    if (id == null) return const [];
    final docs = await db.getCollection(FirestorePaths.customFoods(id));
    return [for (final d in docs) _foodFromDoc(d)];
  }

  static Food _foodFromDoc(DocumentSnapshotData doc) =>
      Food.fromJson({...doc.data, 'id': doc.id});

  Future<List<Food>> _userFoods() async {
    final userId = uid;
    if (userId == null) return const [];
    final favs = await db.getCollection(FirestorePaths.favoriteFoods(userId));
    final recents = await db.getCollection(FirestorePaths.recentFoods(userId));
    return [
      for (final d in favs) Food.fromJson(JsonUtils.readMap(d.data['food'])),
      for (final d in recents) RecentFood.fromJson(d.data).food,
    ];
  }

  Future<List<Food>> _localMatches(String query) async {
    final custom = await _customFoods();
    final extras = await _userFoods();
    final cached = _lookupCache?.cachedFoods() ?? const <Food>[];
    return _search.rank([...custom, ...extras, ...cached], query, limit: 8);
  }

  @override
  Future<Result<List<Food>>> search(String query, {int page = 1}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const Result.success([]));
    return guard(() async {
      final custom = page == 1 ? await _customFoods() : const <Food>[];
      if (!FoodApiConfig.isRemoteSearchQuery(trimmed)) {
        if (page > 1) return const <Food>[];
        return _localMatches(trimmed);
      }
      List<Food> remote = const [];
      Object? remoteError;
      try {
        remote = await _foodDatabase.search(
          trimmed,
          page: page,
          pageSize: FoodApiConfig.searchPageSize,
          locale: AppConstants.defaultLocale,
        );
      } on Object catch (error) {
        remoteError = error;
        if (page > 1) rethrow;
      }
      final combined = _search.combine(
        local: custom,
        remote: remote,
        query: trimmed,
      );
      if (combined.isEmpty && remoteError != null) {
        throw remoteError;
      }
      if (page == 1) {
        unawaited(_analytics?.logEvent(AnalyticsEvents.foodSearch));
      }
      return combined;
    });
  }

  @override
  Future<Result<List<Food>>> suggestions(String query) => guard(() async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    return _localMatches(trimmed);
  });

  @override
  Future<Result<Food?>> getById(String id) => guard(() async {
    final userId = uid;
    if (userId != null) {
      final doc = await db.getDocument(
        '${FirestorePaths.customFoods(userId)}/$id',
      );
      if (doc != null) return _foodFromDoc(doc);
    }
    return _foodDatabase.getById(id);
  });

  @override
  Future<Result<Food?>> findByBarcode(String barcode) => guard(() async {
    final code = BarcodeDigits.normalize(barcode);
    if (code.isEmpty) return null;
    AppLogger.debug('Barcode repository: barcode=$code');
    unawaited(_analytics?.logEvent(AnalyticsEvents.barcodeScan));
    for (final food in await _customFoods()) {
      if (food.barcode == code) {
        unawaited(_analytics?.logEvent(AnalyticsEvents.barcodeProductFound));
        return food;
      }
    }
    final remote = await _barcodeLookup.lookup(code);
    unawaited(
      _analytics?.logEvent(
        remote == null
            ? AnalyticsEvents.barcodeProductNotFound
            : AnalyticsEvents.barcodeProductFound,
      ),
    );
    return remote;
  });

  @override
  Stream<List<Food>> watchCustomFoods() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.customFoods(id),
          query: const DocumentQuery(orderBy: 'name'),
        )
        .map((docs) => [for (final d in docs) _foodFromDoc(d)]);
  }

  @override
  Future<Result<Food>> saveCustomFood(Food food) => guard(() async {
    final collection = FirestorePaths.customFoods(requireUid());
    final saved = food.copyWith(
      id: food.id.isEmpty ? db.generateId(collection) : food.id,
      source: food.isRecipe ? FoodSource.recipe : FoodSource.custom,
    );
    await db.setDocument('$collection/${saved.id}', saved.toJson());
    unawaited(_analytics?.logEvent(AnalyticsEvents.customFoodCreated));
    return saved;
  });

  @override
  Future<Result<void>> deleteCustomFood(String id) => guard(() async {
    final userId = requireUid();
    await db.deleteDocument('${FirestorePaths.customFoods(userId)}/$id');
    await db.deleteDocument('${FirestorePaths.favoriteFoods(userId)}/$id');
    await db.deleteDocument('${FirestorePaths.recentFoods(userId)}/$id');
  });

  @override
  Stream<List<Food>> watchFavorites() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.favoriteFoods(id),
          query: const DocumentQuery(orderBy: 'addedAt', descending: true),
        )
        .map(
          (docs) => [
            for (final d in docs)
              Food.fromJson(JsonUtils.readMap(d.data['food'])),
          ],
        );
  }

  @override
  Future<Result<void>> setFavorite(Food food, {required bool favorite}) =>
      guard(() async {
        final path = '${FirestorePaths.favoriteFoods(requireUid())}/${food.id}';
        if (!favorite) return db.deleteDocument(path);
        await db.setDocument(path, {
          'food': food.toJson(),
          'addedAt': _clock().toIso8601String(),
        });
        unawaited(_analytics?.logEvent(AnalyticsEvents.foodFavorited));
      });

  @override
  Stream<List<RecentFood>> watchRecents({int limit = 20}) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.recentFoods(id),
          query: DocumentQuery(
            orderBy: 'lastUsedAt',
            descending: true,
            limit: limit,
          ),
        )
        .map((docs) => [for (final d in docs) RecentFood.fromJson(d.data)]);
  }

  @override
  Future<Result<void>> recordRecent(
    Food food,
    PortionSelection selection, {
    required DateTime at,
  }) => guard(() async {
    final collection = FirestorePaths.recentFoods(requireUid());
    final recent = RecentFood(
      food: food,
      lastSelection: selection,
      lastUsedAt: at,
    );
    await db.setDocument('$collection/${food.id}', recent.toJson());

    final all = await db.getCollection(
      collection,
      query: const DocumentQuery(orderBy: 'lastUsedAt', descending: true),
    );
    for (final stale in all.skip(maxRecents)) {
      await db.deleteDocument('$collection/${stale.id}');
    }
  });
}

/// `useFakeServices` açıkken örnek katalog, aksi halde Open Food Facts
/// (önbellekli) kullanılır. UI bu seçimi görmez.
final sampleFoodDatabaseProvider = Provider<SampleFoodDatabaseService>(
  (ref) => SampleFoodDatabaseService(),
);

final foodLookupCacheProvider = Provider<FoodLookupCache>(
  (ref) => FoodLookupCache(
    ref.watch(keyValueStorageProvider),
    clock: ref.watch(clockProvider),
  ),
);

final openFoodFactsFoodServiceProvider = Provider<OpenFoodFactsFoodService>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  FoodApiConfig.logContactEmailStatus(
    config.foodApiContactEmail,
    useFakeServices: config.useFakeServices,
  );
  return OpenFoodFactsFoodService(
    DioApiClient.create(
      baseUrl: config.foodDatabaseBaseUrl,
      headers: {
        'User-Agent': FoodApiConfig.userAgentFor(
          contactEmail: config.foodApiContactEmail,
        ),
      },
    ),
  );
});

final remoteFoodCatalogProvider = Provider<CachingFoodDatabaseService>((ref) {
  final remote = ref.watch(openFoodFactsFoodServiceProvider);
  return CachingFoodDatabaseService(
    database: remote,
    barcodes: remote,
    cache: ref.watch(foodLookupCacheProvider),
  );
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final useSample = ref.watch(appConfigProvider).useFakeServices;
  late final FoodDatabaseService database;
  late final BarcodeLookupService barcodes;
  if (useSample) {
    final sample = ref.watch(sampleFoodDatabaseProvider);
    database = sample;
    barcodes = sample;
  } else {
    final remote = ref.watch(remoteFoodCatalogProvider);
    database = remote;
    barcodes = remote;
  }
  return FoodRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
    foodDatabase: database,
    barcodeLookup: barcodes,
    clock: ref.watch(clockProvider),
    analytics: ref.watch(analyticsServiceProvider),
    lookupCache: useSample ? null : ref.watch(foodLookupCacheProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/services/recipe_query.dart';
import '../../domain/services/recipe_recommendation_service.dart';
import '../datasources/recipe_catalog.dart';

/// Katalog tarifleri uygulamayla gelir; kullanıcının tarifleri ve
/// favorileri `users/{uid}/recipes` ve `users/{uid}/favorite_recipes`
/// altında tutulur, başka kullanıcılar göremez.
///
/// Seed katalog kullanıcı Firestore'una kopyalanmaz.
final class RecipeRepositoryImpl extends UserScopedRepository
    implements RecipeRepository {
  const RecipeRepositoryImpl(
    super.db,
    super.uid, {
    List<Recipe> catalog = const [],
    RecipeRecommendationService recommendations =
        const RecipeRecommendationService(),
  }) : _catalog = catalog,
       _recommendations = recommendations;

  final List<Recipe> _catalog;
  final RecipeRecommendationService _recommendations;

  Stream<List<Recipe>> _watchOwn() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.userRecipes(id),
          query: const DocumentQuery(orderBy: 'createdAt', descending: true),
        )
        .map(
          (docs) => [
            for (final d in docs) Recipe.fromJson({...d.data, 'id': d.id}),
          ],
        );
  }

  @override
  Stream<List<Recipe>> watchRecipes() =>
      _watchOwn().map((own) => [...own, ..._catalog]);

  @override
  Stream<Recipe?> watchRecipe(String id) {
    final fromCatalog = _catalog.where((r) => r.id == id).firstOrNull;
    if (fromCatalog != null) return Stream.value(fromCatalog);
    final user = uid;
    if (user == null) return Stream.value(null);
    return db
        .watchDocument('${FirestorePaths.userRecipes(user)}/$id')
        .map(
          (d) => d == null ? null : Recipe.fromJson({...d.data, 'id': d.id}),
        );
  }

  @override
  Future<Result<Recipe>> saveRecipe(Recipe recipe) => guard(() async {
    final user = requireUid();
    final collection = FirestorePaths.userRecipes(user);
    final now = DateTime.now();
    final id = recipe.id.isEmpty ? db.generateId(collection) : recipe.id;
    final existing = await db.getDocument('$collection/$id');
    final created = recipe.createdAt ??
        DateTime.tryParse('${existing?.data['createdAt']}') ??
        now;
    final saved = recipe.copyWith(
      id: id,
      authorId: user,
      source: RecipeSource.user,
      createdAt: created,
      updatedAt: now,
    );
    await db.setDocument('$collection/${saved.id}', saved.toJson());
    return saved;
  });

  @override
  Future<Result<void>> deleteRecipe(String id) => guard(() async {
    final user = requireUid();
    await db.deleteDocument('${FirestorePaths.userRecipes(user)}/$id');
    await db.deleteDocument('${FirestorePaths.favoriteRecipes(user)}/$id');
    await db.deleteDocument('${FirestorePaths.recentRecipes(user)}/$id');
  });

  @override
  Stream<Set<String>> watchFavoriteIds() {
    final id = uid;
    if (id == null) return Stream.value(const {});
    return db
        .watchCollection(FirestorePaths.favoriteRecipes(id))
        .map((docs) => {for (final d in docs) d.id});
  }

  @override
  Future<Result<void>> setFavorite(
    String recipeId, {
    required bool favorite,
  }) => guard(() async {
    final path = '${FirestorePaths.favoriteRecipes(requireUid())}/$recipeId';
    if (favorite) {
      await db.setDocument(path, {
        'recipeId': recipeId,
        'addedAt': DateTime.now().toIso8601String(),
      });
    } else {
      await db.deleteDocument(path);
    }
  });

  @override
  Future<List<Recipe>> getRecipes() => watchRecipes().first;

  @override
  Future<Recipe?> getRecipeById(String id) => watchRecipe(id).first;

  @override
  Future<List<Recipe>> searchRecipes(String query) async =>
      RecipeQuery.search(await getRecipes(), query);

  @override
  Future<List<Recipe>> getRecipesByCategory(String category) async =>
      RecipeQuery.byCategory(await getRecipes(), category);

  @override
  Future<List<Recipe>> getRecipesByMealType(MealType mealType) async =>
      RecipeQuery.byMealType(await getRecipes(), mealType);

  @override
  Future<List<Recipe>> getFavoriteRecipes() async {
    final ids = await watchFavoriteIds().first;
    final all = await getRecipes();
    return [for (final recipe in all) if (ids.contains(recipe.id)) recipe];
  }

  @override
  Future<Result<bool>> toggleFavorite(String recipeId) async {
    final ids = await watchFavoriteIds().first;
    final next = !ids.contains(recipeId);
    final result = await setFavorite(recipeId, favorite: next);
    return result.map((_) => next);
  }

  @override
  Future<List<Recipe>> getRecommendedRecipes(UserProfile? profile) async =>
      _recommendations.recommend(await getRecipes(), profile);

  @override
  Future<List<Recipe>> getRecipesByTags(Set<String> tags) async =>
      RecipeQuery.byTags(await getRecipes(), tags);

  @override
  Stream<List<Recipe>> watchRecent({int limit = 8}) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.recentRecipes(id),
          query: const DocumentQuery(orderBy: 'viewedAt', descending: true),
        )
        .asyncMap((docs) async {
          final all = await getRecipes();
          final byId = {for (final recipe in all) recipe.id: recipe};
          return [
            for (final doc in docs.take(limit)) ?byId[doc.id],
          ];
        });
  }

  @override
  Future<Result<void>> recordView(String recipeId) => guard(() async {
    final id = uid;
    if (id == null || recipeId.isEmpty) return;
    await db.setDocument('${FirestorePaths.recentRecipes(id)}/$recipeId', {
      'recipeId': recipeId,
      'viewedAt': DateTime.now().toIso8601String(),
    });
  });
}

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
    catalog: RecipeCatalog.all,
  ),
);

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/models/recipe_category.dart';
import '../../domain/services/recipe_portion_service.dart';
import '../../domain/services/recipe_query.dart';
import '../../domain/usecases/recipe_usecases.dart';

final recipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchRecipes(),
);

final recipeProvider = StreamProvider.family<Recipe?, String>(
  (ref, id) => ref.watch(recipeRepositoryProvider).watchRecipe(id),
);

final favoriteRecipeIdsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchFavoriteIds(),
);

final recentRecipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchRecent(),
);

final recommendedRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final profile = ref.watch(userProfileProvider).value;
  return ref.watch(recipeRepositoryProvider).getRecommendedRecipes(profile);
});

final recipePortionServiceProvider = Provider<RecipePortionService>(
  (ref) => const RecipePortionService(),
);

final logRecipeProvider = Provider<LogRecipe>(
  (ref) => LogRecipe(
    meals: ref.watch(mealLogRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final addRecipeToPlanProvider = Provider<AddRecipeToPlan>(
  (ref) => AddRecipeToPlan(ref.watch(weeklyMealPlannerProvider)),
);

class RecipeFilter extends Equatable {
  const RecipeFilter({
    this.query = '',
    this.category,
    this.mealType,
    this.tags = const {},
    this.maxCalories,
    this.favoritesOnly = false,
  });

  final String query;
  final RecipeCategory? category;
  final MealType? mealType;
  final Set<String> tags;
  final double? maxCalories;
  final bool favoritesOnly;

  bool get isEmpty =>
      query.trim().isEmpty &&
      category == null &&
      mealType == null &&
      tags.isEmpty &&
      maxCalories == null &&
      !favoritesOnly;

  RecipeCriteria get criteria => RecipeCriteria(
    query: query,
    category: category?.name,
    mealType: mealType,
    tags: tags,
    maxCalories: maxCalories,
    favoritesOnly: favoritesOnly,
  );

  RecipeFilter copyWith({
    String? query,
    RecipeCategory? category,
    bool clearCategory = false,
    MealType? mealType,
    bool clearMealType = false,
    Set<String>? tags,
    double? maxCalories,
    bool clearMaxCalories = false,
    bool? favoritesOnly,
  }) {
    return RecipeFilter(
      query: query ?? this.query,
      category: clearCategory ? null : category ?? this.category,
      mealType: clearMealType ? null : mealType ?? this.mealType,
      tags: tags ?? this.tags,
      maxCalories: clearMaxCalories ? null : maxCalories ?? this.maxCalories,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  @override
  List<Object?> get props => [
    query,
    category,
    mealType,
    tags,
    maxCalories,
    favoritesOnly,
  ];
}

class RecipeFilterController extends Notifier<RecipeFilter> {
  @override
  RecipeFilter build() => const RecipeFilter();

  void search(String query) => state = state.copyWith(query: query);

  /// `null`: tüm kategoriler. Öğün ve favori seçimini kapatır.
  void selectCategory(RecipeCategory? category) => state = state.copyWith(
    category: category,
    clearCategory: category == null,
    clearMealType: true,
    favoritesOnly: false,
  );

  void selectMealType(MealType? mealType) => state = state.copyWith(
    mealType: mealType,
    clearMealType: mealType == null,
    clearCategory: true,
    favoritesOnly: false,
  );

  void toggleTag(String tag) {
    final next = {...state.tags};
    if (!next.add(tag)) next.remove(tag);
    state = state.copyWith(tags: next, favoritesOnly: false);
  }

  void setMaxCalories(double? kcal) => state = state.copyWith(
    maxCalories: kcal,
    clearMaxCalories: kcal == null,
  );

  void showFavorites() => state = state.copyWith(
    clearCategory: true,
    clearMealType: true,
    tags: const {},
    clearMaxCalories: true,
    favoritesOnly: true,
  );

  void clear() => state = const RecipeFilter();
}

final recipeFilterProvider =
    NotifierProvider<RecipeFilterController, RecipeFilter>(
      RecipeFilterController.new,
    );

class RecipeListWindow extends Notifier<int> {
  static const pageSize = 12;

  @override
  int build() {
    ref.watch(recipeFilterProvider);
    return pageSize;
  }

  void loadMore(int total) {
    if (state >= total) return;
    final next = state + pageSize;
    state = next > total ? total : next;
  }
}

final recipeListWindowProvider = NotifierProvider<RecipeListWindow, int>(
  RecipeListWindow.new,
);

/// Aynı ölçüt ve aynı katalog için filtreyi yeniden hesaplamaz.
class RecipeSearchCache {
  String? _key;
  List<Recipe>? _hit;

  List<Recipe> filter(
    List<Recipe> recipes,
    RecipeFilter filter, {
    Set<String> favorites = const {},
  }) {
    final key = [
      recipes.length,
      recipes.firstOrNull?.id,
      recipes.lastOrNull?.id,
      filter.query,
      filter.category?.name,
      filter.mealType?.name,
      filter.tags.join(','),
      filter.maxCalories,
      filter.favoritesOnly,
      favorites.length,
    ].join('|');
    if (key == _key && _hit != null) return _hit!;
    _key = key;
    _hit = RecipeQuery.apply(recipes, filter.criteria, favorites: favorites);
    return _hit!;
  }
}

final recipeSearchCacheProvider = Provider<RecipeSearchCache>(
  (ref) => RecipeSearchCache(),
);

String normalizeSearch(String text) => normalizeRecipeSearch(text);

List<Recipe> filterRecipes(
  List<Recipe> recipes,
  RecipeFilter filter, {
  Set<String> favorites = const {},
}) => RecipeQuery.apply(recipes, filter.criteria, favorites: favorites);

final filteredRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final filter = ref.watch(recipeFilterProvider);
  final favorites = ref.watch(favoriteRecipeIdsProvider).value ?? const {};
  final cache = ref.watch(recipeSearchCacheProvider);
  return ref
      .watch(recipesProvider)
      .whenData(
        (all) => cache.filter(all, filter, favorites: favorites),
      );
});

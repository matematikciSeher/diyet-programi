import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_view.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/models/recipe_category.dart';
import '../../domain/models/recipe_tags.dart';
import '../providers/recipe_providers.dart';
import '../recipe_labels.dart';
import '../widgets/recipe_widgets.dart';

/// Arama, öğün/etiket/kalori filtresi ve sayfalanmış tarif kartları.
class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  late final _search = TextEditingController(
    text: ref.read(recipeFilterProvider).query,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(recipeFilterProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(recipeFilterProvider);
    final recipes = ref.watch(filteredRecipesProvider);
    final favorites = ref.watch(favoriteRecipeIdsProvider).value ?? const {};
    final controller = ref.read(recipeFilterProvider.notifier);
    final window = ref.watch(recipeListWindowProvider);

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      IconData? icon,
    }) => Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: AppSizes.iconSm),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );

    void clearAll() {
      _debounce?.cancel();
      _search.clear();
      controller.clear();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureRecipes)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.recipeCreate),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.recipeCreate),
      ),
      body: Column(
        children: [
          ResponsiveCenter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: SearchBar(
                controller: _search,
                hintText: l10n.recipeSearchHint,
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: _onSearch,
                trailing: [
                  if (_search.text.isNotEmpty || filter.query.isNotEmpty)
                    IconButton(
                      tooltip: l10n.foodClearSearch,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _debounce?.cancel();
                        _search.clear();
                        controller.search('');
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),
          AppSpacing.gapMd,
          SizedBox(
            height: AppSizes.minTouchTarget,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                chip(
                  label: l10n.recipeCategoryAll,
                  selected: filter.isEmpty,
                  onTap: clearAll,
                ),
                chip(
                  label: l10n.recipeFavorites,
                  icon: Icons.favorite_outline_rounded,
                  selected: filter.favoritesOnly,
                  onTap: controller.showFavorites,
                ),
                for (final meal in MealType.values)
                  chip(
                    label: meal.label(l10n),
                    icon: meal.icon,
                    selected: filter.mealType == meal,
                    onTap: () => controller.selectMealType(meal),
                  ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          SizedBox(
            height: AppSizes.minTouchTarget,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                chip(
                  label: l10n.recipeCategoryHighProtein,
                  icon: RecipeCategory.highProtein.icon,
                  selected: filter.tags.contains(RecipeTags.highProtein),
                  onTap: () => controller.toggleTag(RecipeTags.highProtein),
                ),
                chip(
                  label: l10n.recipeCategoryLowCalorie,
                  icon: RecipeCategory.lowCalorie.icon,
                  selected: filter.tags.contains(RecipeTags.lowCalorie),
                  onTap: () => controller.toggleTag(RecipeTags.lowCalorie),
                ),
                chip(
                  label: l10n.recipeVegetarian,
                  icon: Icons.spa_outlined,
                  selected: filter.tags.contains(RecipeTags.vegetarian),
                  onTap: () => controller.toggleTag(RecipeTags.vegetarian),
                ),
                chip(
                  label: l10n.recipeSalad,
                  selected: filter.tags.contains(RecipeTags.salad),
                  onTap: () => controller.toggleTag(RecipeTags.salad),
                ),
                chip(
                  label: l10n.recipeSoup,
                  selected: filter.tags.contains(RecipeTags.soup),
                  onTap: () => controller.toggleTag(RecipeTags.soup),
                ),
                chip(
                  label: l10n.recipePractical,
                  selected: filter.tags.contains(RecipeTags.practical),
                  onTap: () => controller.toggleTag(RecipeTags.practical),
                ),
                for (final cap in const [300, 500])
                  chip(
                    label: l10n.recipeCalorieMax(cap),
                    selected: filter.maxCalories == cap,
                    onTap: () => controller.setMaxCalories(
                      filter.maxCalories == cap ? null : cap.toDouble(),
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: AsyncValueView(
              value: recipes,
              loading: (_) => const SkeletonView(cardHeight: 200),
              onRetry: () => ref.invalidate(recipesProvider),
              data: (list) {
                if (list.isEmpty) {
                  return filter.favoritesOnly && filter.query.isEmpty
                      ? EmptyStateView(
                          icon: Icons.favorite_outline_rounded,
                          title: l10n.recipeFavoritesEmptyTitle,
                          message: l10n.recipeFavoritesEmptyMessage,
                        )
                      : EmptyStateView(
                          icon: Icons.search_off_rounded,
                          title: l10n.recipeNoResults,
                          actionLabel: l10n.recipeClearFilters,
                          onAction: clearAll,
                        );
                }
                final visible = window < list.length ? window : list.length;
                final hasMore = visible < list.length;
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 280) {
                      ref
                          .read(recipeListWindowProvider.notifier)
                          .loadMore(list.length);
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    slivers: [
                      if (filter.isEmpty) ...[
                        _RecentStrip(favorites: favorites),
                        _RecommendedStrip(favorites: favorites),
                      ],
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 280,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisExtent: 270,
                              ),
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final recipe = list[i];
                            return RecipeCard(
                              key: ValueKey('recipe-${recipe.id}'),
                              recipe: recipe,
                              favorite: favorites.contains(recipe.id),
                              onTap: () => context.push(
                                AppRoutes.recipeDetailPath(recipe.id),
                              ),
                            );
                          }, childCount: visible),
                        ),
                      ),
                      if (hasMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              AppSpacing.xxxl * 2,
                            ),
                            child: OutlinedButton(
                              onPressed: () => ref
                                  .read(recipeListWindowProvider.notifier)
                                  .loadMore(list.length),
                              child: Text(l10n.recipeLoadMore),
                            ),
                          ),
                        )
                      else
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.xxxl * 2),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentStrip extends ConsumerWidget {
  const _RecentStrip({required this.favorites});

  final Set<String> favorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentRecipesProvider).value ?? const [];
    if (recent.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return _strip(
      context,
      title: context.l10n.recipeRecentTitle,
      recipes: recent,
      favorites: favorites,
    );
  }
}

class _RecommendedStrip extends ConsumerWidget {
  const _RecommendedStrip({required this.favorites});

  final Set<String> favorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommended = ref.watch(recommendedRecipesProvider).value ?? const [];
    if (recommended.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return _strip(
      context,
      title: context.l10n.recipeRecommendedTitle,
      recipes: recommended.take(8).toList(),
      favorites: favorites,
    );
  }
}

Widget _strip(
  BuildContext context, {
  required String title,
  required List<Recipe> recipes,
  required Set<String> favorites,
}) {
  return SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: recipes.length,
            separatorBuilder: (_, _) => AppSpacing.gapMd,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return SizedBox(
                width: 220,
                child: RecipeCard(
                  recipe: recipe,
                  favorite: favorites.contains(recipe.id),
                  onTap: () =>
                      context.push(AppRoutes.recipeDetailPath(recipe.id)),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

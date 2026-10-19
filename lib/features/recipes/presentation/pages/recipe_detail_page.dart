import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';
import '../../../shopping/presentation/providers/shopping_list_providers.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/models/recipe_category.dart';
import '../../domain/services/recipe_portion_service.dart';
import '../providers/recipe_providers.dart';
import '../recipe_labels.dart';
import '../widgets/recipe_sheets.dart';
import '../widgets/recipe_widgets.dart';

class RecipeDetailPage extends ConsumerStatefulWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> {
  static const _portionChoices = [1, 2, 3];
  var _servings = 1;
  var _recordedView = false;

  Future<void> _log(BuildContext context, Recipe recipe) async {
    final l10n = context.l10n;
    final input = await showLogRecipeSheet(
      context,
      recipe: recipe,
      initialServings: _servings.toDouble(),
    );
    if (input == null || !context.mounted) return;
    final result = await ref
        .read(logRecipeProvider)
        .call(
          recipe,
          mealType: input.meal,
          servings: input.servings,
          servingLabel: l10n.servingsCount(
            AppFormat.decimal(context, input.servings),
          ),
        );
    if (!context.mounted) return;
    switch (result) {
      case Success(value: final entry):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.recipeLogged(recipe.title, input.meal.label(l10n)),
              ),
              action: SnackBarAction(
                label: l10n.actionUndo,
                onPressed: () =>
                    ref.read(logPlannedMealProvider).undo([entry]),
              ),
            ),
          );
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> _addToPlan(BuildContext context, Recipe recipe) async {
    final l10n = context.l10n;
    final today = ref.read(clockProvider)().startOfDay;
    final days = [
      for (var i = 0; i < 7; i++) today.addDays(i),
    ];
    final input = await showAddRecipeToPlanSheet(
      context,
      recipe: recipe,
      days: days,
    );
    if (input == null || !context.mounted) return;
    final result = await ref
        .read(addRecipeToPlanProvider)
        .call(
          recipe,
          day: input.day,
          mealType: input.meal,
          servings: input.servings,
          prefs: ref.read(mealPlanPreferencesProvider),
        );
    if (!context.mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.recipeAddedToPlan(
                  AppFormat.date(context, input.day),
                  input.meal.label(l10n),
                ),
              ),
              action: SnackBarAction(
                label: l10n.recipeOpenPlan,
                onPressed: () => context.push(AppRoutes.nutritionPlan),
              ),
            ),
          );
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> _addToShopping(BuildContext context, Recipe recipe) async {
    final base = recipe.servings <= 0 ? 1 : recipe.servings;
    final count = await ref
        .read(shoppingListActionsProvider)
        .addRecipe(recipe, portionFactor: _servings / base);
    if (!context.mounted) return;
    context.showSnack(
      count == 0
          ? context.l10n.shoppingEmptyMessage
          : context.l10n.recipeAddedToShopping,
    );
  }

  Future<void> _delete(BuildContext context, Recipe recipe) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recipeDeleteTitle),
        content: Text(l10n.recipeDeleteMessage(recipe.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(recipeRepositoryProvider)
        .deleteRecipe(recipe.id);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        context.showSnack(l10n.recipeDeleted);
        context.pop();
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recipeId = widget.recipeId;
    ref.listen(recipeProvider(recipeId), (previous, next) {
      final loaded = next.value;
      if (loaded != null && !_recordedView) {
        _recordedView = true;
        ref.read(recipeRepositoryProvider).recordView(recipeId).ignore();
      }
      if (previous?.value == null && loaded != null) {
        ref
            .read(analyticsServiceProvider)
            .logEvent(
              AnalyticsEvents.recipeOpened,
              parameters: {'source': 'detail'},
            )
            .ignore();
      }
    });
    final recipe = ref.watch(recipeProvider(recipeId));
    final favorite =
        ref.watch(favoriteRecipeIdsProvider).value?.contains(recipeId) ??
        false;
    final loaded = recipe.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(loaded?.title ?? l10n.featureRecipes),
        actions: [
          if (loaded != null)
            IconButton(
              tooltip: favorite
                  ? l10n.recipeRemoveFavorite
                  : l10n.recipeAddFavorite,
              isSelected: favorite,
              icon: const Icon(Icons.favorite_outline_rounded),
              selectedIcon: Icon(
                Icons.favorite_rounded,
                color: context.colors.error,
              ),
              onPressed: () => ref
                  .read(recipeRepositoryProvider)
                  .setFavorite(recipeId, favorite: !favorite),
            ),
          if (loaded?.isUserCreated ?? false)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context, loaded!),
            ),
        ],
      ),
      bottomNavigationBar: loaded == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _addToShopping(context, loaded),
                      icon: const Icon(Icons.shopping_basket_outlined),
                      label: Text(l10n.recipeAddToShopping),
                    ),
                    AppSpacing.gapSm,
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addToPlan(context, loaded),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(l10n.recipeAddToPlan),
                          ),
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _log(context, loaded),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(l10n.recipeLogToday),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      body: AsyncValueView(
        value: recipe,
        onRetry: () => ref.invalidate(recipeProvider(recipeId)),
        data: (r) => r == null
            ? MessageView(
                icon: Icons.search_off_rounded,
                title: l10n.recipeNotFound,
              )
            : _RecipeBody(
                recipe: r,
                servings: _servings,
                onServings: (value) => setState(() => _servings = value),
              ),
      ),
    );
  }
}

class _RecipeBody extends StatelessWidget {
  const _RecipeBody({
    required this.recipe,
    required this.servings,
    required this.onServings,
  });

  final Recipe recipe;
  final int servings;
  final ValueChanged<int> onServings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const portions = RecipePortionService();
    final n = portions.forServings(recipe, servings.toDouble());
    final ingredients = portions.ingredientsForServings(
      recipe,
      servings.toDouble(),
    );
    final variant = context.colors.onSurfaceVariant;
    final nutrition = context.nutritionColors;
    final categories = RecipeCategory.of(recipe);
    String grams(double? v) =>
        v == null ? '—' : l10n.gramsValue(AppFormat.decimal(context, v));

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.gapMd,
              ClipRRect(
                borderRadius: AppRadius.lgAll,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: RecipeImage(recipe: recipe, iconSize: 72),
                ),
              ),
              AppSpacing.gapLg,
              Semantics(
                header: true,
                child: Text(
                  recipe.title,
                  style: context.textStyles.headlineSmall,
                ),
              ),
              if (recipe.description case final description?) ...[
                AppSpacing.gapXs,
                Text(
                  description,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: variant,
                  ),
                ),
              ],
              AppSpacing.gapMd,
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  if ((recipe.prepMinutes ?? 0) > 0)
                    _Meta(
                      icon: Icons.schedule_rounded,
                      text:
                          '${l10n.recipePrepMinutes} ${l10n.recipeMinutes(recipe.prepMinutes!)}',
                    ),
                  if ((recipe.cookMinutes ?? 0) > 0)
                    _Meta(
                      icon: Icons.local_fire_department_outlined,
                      text:
                          '${l10n.recipeCookMinutes} ${l10n.recipeMinutes(recipe.cookMinutes!)}',
                    ),
                  _Meta(
                    icon: Icons.people_outline_rounded,
                    text: l10n.servingsCount(
                      AppFormat.integer(context, recipe.servings),
                    ),
                  ),
                  if (recipe.gramsPerServing case final perServing?)
                    _Meta(
                      icon: Icons.scale_outlined,
                      text: l10n.recipePortionGrams(
                        l10n.gramsValue(
                          AppFormat.integer(context, perServing * servings),
                        ),
                      ),
                    ),
                  if (recipe.isUserCreated)
                    _Meta(
                      icon: Icons.person_outline_rounded,
                      text: l10n.recipeMine,
                    ),
                ],
              ),
              AppSpacing.gapMd,
              Text(
                l10n.recipeSelectedServings,
                style: context.textStyles.labelLarge,
              ),
              AppSpacing.gapSm,
              SegmentedButton<int>(
                key: const ValueKey('recipe-servings'),
                segments: [
                  for (final value in _RecipeDetailPageState._portionChoices)
                    ButtonSegment<int>(
                      value: value,
                      label: Text('$value'),
                    ),
                ],
                selected: {servings},
                onSelectionChanged: (value) => onServings(value.first),
              ),
              if (recipe.isDemo) ...[
                AppSpacing.gapMd,
                Text(
                  l10n.recipeDemoNutrition,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: variant,
                  ),
                ),
              ],
              if (categories.isNotEmpty) ...[
                AppSpacing.gapMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final c in categories)
                      Chip(
                        avatar: Icon(c.icon, size: AppSizes.iconSm),
                        label: Text(c.label(l10n)),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              AppSpacing.gapMd,
              Text(l10n.recipeAllergens, style: context.textStyles.labelLarge),
              AppSpacing.gapSm,
              recipe.allergens.isEmpty
                  ? Text(
                      l10n.recipeNoDeclaredAllergens,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: variant,
                      ),
                    )
                  : Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final name in recipe.allergens)
                          Chip(
                            label: Text(
                              Allergen.tryParse(name)?.label(l10n) ?? name,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
              SectionHeader(
                title: servings == 1
                    ? l10n.recipeNutritionPerServing
                    : '${l10n.recipeNutritionPerServing} · ${l10n.servingsCount(AppFormat.integer(context, servings))}',
              ),
              StatGrid(
                children: [
                  StatTile(
                    label: l10n.nutrientCalories,
                    value: l10n.kcalValue(
                      AppFormat.integer(context, n.calories),
                    ),
                    color: context.colors.primary,
                  ),
                  StatTile(
                    label: l10n.macroProtein,
                    value: grams(n.proteinG),
                    color: nutrition.protein,
                  ),
                  StatTile(
                    label: l10n.macroCarbs,
                    value: grams(n.carbsG),
                    color: nutrition.carbs,
                  ),
                  StatTile(
                    label: l10n.macroFat,
                    value: grams(n.fatG),
                    color: nutrition.fat,
                  ),
                  StatTile(
                    label: l10n.nutrientFiber,
                    value: grams(n.fiberG),
                    color: nutrition.fiber,
                  ),
                ],
              ),
              SectionHeader(title: l10n.recipeIngredients),
              AppCard(
                child: recipe.ingredients.isEmpty
                    ? Text(l10n.recipeNoIngredientList)
                    : Column(
                        children: [
                          for (final i in ingredients)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: context.colors.primary,
                                  ),
                                  AppSpacing.gapMd,
                                  Expanded(child: Text(i.name)),
                                  Text(
                                    [
                                      if (i.quantity > 0)
                                        AppFormat.decimal(context, i.quantity),
                                      i.unit,
                                    ].join(' ').trim(),
                                    style: context.textStyles.bodySmall
                                        ?.copyWith(color: variant),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              SectionHeader(title: l10n.recipeSteps),
              AppCard(
                child: recipe.steps.isEmpty
                    ? Text(l10n.recipeNoSteps)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (index, step) in recipe.steps.indexed)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        context.colors.primaryContainer,
                                    child: Text(
                                      '${index + 1}',
                                      style: context.textStyles.labelMedium
                                          ?.copyWith(
                                            color: context
                                                .colors
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                  ),
                                  AppSpacing.gapMd,
                                  Expanded(child: Text(step)),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final variant = context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: variant),
        AppSpacing.gapXs,
        Text(
          text,
          style: context.textStyles.labelLarge?.copyWith(color: variant),
        ),
      ],
    );
  }
}
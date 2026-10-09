import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../nutrition/presentation/widgets/plan_meal_sheets.dart';
import '../../../recipes/data/repositories/recipe_repository_impl.dart';
import '../../data/repositories/meal_plan_repository_impl.dart';
import '../../domain/models/planned_meal.dart';
import '../../domain/services/personalized_meal_plan_service.dart';
import '../../domain/usecases/weekly_meal_planner.dart';
import '../providers/meal_plan_providers.dart';

/// Profil hedeflerine göre üretilmiş 7 günlük tarif planı.
class MealPlansPage extends ConsumerStatefulWidget {
  const MealPlansPage({super.key});

  @override
  ConsumerState<MealPlansPage> createState() => _MealPlansPageState();
}

class _MealPlansPageState extends ConsumerState<MealPlansPage> {
  var _busy = false;

  Future<void> _regenerate(List<PlannedMeal> current) async {
    final l10n = context.l10n;
    if (current.isNotEmpty) {
      final confirmed = await showAppConfirmDialog(
        context,
        title: l10n.confirmRegenerateWeekTitle,
        message: l10n.confirmRegenerateWeekMessage,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _busy = true);
    final today = ref.read(planDayProvider);
    final result = await ref
        .read(weeklyMealPlannerProvider)
        .regenerate(
          WeeklyMealPlanner.weekDays(today),
          ref.read(mealPlanPreferencesProvider),
          seed: ref.read(clockProvider)().millisecondsSinceEpoch & 0x7fffffff,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Success()) {
      context.showSnack(l10n.planReplyRegenerated);
    } else if (result case Err(:final failure)) {
      context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> _swap(DateTime day, PlannedMeal meal) async {
    final replacement = await showAlternativesSheet(
      context,
      meal: meal,
      load: () => ref
          .read(weeklyMealPlannerProvider)
          .alternatives(day, meal, ref.read(mealPlanPreferencesProvider)),
    );
    if (replacement == null || !mounted) return;
    final result = await ref
        .read(weeklyMealPlannerProvider)
        .replaceMeal(day, replacement);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> _setServings(
    DateTime day,
    PlannedMeal meal,
    int servings,
  ) async {
    if (meal.portionFactor == servings) return;
    final recipeId = meal.recipeId;
    final recipe = recipeId == null
        ? null
        : await ref.read(recipeRepositoryProvider).getRecipeById(recipeId);
    final next = ref
        .read(personalizedMealPlanServiceProvider)
        .withServings(meal, servings.toDouble(), recipe: recipe);
    final result = await ref
        .read(mealPlanRepositoryProvider)
        .updateMealPortion(day, next);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> _log(PlannedMeal meal) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(logPlannedMealProvider)(
      meal,
      servingLabel: (item) => item.amount,
      mealServingLabel: l10n.servingsCount(
        AppFormat.decimal(context, meal.portionFactor),
      ),
    );
    if (!mounted) return;
    result.when(
      success: (entries) => messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.planMealLogged(meal.mealType.label(l10n))),
            action: SnackBarAction(
              label: l10n.actionUndo,
              onPressed: () => ref.read(logPlannedMealProvider).undo(entries),
            ),
          ),
        ),
      failure: (failure) =>
          context.showSnack(failure.localizedMessage(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ref.watch(planDayProvider);
    final selected = ref.watch(planScreenDayProvider);
    final week = WeeklyMealPlanner.weekDays(today);
    final plan = ref.watch(weeklyMealPlanProvider);
    final logged = ref.watch(loggedMealTypesProvider(today)).value ?? const {};
    final target = ref.watch(mealPlanPreferencesProvider).dailyCalories;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.featureMealPlans),
        actions: [
          IconButton(
            tooltip: l10n.planRegenerate,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _busy ? null : () => _regenerate(plan.value ?? const []),
          ),
          IconButton(
            tooltip: l10n.featureShoppingList,
            icon: const Icon(Icons.shopping_basket_outlined),
            onPressed: () => context.push(AppRoutes.shoppingList),
          ),
        ],
      ),
      body: AsyncValueView(
        value: plan,
        onRetry: () => ref.invalidate(weeklyMealPlanProvider),
        data: (meals) {
          if (meals.isEmpty) {
            return MessageView(
              icon: Icons.calendar_month_outlined,
              title: l10n.planEmpty,
              actionLabel: l10n.planCreate,
              onAction: _busy ? null : () => _regenerate(meals),
            );
          }
          final selectedMeals = [
            for (final meal in meals)
              if (meal.dayKey == selected.dayKey) meal,
          ];
          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xxxl,
            ),
            children: [
              ResponsiveCenter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.weeklyPlanTitle,
                      style: context.textStyles.headlineSmall,
                    ),
                    AppSpacing.gapXs,
                    Text(
                      l10n.nutritionPlanWeekRange(
                        AppFormat.date(context, week.first),
                        AppFormat.date(context, week.last),
                      ),
                      style: context.textStyles.titleMedium,
                    ),
                    AppSpacing.gapXs,
                    Text(
                      '${l10n.nutritionPlanDailyTarget}: ${l10n.kcalValue(AppFormat.integer(context, target))}',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapLg,
                    _WeekDays(
                      week: week,
                      meals: meals,
                      selected: selected,
                      today: today,
                      onSelect: (day) =>
                          ref.read(planScreenDayProvider.notifier).select(day),
                    ),
                    AppSpacing.gapLg,
                    Text(
                      DateFormat.yMMMMEEEEd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(selected),
                      style: context.textStyles.titleLarge,
                    ),
                    AppSpacing.gapXs,
                    _MacroLine(
                      total: selectedMeals.fold(
                        NutritionFacts.zero,
                        (sum, meal) => sum + meal.nutrition,
                      ),
                    ),
                    AppSpacing.gapMd,
                    for (final meal in selectedMeals) ...[
                      _RecipeMealCard(
                        meal: meal,
                        logged:
                            selected.isSameDay(today) &&
                            logged.contains(meal.mealType),
                        onOpen: meal.recipeId == null
                            ? null
                            : () => context.push(
                                AppRoutes.recipeDetailPath(meal.recipeId!),
                              ),
                        onSwap: _busy ? null : () => _swap(selected, meal),
                        onLog: () => _log(meal),
                        onServings: (servings) =>
                            _setServings(selected, meal, servings),
                      ),
                      AppSpacing.gapMd,
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeekDays extends StatelessWidget {
  const _WeekDays({
    required this.week,
    required this.meals,
    required this.selected,
    required this.today,
    required this.onSelect,
  });

  final List<DateTime> week;
  final List<PlannedMeal> meals;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(locale);
    final colors = context.colors;
    return Row(
      children: [
        for (final day in week)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: _DayChip(
                key: ValueKey('plan-day-${day.dayKey}'),
                label: weekday.format(day),
                dayOfMonth: day.day,
                calories: meals
                    .where((meal) => meal.dayKey == day.dayKey)
                    .fold<double>(
                      0,
                      (sum, meal) => sum + meal.nutrition.calories,
                    ),
                selected: day.isSameDay(selected),
                today: day.isSameDay(today),
                onTap: () => onSelect(day),
                selectedColor: colors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    super.key,
    required this.label,
    required this.dayOfMonth,
    required this.calories,
    required this.selected,
    required this.today,
    required this.onTap,
    required this.selectedColor,
  });

  final String label;
  final int dayOfMonth;
  final double calories;
  final bool selected;
  final bool today;
  final VoidCallback onTap;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? selectedColor : colors.surfaceContainerHighest,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: today && !selected
                ? BoxDecoration(
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: selectedColor, width: 1.5),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    label,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                Text(
                  '$dayOfMonth',
                  style: context.textStyles.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FittedBox(
                  child: Text(
                    AppFormat.integer(context, calories),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  const _MacroLine({required this.total});

  final NutritionFacts total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String grams(double value) => AppFormat.integer(context, value);
    return Text(
      '${l10n.kcalValue(grams(total.calories))} · '
      '${l10n.macroSummaryShort(grams(total.proteinG), grams(total.carbsG), grams(total.fatG))} · '
      '${l10n.macroFiber} ${l10n.gramsValue(grams(total.fiberG ?? 0))}',
      style: context.textStyles.bodyMedium?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
  }
}

class _RecipeMealCard extends StatelessWidget {
  const _RecipeMealCard({
    required this.meal,
    required this.logged,
    required this.onOpen,
    required this.onSwap,
    required this.onLog,
    required this.onServings,
  });

  final PlannedMeal meal;
  final bool logged;
  final VoidCallback? onOpen;
  final VoidCallback? onSwap;
  final VoidCallback onLog;
  final ValueChanged<int> onServings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final n = meal.nutrition;
    final variant = context.colors.onSurfaceVariant;
    String grams(double value) => AppFormat.integer(context, value);
    final selected = PersonalizedMealPlanService.snapServings(
      meal.portionFactor,
    ).round();

    return AppCard(
      key: ValueKey('planned-${meal.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meal.mealType.icon, color: context.colors.primary),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  meal.mealType.label(l10n),
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          InkWell(
            onTap: onOpen,
            child: Text(
              meal.title,
              style: context.textStyles.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: onOpen == null ? null : TextDecoration.underline,
              ),
            ),
          ),
          AppSpacing.gapXs,
          Text(
            '${l10n.servingsCount(AppFormat.decimal(context, meal.portionFactor))} · '
            '${l10n.kcalValue(grams(n.calories))} · '
            '${l10n.macroSummaryShort(grams(n.proteinG), grams(n.carbsG), grams(n.fatG))}',
            style: context.textStyles.labelMedium?.copyWith(color: variant),
          ),
          AppSpacing.gapMd,
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final value in const [1, 2, 3])
                ButtonSegment<int>(value: value, label: Text('$value')),
            ],
            selected: {selected},
            onSelectionChanged: (value) => onServings(value.first),
          ),
          AppSpacing.gapSm,
          OverflowBar(
            spacing: AppSpacing.sm,
            overflowSpacing: AppSpacing.xs,
            children: [
              TextButton.icon(
                onPressed: onSwap,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(l10n.planChangeRecipe),
              ),
              if (logged)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: context.nutritionColors.success,
                      size: AppSizes.iconSm,
                    ),
                    AppSpacing.gapXs,
                    Text(
                      l10n.planLogged,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: context.nutritionColors.success,
                      ),
                    ),
                  ],
                )
              else
                FilledButton.tonalIcon(
                  onPressed: onLog,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.nutritionPlanLogToday),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

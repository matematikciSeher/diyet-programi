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
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/skeleton_view.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../../meal_plans/domain/models/plan_item.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';
import '../providers/nutrition_plan_providers.dart';
import '../widgets/new_plan_sheet.dart';
import '../widgets/plan_meal_sheets.dart';

/// "Beslenme Planım": profil hedefleri, Pazartesi–Pazar gün seçimi ve
/// seçili günün öğünleri. Öğünler günlüğe eklenebilir veya
/// değiştirilebilir; "Yeni Plan Oluştur" profil tercihlerini günceller.
class NutritionPlanPage extends ConsumerWidget {
  const NutritionPlanPage({super.key});

  Future<void> _newPlan(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final profile = ref.read(userProfileProvider).value;
    final day = ref.read(selectedPlanDayProvider);
    final existing = ref.read(mealPlanForDayProvider(day)).value;
    if (existing != null && existing.isNotEmpty) {
      final confirmed = await showAppConfirmDialog(
        context,
        title: l10n.confirmNewPlanTitle,
        message: l10n.confirmNewPlanMessage,
      );
      if (!confirmed || !context.mounted) return;
    }
    final input = await showNewPlanSheet(context, profile: profile);
    if (input == null || !context.mounted) return;
    final result = await ref
        .read(nutritionPlanActionsProvider)
        .createNewPlan(input);
    if (!context.mounted) return;
    context.showSnack(switch (result) {
      Success() => l10n.nutritionPlanCreated,
      Err(:final failure) => failure.localizedMessage(context),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final day = ref.watch(selectedPlanDayProvider);
    final plan = ref.watch(mealPlanForDayProvider(day));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.featureNutrition),
        actions: [
          IconButton(
            tooltip: l10n.featureShoppingList,
            icon: const Icon(Icons.shopping_basket_outlined),
            onPressed: () => context.push(AppRoutes.shoppingList),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xxxl,
        ),
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GoalsCard(profile: profile),
                AppSpacing.gapLg,
                const _WeekSelector(),
                AppSpacing.gapLg,
                if (profile?.isFasting ?? false) ...[
                  _FastingWindowHint(profile: profile!),
                  AppSpacing.gapMd,
                ],
                AsyncValueView(
                  value: plan,
                  loading: (_) => Column(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        const SkeletonBox(height: 76, radius: AppRadius.lgAll),
                        AppSpacing.gapSm,
                      ],
                    ],
                  ),
                  onRetry: () => ref.invalidate(mealPlanForDayProvider(day)),
                  data: (meals) => meals.isEmpty
                      ? EmptyStateView(
                          icon: Icons.calendar_month_outlined,
                          title: l10n.planEmpty,
                          actionLabel: l10n.nutritionPlanCreate,
                          onAction: () => _newPlan(context, ref),
                        )
                      : _DayMeals(day: day, meals: meals),
                ),
                AppSpacing.gapLg,
                FilledButton.icon(
                  onPressed: () => _newPlan(context, ref),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(l10n.nutritionPlanCreate),
                ),
                AppSpacing.gapSm,
                Text(
                  l10n.planApproxNote,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final targets = profile?.nutritionTargets ?? NutritionTargets.fallback;
    final goal = profile?.goal;
    final nutrition = context.nutritionColors;
    final variant = context.colors.onSurfaceVariant;

    Widget macro(String label, double grams, Color color) => Expanded(
      child: Column(
        children: [
          Text(
            l10n.gramsValue(AppFormat.integer(context, grams)),
            style: context.textStyles.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(color: variant),
          ),
        ],
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.nutritionPlanTitle,
              style: context.textStyles.headlineSmall,
            ),
          ),
          if (goal != null) ...[
            AppSpacing.gapXs,
            Text(
              l10n.nutritionPlanGoal(goal.label(l10n)),
              style: context.textStyles.bodyMedium?.copyWith(color: variant),
            ),
          ],
          AppSpacing.gapLg,
          Text(
            l10n.kcalValue(AppFormat.integer(context, targets.calories)),
            textAlign: TextAlign.center,
            style: context.textStyles.headlineMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            l10n.nutritionPlanDailyTarget,
            textAlign: TextAlign.center,
            style: context.textStyles.labelMedium?.copyWith(color: variant),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              macro(l10n.macroProtein, targets.proteinG, nutrition.protein),
              macro(l10n.macroCarbs, targets.carbsG, nutrition.carbs),
              macro(l10n.macroFat, targets.fatG, nutrition.fat),
            ],
          ),
          AppSpacing.gapMd,
          Align(
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.personalInfo),
              icon: const Icon(Icons.tune_rounded),
              label: Text(l10n.nutritionPlanEditGoals),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekSelector extends ConsumerWidget {
  const _WeekSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(selectedPlanDayProvider);
    final week = ref.watch(selectedWeekProvider);
    final today = ref.watch(clockProvider)().startOfDay;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(locale);
    final controller = ref.read(selectedPlanDayProvider.notifier);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.nutritionPlanPreviousWeek,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => controller.shiftWeek(-1),
            ),
            Expanded(
              child: Text(
                l10n.nutritionPlanWeekRange(
                  AppFormat.date(context, week.first),
                  AppFormat.date(context, week.last),
                ),
                textAlign: TextAlign.center,
                style: context.textStyles.titleSmall,
              ),
            ),
            IconButton(
              tooltip: l10n.nutritionPlanNextWeek,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => controller.shiftWeek(1),
            ),
          ],
        ),
        AppSpacing.gapSm,
        Row(
          children: [
            for (final day in week)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                  ),
                  child: _DayChip(
                    key: ValueKey('plan-day-${day.dayKey}'),
                    weekday: weekday.format(day),
                    dayOfMonth: day.day,
                    selected: day.isSameDay(selected),
                    today: day.isSameDay(today),
                    onTap: () => controller.select(day),
                    selectedColor: colors.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    super.key,
    required this.weekday,
    required this.dayOfMonth,
    required this.selected,
    required this.today,
    required this.onTap,
    required this.selectedColor,
  });

  final String weekday;
  final int dayOfMonth;
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
              minHeight: AppSizes.minTouchTarget + AppSpacing.md,
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
                    weekday,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                Text(
                  '$dayOfMonth',
                  style: context.textStyles.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
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

class _FastingWindowHint extends StatelessWidget {
  const _FastingWindowHint({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final start = profile.effectiveEatingWindowStart;
    final hours = profile.fastingPreference!.eatingHours;
    String time(int minutes) => AppFormat.minutesOfDay(context, minutes);
    return AppCard(
      onTap: () => context.push(AppRoutes.fasting),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: context.colors.primary),
          AppSpacing.gapMd,
          Expanded(
            child: Text(
              l10n.nutritionPlanEatingWindow(
                time(start),
                time(start + hours * 60),
              ),
              style: context.textStyles.bodyMedium,
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _DayMeals extends ConsumerWidget {
  const _DayMeals({required this.day, required this.meals});

  final DateTime day;
  final List<PlannedMeal> meals;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    PlannedMeal meal,
    bool logged,
  ) async {
    final action = await showPlannedMealSheet(
      context,
      meal: meal,
      loggedToday: logged,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case PlannedMealAction.logToday:
        await _log(context, ref, meal);
      case PlannedMealAction.swap:
        await _swap(context, ref, meal);
      case PlannedMealAction.openRecipe:
        final id = meal.recipeId;
        if (id != null) await context.push(AppRoutes.recipeDetailPath(id));
    }
  }

  Future<void> _log(
    BuildContext context,
    WidgetRef ref,
    PlannedMeal meal,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(nutritionPlanActionsProvider);
    final factor = meal.portionFactor == 1
        ? null
        : AppFormat.decimal(context, meal.portionFactor, digits: 2);
    final result = await actions.logToToday(
      meal,
      servingLabel: (PlanItem item) =>
          factor == null ? item.amount : '${item.amount} × $factor',
      mealServingLabel: l10n.servingsCount(
        AppFormat.decimal(context, meal.portionFactor),
      ),
    );
    if (!context.mounted) return;
    switch (result) {
      case Success(value: final entries):
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.planMealLogged(meal.mealType.label(l10n))),
              action: SnackBarAction(
                label: l10n.actionUndo,
                onPressed: () => actions.undoLog(entries),
              ),
            ),
          );
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> _swap(
    BuildContext context,
    WidgetRef ref,
    PlannedMeal meal,
  ) async {
    final l10n = context.l10n;
    final actions = ref.read(nutritionPlanActionsProvider);
    final choice = await showAlternativesSheet(
      context,
      meal: meal,
      load: () => actions.alternatives(day, meal),
    );
    if (choice == null || !context.mounted) return;
    final result = await actions.replace(day, choice);
    if (!context.mounted) return;
    context.showSnack(switch (result) {
      Success() => l10n.planMealSwapped(
        meal.mealType.label(l10n),
        choice.title,
      ),
      Err(:final failure) => failure.localizedMessage(context),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = ref.watch(clockProvider)().startOfDay;
    final isToday = day.isSameDay(today);
    final logged = isToday
        ? ref.watch(loggedMealTypesProvider(today)).value ?? const <MealType>{}
        : const <MealType>{};
    final target = ref.watch(mealPlanPreferencesProvider).dailyCalories;
    final total = meals.fold(NutritionFacts.zero, (sum, m) => sum + m.nutrition);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardTitle(
          icon: Icons.restaurant_menu_rounded,
          title: isToday
              ? l10n.nutritionPlanToday
              : AppFormat.date(context, day),
          color: context.colors.primary,
          trailing: Text(
            l10n.planDayTotal(
              AppFormat.integer(context, total.calories),
              AppFormat.integer(context, target),
            ),
            style: context.textStyles.labelLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        AppSpacing.gapMd,
        for (final meal in meals) ...[
          PlanMealTile(
            key: ValueKey('plan-meal-${meal.id}'),
            meal: meal,
            logged: logged.contains(meal.mealType),
            onTap: () =>
                _open(context, ref, meal, logged.contains(meal.mealType)),
          ),
          AppSpacing.gapSm,
        ],
      ],
    );
  }
}

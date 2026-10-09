import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/models/recipe_category.dart';
import '../../domain/services/recipe_portion_service.dart';

typedef RecipeLogInput = ({MealType meal, double servings});
typedef RecipePlanInput = ({DateTime day, MealType meal, double servings});

const _mealOrder = [
  MealType.breakfast,
  MealType.lunch,
  MealType.dinner,
  MealType.snack,
];

Future<RecipeLogInput?> showLogRecipeSheet(
  BuildContext context, {
  required Recipe recipe,
  double initialServings = 1,
}) => showModalBottomSheet<RecipeLogInput>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _RecipeTargetSheet(
    recipe: recipe,
    initialServings: initialServings,
  ),
);

/// [days] arasından gün seçtirilir (ör. bu haftanın kalan günleri).
Future<RecipePlanInput?> showAddRecipeToPlanSheet(
  BuildContext context, {
  required Recipe recipe,
  required List<DateTime> days,
}) => showModalBottomSheet<RecipePlanInput>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _RecipeTargetSheet(recipe: recipe, days: days),
);

class _RecipeTargetSheet extends StatefulWidget {
  const _RecipeTargetSheet({
    required this.recipe,
    this.days,
    this.initialServings = 1,
  });

  final Recipe recipe;

  /// `null`: günlüğe ekleme (bugün).
  final List<DateTime>? days;
  final double initialServings;

  @override
  State<_RecipeTargetSheet> createState() => _RecipeTargetSheetState();
}

class _RecipeTargetSheetState extends State<_RecipeTargetSheet> {
  static const _step = 0.5;
  static const _maxServings = 10.0;

  late MealType _meal = RecipeCategory.defaultMealType(widget.recipe);
  late DateTime? _day = widget.days?.firstOrNull;
  late double _servings = widget.initialServings;

  void _submit() {
    final day = _day;
    Navigator.of(context).pop(
      widget.days == null || day == null
          ? (meal: _meal, servings: _servings)
          : (day: day, meal: _meal, servings: _servings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = widget.days;
    final n = const RecipePortionService().forServings(
      widget.recipe,
      _servings,
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayFormat = DateFormat.MMMEd(locale);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            days == null ? l10n.recipeLogToday : l10n.recipeAddToPlan,
            style: context.textStyles.titleLarge,
          ),
          AppSpacing.gapXs,
          Text(
            widget.recipe.title,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (days != null) ...[
            AppSpacing.gapLg,
            Text(l10n.recipePickDay, style: context.textStyles.labelLarge),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final d in days)
                  ChoiceChip(
                    key: ValueKey('recipe-plan-day-${d.dayKey}'),
                    label: Text(dayFormat.format(d)),
                    selected: _day != null && d.isSameDay(_day!),
                    onSelected: (_) => setState(() => _day = d),
                  ),
              ],
            ),
          ],
          AppSpacing.gapLg,
          Text(l10n.recipePickMeal, style: context.textStyles.labelLarge),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final meal in _mealOrder)
                ChoiceChip(
                  avatar: Icon(meal.icon, size: AppSizes.iconSm),
                  label: Text(meal.label(l10n)),
                  selected: _meal == meal,
                  onSelected: (_) => setState(() => _meal = meal),
                ),
            ],
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.recipeServingsLabel,
                  style: context.textStyles.labelLarge,
                ),
              ),
              IconButton.outlined(
                tooltip: l10n.recipeLessServings,
                onPressed: _servings > _step
                    ? () => setState(() => _servings -= _step)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  AppFormat.decimal(context, _servings),
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium,
                ),
              ),
              IconButton.outlined(
                tooltip: l10n.recipeMoreServings,
                onPressed: _servings < _maxServings
                    ? () => setState(() => _servings += _step)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            '${l10n.kcalValue(AppFormat.integer(context, n.calories))} · '
            '${l10n.macroSummaryShort(AppFormat.integer(context, n.proteinG), AppFormat.integer(context, n.carbsG), AppFormat.integer(context, n.fatG))}',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapXl,
          FilledButton(
            onPressed: days != null && _day == null ? null : _submit,
            child: Text(days == null ? l10n.recipeLogToday : l10n.recipeAddToPlan),
          ),
        ],
      ),
    );
  }
}

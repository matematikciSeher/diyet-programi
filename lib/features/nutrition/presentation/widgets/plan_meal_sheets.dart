import 'package:flutter/material.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';

enum PlannedMealAction { logToday, swap, openRecipe }

String _macroLine(BuildContext context, PlannedMeal meal) {
  final l10n = context.l10n;
  final n = meal.nutrition;
  return '${l10n.kcalValue(AppFormat.integer(context, n.calories))} · '
      '${l10n.macroSummaryShort(AppFormat.integer(context, n.proteinG), AppFormat.integer(context, n.carbsG), AppFormat.integer(context, n.fatG))}';
}

/// Haftalık plandaki tek öğün satırı; dokununca eylem sayfası açılır.
class PlanMealTile extends StatelessWidget {
  const PlanMealTile({
    super.key,
    required this.meal,
    required this.logged,
    required this.onTap,
  });

  final PlannedMeal meal;
  final bool logged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final variant = context.colors.onSurfaceVariant;
    final time = meal.timeMinutes;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.colors.primaryContainer,
            foregroundColor: context.colors.onPrimaryContainer,
            child: Icon(meal.mealType.icon),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    meal.mealType.label(l10n),
                    if (time != null) AppFormat.minutesOfDay(context, time),
                  ].join(' · '),
                  style: context.textStyles.labelMedium?.copyWith(
                    color: variant,
                  ),
                ),
                Text(
                  meal.title,
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _macroLine(context, meal),
                  style: context.textStyles.labelMedium?.copyWith(
                    color: variant,
                  ),
                ),
              ],
            ),
          ),
          if (logged)
            Tooltip(
              message: l10n.planLogged,
              child: Icon(
                Icons.check_circle_rounded,
                color: context.nutritionColors.success,
              ),
            )
          else
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

Future<PlannedMealAction?> showPlannedMealSheet(
  BuildContext context, {
  required PlannedMeal meal,
  required bool loggedToday,
}) => showModalBottomSheet<PlannedMealAction>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) {
    final l10n = context.l10n;
    final variant = context.colors.onSurfaceVariant;
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
            meal.mealType.label(l10n),
            style: context.textStyles.labelLarge?.copyWith(color: variant),
          ),
          Text(meal.title, style: context.textStyles.titleLarge),
          AppSpacing.gapXs,
          Text(
            _macroLine(context, meal),
            style: context.textStyles.bodyMedium?.copyWith(color: variant),
          ),
          if (meal.items.isNotEmpty) ...[
            AppSpacing.gapMd,
            for (final item in meal.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: ExcludeSemantics(
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    Expanded(child: Text(item.name)),
                    Text(
                      item.amount,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: variant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (loggedToday) ...[
            AppSpacing.gapMd,
            Text(
              l10n.nutritionPlanAlreadyLogged,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.nutritionColors.success,
              ),
            ),
          ],
          AppSpacing.gapLg,
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(PlannedMealAction.logToday),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.nutritionPlanLogToday),
          ),
          AppSpacing.gapSm,
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(PlannedMealAction.swap),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(l10n.nutritionPlanSwap),
          ),
          if (meal.recipeId != null) ...[
            AppSpacing.gapSm,
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(PlannedMealAction.openRecipe),
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(l10n.nutritionPlanOpenRecipe),
            ),
          ],
        ],
      ),
    );
  },
);

/// Kısıtlara uyan alternatifleri listeler; seçilen öğünü döndürür.
Future<PlannedMeal?> showAlternativesSheet(
  BuildContext context, {
  required PlannedMeal meal,
  required Future<Result<List<PlannedMeal>>> Function() load,
}) => showModalBottomSheet<PlannedMeal>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AlternativesSheet(meal: meal, load: load),
);

class _AlternativesSheet extends StatefulWidget {
  const _AlternativesSheet({required this.meal, required this.load});

  final PlannedMeal meal;
  final Future<Result<List<PlannedMeal>>> Function() load;

  @override
  State<_AlternativesSheet> createState() => _AlternativesSheetState();
}

class _AlternativesSheetState extends State<_AlternativesSheet> {
  late final Future<Result<List<PlannedMeal>>> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
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
            l10n.nutritionPlanAlternativesTitle(
              widget.meal.mealType.label(l10n),
            ),
            style: context.textStyles.titleLarge,
          ),
          AppSpacing.gapXs,
          Text(
            l10n.nutritionPlanAlternativesSubtitle,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapLg,
          FutureBuilder(
            future: _future,
            builder: (context, snapshot) {
              final result = snapshot.data;
              if (result == null) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return switch (result) {
                Err(:final failure) => Text(failure.localizedMessage(context)),
                Success(value: final options) when options.isEmpty =>
                  MessageView(
                    icon: Icons.search_off_rounded,
                    title: l10n.planReplyNoAlternative(
                      widget.meal.mealType.label(l10n),
                    ),
                  ),
                Success(value: final options) => Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final option in options) ...[
                        AppCard(
                          key: ValueKey(
                            'alternative-${option.recipeId ?? option.templateId ?? option.title}',
                          ),
                          onTap: () => Navigator.of(context).pop(option),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.title,
                                style: context.textStyles.titleSmall,
                              ),
                              AppSpacing.gapXs,
                              Text(
                                _macroLine(context, option),
                                style: context.textStyles.labelMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapSm,
                      ],
                    ],
                  ),
                ),
              };
            },
          ),
        ],
      ),
    );
  }
}

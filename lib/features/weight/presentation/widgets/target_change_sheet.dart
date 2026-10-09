import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/nutrition/nutrition_calculator.dart';
import '../../../../shared/services/nutrition/profile_targets_service.dart';
import '../providers/weight_providers.dart';

enum TargetChangeDecision { useNew, keepCurrent }

Future<TargetChangeDecision?> showTargetChangeSheet(
  BuildContext context, {
  required TargetSuggestion suggestion,
}) => showModalBottomSheet<TargetChangeDecision>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => TargetChangeSheet(suggestion: suggestion),
);

class TargetChangeSheet extends StatelessWidget {
  const TargetChangeSheet({super.key, required this.suggestion});

  final TargetSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        top: AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.targetChangeTitle, style: context.textStyles.titleLarge),
            AppSpacing.gapLg,
            TargetChangeComparison(suggestion: suggestion),
            AppSpacing.gapLg,
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(TargetChangeDecision.useNew),
              child: Text(l10n.targetChangeUseNew),
            ),
            AppSpacing.gapSm,
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pop(TargetChangeDecision.keepCurrent),
              child: Text(l10n.targetChangeKeepCurrent),
            ),
          ],
        ),
      ),
    );
  }
}

class TargetChangeComparison extends StatelessWidget {
  const TargetChangeComparison({super.key, required this.suggestion});

  final TargetSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = suggestion.currentCalories;
    String kcal(int v) => l10n.kcalValue(AppFormat.integer(context, v));
    String kg(double v) => '${AppFormat.decimal(context, v)} kg';

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textStyles.bodyMedium)),
          Text(
            value,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (suggestion.hasWeightChange) ...[
            row(l10n.targetChangeCurrentWeight, kg(suggestion.previousWeightKg!)),
            row(l10n.targetChangeNewWeight, kg(suggestion.weightKg!)),
            const Divider(),
          ],
          if (current != null)
            row(l10n.targetChangeCurrentCalories, kcal(current)),
          row(l10n.targetChangeNewCalories, kcal(suggestion.calories)),
          AppSpacing.gapSm,
          Text(
            l10n.targetChangeMacros(
              AppFormat.integer(context, suggestion.proteinG),
              AppFormat.integer(context, suggestion.carbsG),
              AppFormat.integer(context, suggestion.fatG),
            ),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (suggestion.limited ||
              suggestion.notices.contains(HealthNotice.calorieFloorApplied)) ...[
            AppSpacing.gapSm,
            Text(
              suggestion.limited
                  ? l10n.targetSuggestionLimited
                  : l10n.targetChangeSafety,
              style: context.textStyles.bodySmall,
            ),
          ],
          AppSpacing.gapSm,
          Text(
            l10n.targetChangeSafety,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> applyTargetChangeDecision(
  WidgetRef ref,
  TargetSuggestion suggestion,
  TargetChangeDecision decision,
) async {
  if (decision == TargetChangeDecision.useNew) {
    await ref.read(applyTargetSuggestionProvider)(suggestion);
  } else {
    await ref.read(keepCurrentTargetProvider)(suggestion);
  }
}

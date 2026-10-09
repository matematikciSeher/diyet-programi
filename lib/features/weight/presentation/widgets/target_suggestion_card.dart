import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../providers/weight_providers.dart';
import 'target_change_sheet.dart';

/// Kilo veya profil değişince yeniden hesaplanan hedefi önerir; kullanıcı
/// onaylamadan profil değişmez.
class TargetSuggestionCard extends ConsumerWidget {
  const TargetSuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(targetSuggestionProvider);
    if (suggestion == null) return const SizedBox.shrink();
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        color: context.colors.secondaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: context.colors.onSecondaryContainer,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    l10n.targetSuggestionTitle,
                    style: context.textStyles.titleSmall?.copyWith(
                      color: context.colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            TargetChangeComparison(suggestion: suggestion),
            AppSpacing.gapXs,
            Text(
              l10n.macroSummaryShort(
                AppFormat.integer(context, suggestion.proteinG),
                AppFormat.integer(context, suggestion.carbsG),
                AppFormat.integer(context, suggestion.fatG),
              ),
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSecondaryContainer,
              ),
            ),
            if (suggestion.limited) ...[
              AppSpacing.gapXs,
              Text(
                l10n.targetSuggestionLimited,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSecondaryContainer,
                ),
              ),
            ],
            AppSpacing.gapXs,
            Text(
              l10n.targetSuggestionNote,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSecondaryContainer,
              ),
            ),
            AppSpacing.gapMd,
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: () =>
                      ref.read(keepCurrentTargetProvider)(suggestion),
                  child: Text(l10n.targetChangeKeepCurrent),
                ),
                FilledButton(
                  onPressed: () async {
                    await ref.read(applyTargetSuggestionProvider)(suggestion);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(l10n.targetSuggestionApplied),
                          action: SnackBarAction(
                            label: l10n.featureNutrition,
                            onPressed: () =>
                                context.push(AppRoutes.nutritionPlan),
                          ),
                        ),
                      );
                  },
                  child: Text(l10n.targetChangeUseNew),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

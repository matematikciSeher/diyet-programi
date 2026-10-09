import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../providers/diary_providers.dart';

/// Su tüketimi: hedefe göre ilerleme, bardaklar, hızlı ekleme/azaltma.
class DiaryWaterCard extends ConsumerWidget {
  const DiaryWaterCard({
    super.key,
    required this.onAdd,
    required this.onRemove,
  });

  static const glassMl = 250;
  static const quickAmounts = [100, 250, 500];

  /// Hedef çok yüksek olsa da satır taşmasın diye.
  static const _maxGlassIcons = 16;

  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final color = context.nutritionColors.water;
    final water = ref.watch(waterProgressProvider);
    final consumed = water?.consumedMl ?? 0;
    final int goal =
        water?.goalMl ??
        ref.watch(diaryTargetsProvider.select<int>((t) => t.waterMl));
    final glassCount = (goal / glassMl).ceil().clamp(1, _maxGlassIcons);
    final filled = consumed ~/ glassMl;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.water_drop_rounded,
            title: l10n.diaryWaterTitle,
            color: color,
            trailing: Text(
              l10n.diaryWaterOfGoal(
                AppFormat.integer(context, consumed),
                AppFormat.integer(context, goal),
              ),
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AppSpacing.gapMd,
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                end: goal <= 0 ? 0 : (consumed / goal).clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.16),
              ),
            ),
          ),
          AppSpacing.gapMd,
          ExcludeSemantics(
            child: Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (var i = 0; i < glassCount; i++)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      i < filled
                          ? Icons.water_drop_rounded
                          : Icons.water_drop_outlined,
                      key: ValueKey(i < filled),
                      size: 22,
                      color: i < filled ? color : context.colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (water?.reachedGoal ?? false) ...[
            AppSpacing.gapSm,
            Text(
              l10n.waterGoalReached,
              style: context.textStyles.labelLarge?.copyWith(
                color: context.nutritionColors.success,
              ),
            ),
          ],
          AppSpacing.gapLg,
          Row(
            children: [
              IconButton.outlined(
                tooltip: l10n.diaryWaterRemove(glassMl),
                onPressed: consumed > 0 ? () => onRemove(glassMl) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => onAdd(glassMl),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.waterAddAmount(glassMl)),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final ml in quickAmounts)
                ActionChip(
                  avatar: Icon(
                    Icons.add_rounded,
                    size: AppSizes.iconSm,
                    color: color,
                  ),
                  label: Text(l10n.diaryMlValue(ml)),
                  onPressed: () => onAdd(ml),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

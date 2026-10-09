import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_view.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../meals/presentation/providers/diary_providers.dart';
import '../../../meals/presentation/widgets/diary_water_card.dart';
import '../providers/water_providers.dart';

class WaterPage extends ConsumerWidget {
  const WaterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progress = ref.watch(todayWaterProgressProvider);
    final history = ref.watch(waterHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureWater)),
      body: AsyncValueView(
        value: progress,
        loading: (_) => const SkeletonView(),
        onRetry: () => ref.invalidate(todayWaterProgressProvider),
        data: (data) => ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxxl,
          ),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DiaryWaterCard(
                    onAdd: (ml) => _add(context, ref, ml, data.day),
                    onRemove: (ml) => _remove(context, ref, ml, data.logs),
                  ),
                  AppSpacing.gapLg,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final ml in DiaryWaterCard.quickAmounts)
                        ActionChip(
                          key: ValueKey('water-add-$ml'),
                          avatar: const Icon(Icons.add_rounded, size: 18),
                          label: Text(l10n.diaryMlValue(ml)),
                          onPressed: () => _add(context, ref, ml, data.day),
                        ),
                      for (final ml in DiaryWaterCard.quickAmounts)
                        ActionChip(
                          key: ValueKey('water-remove-$ml'),
                          avatar: const Icon(Icons.remove_rounded, size: 18),
                          label: Text(l10n.waterRemoveAmount(ml)),
                          onPressed: data.consumedMl <= 0
                              ? null
                              : () => _remove(context, ref, ml, data.logs),
                        ),
                    ],
                  ),
                  AppSpacing.gapLg,
                  SectionHeader(title: l10n.waterHistoryTitle),
                  AsyncValueView(
                    value: history,
                    onRetry: () => ref.invalidate(waterHistoryProvider),
                    data: (days) {
                      final others = [
                        for (final day in days)
                          if (!day.date.isAtSameMomentAs(data.day)) day,
                      ];
                      if (others.isEmpty) {
                        return AppCard(child: Text(l10n.waterEmptyHistory));
                      }
                      return AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (i, day) in others.indexed) ...[
                              if (i > 0) const Divider(height: 1),
                              ListTile(
                                title: Text(AppFormat.date(context, day.date)),
                                trailing: Text(
                                  l10n.diaryMlValue(day.ml),
                                  style: context.textStyles.titleSmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    int ml,
    DateTime day,
  ) async {
    final result = await ref.read(diaryActionsProvider).addWater(ml, day);
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    int ml,
    List<WaterLog> logs,
  ) async {
    final result = await ref.read(diaryActionsProvider).removeWater(ml, logs);
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      context.showSnack(failure.localizedMessage(context));
    }
  }
}

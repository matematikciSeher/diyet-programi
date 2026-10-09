import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/activity_card.dart';
import '../../domain/models/daily_activity.dart';
import '../activity_format.dart';
import '../widgets/health_data_section.dart';

/// Günün hareket özeti ve Apple Health / Health Connect bağlantısı.
class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activity = ref.watch(todayActivityProvider).value;
    final stepGoal =
        ref.watch(userProfileProvider).value?.nutritionTargets?.steps ??
        NutritionTargets.fallback.steps;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureActivity)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (activity == null)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  ActivityCard(
                    activity: activity,
                    stepGoal: stepGoal,
                    title: l10n.diaryActivityTitleToday,
                  ),
                  if (activity.source == ActivitySource.health) ...[
                    AppSpacing.gapSm,
                    Text(
                      activity.workoutsKnown
                          ? '${l10n.activityExercise}: ${l10n.minutesValue(AppFormat.integer(context, activity.exerciseMinutes))}'
                          : '${l10n.activityExercise}: ${formatKnownMeasure(context, known: false, value: '')}',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
                AppSpacing.gapLg,
                const HealthDataSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
